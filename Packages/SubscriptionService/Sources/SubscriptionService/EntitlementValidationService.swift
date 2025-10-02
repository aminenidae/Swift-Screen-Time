import Foundation
import Combine
import SharedModels
import CloudKitService

@available(iOS 15.0, macOS 12.0, *)
public final class EntitlementValidationService: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var currentEntitlement: SubscriptionEntitlement?
    @Published public private(set) var isValidating: Bool = false
    @Published public private(set) var lastValidationError: Error?
    @Published public private(set) var cacheExpiry: Date?

    // MARK: - Private Properties

    private let entitlementRepository: SubscriptionEntitlementRepository
    private let fraudDetectionService: FraudDetectionService
    private let userDefaults: UserDefaults
    private let offlineGracePeriodDays: Int = 7
    private let validationCacheDuration: TimeInterval = 3600 // 1 hour

    private var validationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Cache Keys

    private enum CacheKeys {
        static let lastKnownEntitlement = "lastKnownEntitlement"
        static let lastValidationDate = "lastValidationDate"
        static let offlineGracePeriodStart = "offlineGracePeriodStart"
    }

    // MARK: - Initialization

    public init(
        entitlementRepository: SubscriptionEntitlementRepository,
        fraudDetectionService: FraudDetectionService,
        userDefaults: UserDefaults = .standard
    ) {
        self.entitlementRepository = entitlementRepository
        self.fraudDetectionService = fraudDetectionService
        self.userDefaults = userDefaults

        loadCachedEntitlement()
        setupPeriodicValidation()
    }

    deinit {
        validationTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Validates entitlement for a family on app launch
    public func validateEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        await MainActor.run { isValidating = true }
        defer { Task { @MainActor in isValidating = false } }

        do {
            // Step 1: Check for cached valid entitlement
            if let cachedEntitlement = getCachedEntitlement(for: familyID),
               isCacheValid() {
                await MainActor.run { currentEntitlement = cachedEntitlement }
                return cachedEntitlement
            }

            // Step 2: Fetch from server
            let entitlement = try await entitlementRepository.validateEntitlement(for: familyID)

            // Step 3: Validate against server if needed
            if let entitlement = entitlement {
                let validatedEntitlement = try await validateWithServer(entitlement)
                await MainActor.run {
                    currentEntitlement = validatedEntitlement
                    lastValidationError = nil
                }
                cacheEntitlement(validatedEntitlement)
                return validatedEntitlement
            }

            // Step 4: Handle offline scenario
            return try handleOfflineValidation(for: familyID)

        } catch {
            await MainActor.run { lastValidationError = error }

            // Fallback to cached entitlement if available and within grace period
            if let cachedEntitlement = getCachedEntitlement(for: familyID),
               isWithinOfflineGracePeriod() {
                await MainActor.run { currentEntitlement = cachedEntitlement }
                return cachedEntitlement
            }

            throw error
        }
    }

    /// Checks if current entitlement allows access to premium features
    public func hasActiveEntitlement(for familyID: String) -> Bool {
        guard let entitlement = currentEntitlement,
              entitlement.familyID == familyID else { return false }

        // Check if entitlement is active
        guard entitlement.isActive else { return false }

        // Check expiration date
        guard entitlement.expirationDate > Date() else { return false }

        // Check grace period if applicable
        if let gracePeriodExpiry = entitlement.gracePeriodExpiresAt {
            return gracePeriodExpiry > Date()
        }

        return true
    }

    /// Forces a refresh of entitlement from server
    public func refreshEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        clearCache()
        return try await validateEntitlement(for: familyID)
    }

    /// Handles background sync when connectivity returns
    public func handleConnectivityRestored(for familyID: String) async {
        do {
            _ = try await refreshEntitlement(for: familyID)
            clearOfflineGracePeriod()
        } catch {
            print("Failed to sync entitlement after connectivity restored: \(error)")
        }
    }

    // MARK: - Private Methods

    private func loadCachedEntitlement() {
        if let data = userDefaults.data(forKey: CacheKeys.lastKnownEntitlement),
           let entitlement = try? JSONDecoder().decode(SubscriptionEntitlement.self, from: data) {
            currentEntitlement = entitlement
        }

        if let lastValidation = userDefaults.object(forKey: CacheKeys.lastValidationDate) as? Date {
            cacheExpiry = lastValidation.addingTimeInterval(validationCacheDuration)
        }
    }

    private func cacheEntitlement(_ entitlement: SubscriptionEntitlement) {
        if let data = try? JSONEncoder().encode(entitlement) {
            userDefaults.set(data, forKey: CacheKeys.lastKnownEntitlement)
        }
        userDefaults.set(Date(), forKey: CacheKeys.lastValidationDate)
        cacheExpiry = Date().addingTimeInterval(validationCacheDuration)
    }

    private func getCachedEntitlement(for familyID: String) -> SubscriptionEntitlement? {
        guard let entitlement = currentEntitlement,
              entitlement.familyID == familyID else { return nil }
        return entitlement
    }

    private func isCacheValid() -> Bool {
        guard let expiry = cacheExpiry else { return false }
        return expiry > Date()
    }

    private func clearCache() {
        userDefaults.removeObject(forKey: CacheKeys.lastKnownEntitlement)
        userDefaults.removeObject(forKey: CacheKeys.lastValidationDate)
        cacheExpiry = nil
    }

    private func validateWithServer(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        // Check if validation is needed (every 24 hours for active subscriptions)
        let lastValidated = entitlement.lastValidatedAt
        let needsValidation = Date().timeIntervalSince(lastValidated) > 86400 // 24 hours

        if needsValidation {
            // This would call the CloudKit Function to re-validate the receipt
            // For now, we'll update the lastValidatedAt timestamp
            var updatedEntitlement = entitlement
            updatedEntitlement.lastValidatedAt = Date()

            return try await entitlementRepository.updateEntitlement(updatedEntitlement)
        }

        return entitlement
    }

    private func handleOfflineValidation(for familyID: String) throws -> SubscriptionEntitlement? {
        guard let cachedEntitlement = getCachedEntitlement(for: familyID) else {
            throw EntitlementValidationError.noValidEntitlement
        }

        // Start offline grace period if not already started
        if userDefaults.object(forKey: CacheKeys.offlineGracePeriodStart) == nil {
            userDefaults.set(Date(), forKey: CacheKeys.offlineGracePeriodStart)
        }

        guard isWithinOfflineGracePeriod() else {
            throw EntitlementValidationError.offlineGracePeriodExpired
        }

        return cachedEntitlement
    }

    private func isWithinOfflineGracePeriod() -> Bool {
        guard let startDate = userDefaults.object(forKey: CacheKeys.offlineGracePeriodStart) as? Date else {
            return true // If grace period hasn't started, we're still within it
        }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysSinceStart < offlineGracePeriodDays
    }

    private func clearOfflineGracePeriod() {
        userDefaults.removeObject(forKey: CacheKeys.offlineGracePeriodStart)
    }

    private func setupPeriodicValidation() {
        // Validate every hour when app is active
        validationTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            guard let self = self,
                  let entitlement = self.currentEntitlement else { return }

            Task {
                do {
                    _ = try await self.validateEntitlement(for: entitlement.familyID)
                } catch {
                    print("Periodic validation failed: \(error)")
                }
            }
        }
    }

    // MARK: - Grace Period Management

    public func checkGracePeriodStatus(for entitlement: SubscriptionEntitlement) -> GracePeriodStatus {
        // Check if subscription has expired
        guard entitlement.expirationDate <= Date() else {
            return .notInGracePeriod
        }

        // Check if grace period exists
        guard let gracePeriodExpiry = entitlement.gracePeriodExpiresAt else {
            return .expired
        }

        // Check if still within grace period
        if gracePeriodExpiry > Date() {
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: gracePeriodExpiry).day ?? 0
            return .active(daysRemaining: daysRemaining)
        }

        return .expired
    }

    public func startGracePeriod(for entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        var updatedEntitlement = entitlement
        updatedEntitlement.gracePeriodExpiresAt = Calendar.current.date(byAdding: .day, value: 16, to: Date())

        return try await entitlementRepository.updateEntitlement(updatedEntitlement)
    }
}

// MARK: - Supporting Types

public enum EntitlementValidationError: LocalizedError {
    case noValidEntitlement
    case offlineGracePeriodExpired
    case validationServerUnavailable
    case fraudDetected(FraudDetectionEvent)

    public var errorDescription: String? {
        switch self {
        case .noValidEntitlement:
            return "No valid subscription entitlement found"
        case .offlineGracePeriodExpired:
            return "Offline grace period has expired. Please connect to the internet to validate your subscription."
        case .validationServerUnavailable:
            return "Unable to validate subscription. Please try again later."
        case .fraudDetected(let event):
            return "Subscription validation failed due to security concerns: \(event.detectionType.rawValue)"
        }
    }
}


// MARK: - Fraud Detection Service Protocol

public protocol FraudDetectionService {
    func detectFraud(for entitlement: SubscriptionEntitlement, deviceInfo: [String: String]) async throws -> [FraudDetectionEvent]
    func isJailbroken() -> Bool
    func validateReceiptIntegrity(_ receiptData: String) -> Bool
}

// MARK: - Default Fraud Detection Implementation

@available(iOS 15.0, macOS 12.0, *)
public final class DefaultFraudDetectionService: FraudDetectionService {

    public init() {}

    public func detectFraud(for entitlement: SubscriptionEntitlement, deviceInfo: [String: String]) async throws -> [FraudDetectionEvent] {
        var events: [FraudDetectionEvent] = []

        // Check for jailbreak
        if isJailbroken() {
            let event = FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .jailbrokenDevice,
                severity: .medium,
                deviceInfo: deviceInfo,
                transactionInfo: ["transactionID": entitlement.transactionID],
                metadata: ["detection": "jailbreak_detected"]
            )
            events.append(event)
        }

        // Check receipt integrity
        if !validateReceiptIntegrity(entitlement.receiptData) {
            let event = FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .tamperedReceipt,
                severity: .high,
                deviceInfo: deviceInfo,
                transactionInfo: ["transactionID": entitlement.transactionID],
                metadata: ["detection": "receipt_tampering"]
            )
            events.append(event)
        }

        // Check for anomalous usage patterns
        if await detectAnomalousUsage(entitlement: entitlement) {
            let event = FraudDetectionEvent(
                familyID: entitlement.familyID,
                detectionType: .anomalousUsage,
                severity: .medium,
                deviceInfo: deviceInfo,
                transactionInfo: ["transactionID": entitlement.transactionID],
                metadata: ["detection": "anomalous_usage_pattern"]
            )
            events.append(event)
        }

        return events
    }

    public func isJailbroken() -> Bool {
        // Basic jailbreak detection
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check if we can write to system directories
        let testPath = "/private/test_jailbreak"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // If we can write, device might be jailbroken
        } catch {
            return false
        }
    }

    public func validateReceiptIntegrity(_ receiptData: String) -> Bool {
        // Basic receipt validation - check if it's valid base64
        guard !receiptData.isEmpty else { return false }
        guard Data(base64Encoded: receiptData) != nil else { return false }

        // Additional integrity checks would go here
        return true
    }

    private func detectAnomalousUsage(entitlement: SubscriptionEntitlement) async -> Bool {
        // Check for rapid subscription changes
        let timeSincePurchase = Date().timeIntervalSince(entitlement.purchaseDate)

        // Flag if subscription was purchased very recently (less than 1 hour) but already validated multiple times
        if timeSincePurchase < 3600 && entitlement.lastValidatedAt != entitlement.purchaseDate {
            return true
        }

        return false
    }
}