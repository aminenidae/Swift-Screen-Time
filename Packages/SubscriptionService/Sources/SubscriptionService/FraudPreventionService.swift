import Foundation
import Combine
import SharedModels
import CloudKit
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, macOS 12.0, *)
public final class FraudPreventionService: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var detectedEvents: [FraudDetectionEvent] = []
    @Published public private(set) var fraudScore: Double = 0.0
    @Published public private(set) var isBlocked: Bool = false

    // MARK: - Private Properties

    private let fraudRepository: FraudDetectionRepository
    private let validationRepository: ValidationAuditRepository
    private let deviceProfiler: DeviceProfiler
    private let usageAnalyzer: UsagePatternAnalyzer

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Fraud Detection Thresholds

    private struct FraudThresholds {
        static let jailbreakScore: Double = 0.4
        static let tamperedReceiptScore: Double = 0.8
        static let duplicateTransactionScore: Double = 1.0
        static let anomalousUsageScore: Double = 0.3
        static let blockingThreshold: Double = 0.7
        static let alertThreshold: Double = 0.5
    }

    // MARK: - Initialization

    public init(
        fraudRepository: FraudDetectionRepository,
        validationRepository: ValidationAuditRepository,
        deviceProfiler: DeviceProfiler = DefaultDeviceProfiler(),
        usageAnalyzer: UsagePatternAnalyzer = DefaultUsagePatternAnalyzer()
    ) {
        self.fraudRepository = fraudRepository
        self.validationRepository = validationRepository
        self.deviceProfiler = deviceProfiler
        self.usageAnalyzer = usageAnalyzer
    }

    // MARK: - Public Methods

    /// Comprehensive fraud detection for subscription validation
    public func detectFraud(
        for entitlement: SubscriptionEntitlement,
        context: FraudDetectionContext
    ) async throws -> FraudDetectionResult {

        var detectedEvents: [FraudDetectionEvent] = []
        var totalScore: Double = 0.0

        // 1. Device-based fraud detection
        let deviceEvents = await detectDeviceFraud(
            familyID: entitlement.familyID,
            context: context
        )
        detectedEvents.append(contentsOf: deviceEvents)

        // 2. Receipt tampering detection
        if let receiptEvent = await detectReceiptTampering(
            entitlement: entitlement,
            context: context
        ) {
            detectedEvents.append(receiptEvent)
        }

        // 3. Duplicate transaction detection
        if let duplicateEvent = try await detectDuplicateTransaction(
            entitlement: entitlement,
            context: context
        ) {
            detectedEvents.append(duplicateEvent)
        }

        // 4. Usage pattern analysis
        let usageEvents = try await detectAnomalousUsage(
            entitlement: entitlement,
            context: context
        )
        detectedEvents.append(contentsOf: usageEvents)

        // 5. Calculate overall fraud score
        totalScore = calculateFraudScore(events: detectedEvents)

        // 6. Store detected events
        for event in detectedEvents {
            _ = try await fraudRepository.createFraudEvent(event)
        }

        // 7. Log validation event
        try await logValidationEvent(
            entitlement: entitlement,
            events: detectedEvents,
            score: totalScore
        )

        // 8. Update published properties
        await MainActor.run {
            self.detectedEvents = detectedEvents
            self.fraudScore = totalScore
            self.isBlocked = totalScore >= FraudThresholds.blockingThreshold
        }

        return FraudDetectionResult(
            events: detectedEvents,
            fraudScore: totalScore,
            recommendation: getRecommendation(score: totalScore),
            shouldBlock: totalScore >= FraudThresholds.blockingThreshold
        )
    }

    /// Check if a family is currently blocked due to fraud
    public func isFamilyBlocked(_ familyID: String) async throws -> Bool {
        let recentEvents = try await fraudRepository.fetchFraudEvents(
            for: familyID,
            since: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        )

        let score = calculateFraudScore(events: recentEvents)
        return score >= FraudThresholds.blockingThreshold
    }

    /// Clear fraud blocks for a family (admin function)
    public func clearFraudBlock(for familyID: String) async throws {
        // This would typically require admin privileges
        await MainActor.run {
            self.isBlocked = false
            self.fraudScore = 0.0
            self.detectedEvents = []
        }

        // Log the admin action
        let auditLog = ValidationAuditLog(
            familyID: familyID,
            productID: "admin_action",
            eventType: .fraudDetected,
            metadata: ["action": "fraud_block_cleared"]
        )
        _ = try await validationRepository.createAuditLog(auditLog)
    }

    // MARK: - Private Detection Methods

    private func detectDeviceFraud(
        familyID: String,
        context: FraudDetectionContext
    ) async -> [FraudDetectionEvent] {
        var events: [FraudDetectionEvent] = []

        // Jailbreak detection
        if deviceProfiler.isJailbroken() {
            let event = FraudDetectionEvent(
                familyID: familyID,
                detectionType: .jailbrokenDevice,
                severity: .medium,
                deviceInfo: context.deviceInfo,
                metadata: [
                    "detection_method": "file_system_check",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )
            events.append(event)
        }

        return events
    }

    private func detectReceiptTampering(
        entitlement: SubscriptionEntitlement,
        context: FraudDetectionContext
    ) async -> FraudDetectionEvent? {

        // Basic receipt validation
        guard validateReceiptFormat(entitlement.receiptData) else {
            return FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .tamperedReceipt,
                severity: .high,
                deviceInfo: context.deviceInfo,
                transactionInfo: [
                    "transactionID": entitlement.transactionID,
                    "originalTransactionID": entitlement.originalTransactionID
                ],
                metadata: [
                    "issue": "invalid_receipt_format",
                    "receipt_length": String(entitlement.receiptData.count)
                ]
            )
        }

        // Check for suspicious timing patterns
        let timeSincePurchase = Date().timeIntervalSince(entitlement.purchaseDate)
        if timeSincePurchase < 60 && entitlement.lastValidatedAt != entitlement.purchaseDate {
            return FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .tamperedReceipt,
                severity: .medium,
                deviceInfo: context.deviceInfo,
                transactionInfo: [
                    "transactionID": entitlement.transactionID,
                    "time_since_purchase": String(timeSincePurchase)
                ],
                metadata: [
                    "issue": "suspicious_validation_timing",
                    "validation_count": "multiple"
                ]
            )
        }

        return nil
    }

    private func detectDuplicateTransaction(
        entitlement: SubscriptionEntitlement,
        context: FraudDetectionContext
    ) async throws -> FraudDetectionEvent? {

        // Check for exact transaction ID duplicates across different families
        let existingEntitlements = try await fraudRepository.findEntitlementsByTransactionID(
            entitlement.transactionID
        )

        let duplicatesInOtherFamilies = existingEntitlements.filter {
            $0.familyID != entitlement.familyID
        }

        if !duplicatesInOtherFamilies.isEmpty {
            return FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .duplicateTransaction,
                severity: .critical,
                deviceInfo: context.deviceInfo,
                transactionInfo: [
                    "transactionID": entitlement.transactionID,
                    "duplicate_count": String(duplicatesInOtherFamilies.count),
                    "other_families": duplicatesInOtherFamilies.map(\.familyID).joined(separator: ",")
                ],
                metadata: [
                    "detection": "cross_family_duplicate",
                    "severity_reason": "same_transaction_multiple_families"
                ]
            )
        }

        return nil
    }

    private func detectAnomalousUsage(
        entitlement: SubscriptionEntitlement,
        context: FraudDetectionContext
    ) async throws -> [FraudDetectionEvent] {

        let patterns = try await usageAnalyzer.analyzeUsagePatterns(
            familyID: entitlement.familyID,
            timeRange: DateRange(
                start: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                end: Date()
            )
        )

        var events: [FraudDetectionEvent] = []

        // Check for rapid subscription changes
        if patterns.rapidSubscriptionChanges > 3 {
            let event = FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .anomalousUsage,
                severity: .medium,
                deviceInfo: context.deviceInfo,
                transactionInfo: ["transactionID": entitlement.transactionID],
                metadata: [
                    "pattern": "rapid_subscription_changes",
                    "change_count": String(patterns.rapidSubscriptionChanges),
                    "time_period": "30_days"
                ]
            )
            events.append(event)
        }

        // Check for unusual validation frequency
        if patterns.validationFrequency > 50 {
            let event = FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .anomalousUsage,
                severity: .low,
                deviceInfo: context.deviceInfo,
                transactionInfo: ["transactionID": entitlement.transactionID],
                metadata: [
                    "pattern": "excessive_validation_requests",
                    "validation_count": String(patterns.validationFrequency),
                    "time_period": "30_days"
                ]
            )
            events.append(event)
        }

        return events
    }

    // MARK: - Helper Methods

    private func validateReceiptFormat(_ receiptData: String) -> Bool {
        // Basic validation
        guard !receiptData.isEmpty else { return false }
        guard receiptData.count > 100 else { return false } // Receipts should be substantial
        guard Data(base64Encoded: receiptData) != nil else { return false }

        // Check for obvious tampering indicators
        let suspiciousPatterns = ["test", "fake", "invalid", "tampered"]
        let lowercaseReceipt = receiptData.lowercased()

        for pattern in suspiciousPatterns {
            if lowercaseReceipt.contains(pattern) {
                return false
            }
        }

        return true
    }

    private func calculateFraudScore(events: [FraudDetectionEvent]) -> Double {
        var score: Double = 0.0

        for event in events {
            switch event.detectionType {
            case .jailbrokenDevice:
                score += FraudThresholds.jailbreakScore
            case .tamperedReceipt:
                score += FraudThresholds.tamperedReceiptScore
            case .duplicateTransaction:
                score += FraudThresholds.duplicateTransactionScore
            case .anomalousUsage:
                score += FraudThresholds.anomalousUsageScore
            }

            // Severity multiplier
            switch event.severity {
            case .low:
                score *= 0.5
            case .medium:
                score *= 1.0
            case .high:
                score *= 1.5
            case .critical:
                score *= 2.0
            }
        }

        return min(score, 1.0) // Cap at 1.0
    }

    private func getRecommendation(score: Double) -> FraudRecommendation {
        if score >= FraudThresholds.blockingThreshold {
            return .block
        } else if score >= FraudThresholds.alertThreshold {
            return .alert
        } else {
            return .allow
        }
    }

    private func logValidationEvent(
        entitlement: SubscriptionEntitlement,
        events: [FraudDetectionEvent],
        score: Double
    ) async throws {

        let eventType: ValidationEventType = events.isEmpty ? .receiptValidated : .fraudDetected

        let auditLog = ValidationAuditLog(
            familyID: entitlement.familyID,
            transactionID: entitlement.transactionID,
            productID: entitlement.subscriptionTier.rawValue,
            eventType: eventType,
            metadata: [
                "fraud_score": String(score),
                "event_count": String(events.count),
                "events": events.map(\.detectionType.rawValue).joined(separator: ",")
            ]
        )

        _ = try await validationRepository.createAuditLog(auditLog)
    }
}

// MARK: - Supporting Types

public struct FraudDetectionContext {
    public let deviceInfo: [String: String]
    public let userAgent: String?
    public let ipAddress: String?
    public let timestamp: Date

    public init(
        deviceInfo: [String: String],
        userAgent: String? = nil,
        ipAddress: String? = nil,
        timestamp: Date = Date()
    ) {
        self.deviceInfo = deviceInfo
        self.userAgent = userAgent
        self.ipAddress = ipAddress
        self.timestamp = timestamp
    }
}

public struct FraudDetectionResult {
    public let events: [FraudDetectionEvent]
    public let fraudScore: Double
    public let recommendation: FraudRecommendation
    public let shouldBlock: Bool
}

public enum FraudRecommendation {
    case allow
    case alert
    case block
}

public struct UsagePatterns {
    public let rapidSubscriptionChanges: Int
    public let validationFrequency: Int
    public let deviceChanges: Int
    public let geographicAnomalies: Int

    public init(
        rapidSubscriptionChanges: Int,
        validationFrequency: Int,
        deviceChanges: Int,
        geographicAnomalies: Int
    ) {
        self.rapidSubscriptionChanges = rapidSubscriptionChanges
        self.validationFrequency = validationFrequency
        self.deviceChanges = deviceChanges
        self.geographicAnomalies = geographicAnomalies
    }
}

// MARK: - Protocol Definitions

public protocol FraudDetectionRepository {
    func createFraudEvent(_ event: FraudDetectionEvent) async throws -> FraudDetectionEvent
    func fetchFraudEvents(for familyID: String, since date: Date) async throws -> [FraudDetectionEvent]
    func findEntitlementsByTransactionID(_ transactionID: String) async throws -> [SubscriptionEntitlement]
}

public protocol ValidationAuditRepository {
    func createAuditLog(_ log: ValidationAuditLog) async throws -> ValidationAuditLog
    func fetchAuditLogs(for familyID: String, eventType: ValidationEventType?) async throws -> [ValidationAuditLog]
}

public protocol DeviceProfiler {
    func isJailbroken() -> Bool
    func getDeviceInfo() -> [String: String]
    func detectTampering() -> Bool
}

public protocol UsagePatternAnalyzer {
    func analyzeUsagePatterns(familyID: String, timeRange: DateRange) async throws -> UsagePatterns
}

// MARK: - Default Implementations

public struct DefaultDeviceProfiler: DeviceProfiler {

    public init() {}

    public func isJailbroken() -> Bool {
        // Enhanced jailbreak detection
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check for suspicious libraries
        if let _ = dlopen("/usr/lib/libmis.dylib", RTLD_NOW) {
            return true
        }

        // Check if we can write to system directories
        let testPath = "/private/test_jailbreak_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    public func getDeviceInfo() -> [String: String] {
        var info: [String: String] = [:]

        #if canImport(UIKit)
        info["device_model"] = UIDevice.current.model
        info["system_name"] = UIDevice.current.systemName
        info["system_version"] = UIDevice.current.systemVersion
        info["device_name"] = UIDevice.current.name
        info["identifier_for_vendor"] = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

        // Screen information
        let screen = UIScreen.main
        info["screen_scale"] = String(describing: screen.scale)
        info["screen_bounds"] = NSCoder.string(for: screen.bounds)
        #else
        info["device_model"] = "Unknown"
        info["system_name"] = "macOS"
        info["system_version"] = "Unknown"
        info["device_name"] = "Mac"
        info["identifier_for_vendor"] = "unknown"
        #endif

        return info
    }

    public func detectTampering() -> Bool {
        // Basic tampering detection
        return isJailbroken()
    }
}

public struct DefaultUsagePatternAnalyzer: UsagePatternAnalyzer {

    public init() {}

    public func analyzeUsagePatterns(familyID: String, timeRange: DateRange) async throws -> UsagePatterns {
        // This would typically analyze actual usage data
        // For now, return default values
        return UsagePatterns(
            rapidSubscriptionChanges: 0,
            validationFrequency: 1,
            deviceChanges: 0,
            geographicAnomalies: 0
        )
    }
}