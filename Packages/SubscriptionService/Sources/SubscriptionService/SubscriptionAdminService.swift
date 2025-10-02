import Foundation
import Combine
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public final class SubscriptionAdminService: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var adminSessions: [AdminSession] = []
    @Published public private(set) var lastAction: AdminAction?

    // MARK: - Private Properties

    private let entitlementRepository: SubscriptionEntitlementRepository
    private let fraudRepository: FraudDetectionRepository
    private let auditRepository: ValidationAuditRepository
    private let adminAuditRepository: AdminAuditRepository

    // MARK: - Initialization

    public init(
        entitlementRepository: SubscriptionEntitlementRepository,
        fraudRepository: FraudDetectionRepository,
        auditRepository: ValidationAuditRepository,
        adminAuditRepository: AdminAuditRepository
    ) {
        self.entitlementRepository = entitlementRepository
        self.fraudRepository = fraudRepository
        self.auditRepository = auditRepository
        self.adminAuditRepository = adminAuditRepository
    }

    // MARK: - Dashboard Methods

    /// Gets comprehensive subscription status dashboard data
    public func getSubscriptionDashboard() async throws -> SubscriptionDashboard {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // This would typically fetch data for all families, but for now we'll create a sample dashboard
        let dashboard = SubscriptionDashboard(
            totalActiveSubscriptions: 0,
            totalExpiredSubscriptions: 0,
            totalInGracePeriod: 0,
            totalFraudEvents: 0,
            recentActivations: [],
            recentExpirations: [],
            fraudAlerts: [],
            systemHealth: .healthy
        )

        return dashboard
    }

    /// Gets detailed subscription information for a specific family
    public func getFamilySubscriptionDetails(familyID: String) async throws -> FamilySubscriptionDetails {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Fetch entitlements
        let entitlements = try await entitlementRepository.fetchEntitlements(for: familyID)

        // Fetch fraud events
        let since = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let fraudEvents = try await fraudRepository.fetchFraudEvents(for: familyID, since: since)

        // Fetch audit logs
        let auditLogs = try await auditRepository.fetchAuditLogs(for: familyID, eventType: nil)

        return FamilySubscriptionDetails(
            familyID: familyID,
            currentEntitlement: entitlements.first { $0.isActive },
            allEntitlements: entitlements,
            fraudEvents: fraudEvents,
            auditLogs: Array(auditLogs.prefix(50)), // Limit to recent 50 events
            riskScore: calculateRiskScore(fraudEvents: fraudEvents),
            recommendations: generateRecommendations(entitlements: entitlements, fraudEvents: fraudEvents)
        )
    }

    // MARK: - Manual Entitlement Management

    /// Manually grants entitlement for support cases
    public func grantManualEntitlement(
        request: ManualEntitlementRequest,
        adminUserID: String
    ) async throws -> SubscriptionEntitlement {

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Create manual entitlement
        let entitlement = SubscriptionEntitlement(
            id: UUID().uuidString,
            familyID: request.familyID,
            subscriptionTier: request.subscriptionTier,
            receiptData: "MANUAL_GRANT_\(UUID().uuidString)",
            originalTransactionID: "MANUAL_\(UUID().uuidString)",
            transactionID: "MANUAL_\(UUID().uuidString)",
            purchaseDate: Date(),
            expirationDate: request.expirationDate,
            isActive: true,
            isInTrial: false,
            autoRenewStatus: false,
            metadata: [
                "grant_type": "manual",
                "admin_user_id": adminUserID,
                "reason": request.reason,
                "support_ticket": request.supportTicketID ?? ""
            ]
        )

        let savedEntitlement = try await entitlementRepository.createEntitlement(entitlement)

        // Log admin action
        let adminAction = AdminAction(
            adminUserID: adminUserID,
            action: .manualEntitlementGrant,
            targetFamilyID: request.familyID,
            details: [
                "subscription_tier": request.subscriptionTier.rawValue,
                "expiration_date": ISO8601DateFormatter().string(from: request.expirationDate),
                "reason": request.reason
            ]
        )

        try await logAdminAction(adminAction)

        await MainActor.run {
            self.lastAction = adminAction
        }

        return savedEntitlement
    }

    /// Revokes existing entitlement (fraud, policy violation, etc.)
    public func revokeEntitlement(
        familyID: String,
        reason: String,
        adminUserID: String
    ) async throws {

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        guard let entitlement = try await entitlementRepository.fetchEntitlement(for: familyID) else {
            throw AdminError.entitlementNotFound
        }

        // Create new entitlement with revoked status
        var updatedMetadata = entitlement.metadata
        updatedMetadata["revoked_by"] = adminUserID
        updatedMetadata["revocation_reason"] = reason
        updatedMetadata["revoked_at"] = ISO8601DateFormatter().string(from: Date())

        let revokedEntitlement = SubscriptionEntitlement(
            id: entitlement.id,
            familyID: entitlement.familyID,
            subscriptionTier: entitlement.subscriptionTier,
            receiptData: entitlement.receiptData,
            originalTransactionID: entitlement.originalTransactionID,
            transactionID: entitlement.transactionID,
            purchaseDate: entitlement.purchaseDate,
            expirationDate: entitlement.expirationDate,
            isActive: false,
            isInTrial: entitlement.isInTrial,
            autoRenewStatus: entitlement.autoRenewStatus,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: entitlement.gracePeriodExpiresAt,
            metadata: updatedMetadata
        )

        _ = try await entitlementRepository.updateEntitlement(revokedEntitlement)

        // Log admin action
        let adminAction = AdminAction(
            adminUserID: adminUserID,
            action: .entitlementRevocation,
            targetFamilyID: familyID,
            details: [
                "entitlement_id": entitlement.id,
                "reason": reason,
                "original_expiration": ISO8601DateFormatter().string(from: entitlement.expirationDate)
            ]
        )

        try await logAdminAction(adminAction)

        await MainActor.run {
            self.lastAction = adminAction
        }
    }

    /// Extends existing entitlement
    public func extendEntitlement(
        familyID: String,
        additionalDays: Int,
        reason: String,
        adminUserID: String
    ) async throws -> SubscriptionEntitlement {

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        guard let entitlement = try await entitlementRepository.fetchEntitlement(for: familyID) else {
            throw AdminError.entitlementNotFound
        }

        // Extend expiration date
        guard let newExpirationDate = Calendar.current.date(
            byAdding: .day,
            value: additionalDays,
            to: entitlement.expirationDate
        ) else {
            throw AdminError.invalidDate
        }

        // Create new entitlement with extended expiration
        var updatedMetadata = entitlement.metadata
        updatedMetadata["extended_by"] = adminUserID
        updatedMetadata["extension_reason"] = reason
        updatedMetadata["extension_days"] = String(additionalDays)
        updatedMetadata["extended_at"] = ISO8601DateFormatter().string(from: Date())

        let extendedEntitlement = SubscriptionEntitlement(
            id: entitlement.id,
            familyID: entitlement.familyID,
            subscriptionTier: entitlement.subscriptionTier,
            receiptData: entitlement.receiptData,
            originalTransactionID: entitlement.originalTransactionID,
            transactionID: entitlement.transactionID,
            purchaseDate: entitlement.purchaseDate,
            expirationDate: newExpirationDate,
            isActive: entitlement.isActive,
            isInTrial: entitlement.isInTrial,
            autoRenewStatus: entitlement.autoRenewStatus,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: entitlement.gracePeriodExpiresAt,
            metadata: updatedMetadata
        )

        let savedEntitlement = try await entitlementRepository.updateEntitlement(extendedEntitlement)

        // Log admin action
        let adminAction = AdminAction(
            adminUserID: adminUserID,
            action: .entitlementExtension,
            targetFamilyID: familyID,
            details: [
                "entitlement_id": entitlement.id,
                "additional_days": String(additionalDays),
                "new_expiration": ISO8601DateFormatter().string(from: newExpirationDate),
                "reason": reason
            ]
        )

        try await logAdminAction(adminAction)

        await MainActor.run {
            self.lastAction = adminAction
        }

        return savedEntitlement
    }

    // MARK: - Fraud Management

    /// Clears fraud flags for a family
    public func clearFraudFlags(
        familyID: String,
        reason: String,
        adminUserID: String
    ) async throws {

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Log admin action
        let adminAction = AdminAction(
            adminUserID: adminUserID,
            action: .fraudFlagClear,
            targetFamilyID: familyID,
            details: [
                "reason": reason,
                "cleared_at": ISO8601DateFormatter().string(from: Date())
            ]
        )

        try await logAdminAction(adminAction)

        await MainActor.run {
            self.lastAction = adminAction
        }
    }

    /// Manually flags family for fraud investigation
    public func flagForFraudInvestigation(
        familyID: String,
        reason: String,
        severity: FraudSeverity,
        adminUserID: String
    ) async throws {

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Create fraud event
        let fraudEvent = FraudDetectionEvent(
            familyID: familyID,
            detectionType: .anomalousUsage,
            severity: severity,
            deviceInfo: ["admin_flagged": "true"],
            metadata: [
                "flagged_by": adminUserID,
                "reason": reason,
                "investigation_needed": "true"
            ]
        )

        _ = try await fraudRepository.createFraudEvent(fraudEvent)

        // Log admin action
        let adminAction = AdminAction(
            adminUserID: adminUserID,
            action: .fraudInvestigation,
            targetFamilyID: familyID,
            details: [
                "severity": severity.rawValue,
                "reason": reason,
                "fraud_event_id": fraudEvent.id
            ]
        )

        try await logAdminAction(adminAction)

        await MainActor.run {
            self.lastAction = adminAction
        }
    }

    // MARK: - Audit and Reporting

    /// Gets recent admin actions
    public func getRecentAdminActions(limit: Int = 50) async throws -> [AdminAction] {
        return try await adminAuditRepository.fetchRecentActions(limit: limit)
    }

    /// Gets admin actions for a specific family
    public func getAdminActionsForFamily(familyID: String) async throws -> [AdminAction] {
        return try await adminAuditRepository.fetchActionsForFamily(familyID)
    }

    /// Generates subscription analytics report
    public func generateAnalyticsReport(dateRange: DateRange) async throws -> SubscriptionAnalyticsReport {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // This would aggregate data across all families for the date range
        // For now, return a basic report structure
        return SubscriptionAnalyticsReport(
            dateRange: dateRange,
            totalRevenue: 0,
            newSubscriptions: 0,
            renewals: 0,
            cancellations: 0,
            fraudEvents: 0,
            averageLifetimeValue: 0,
            churnRate: 0,
            conversionRate: 0
        )
    }

    // MARK: - Private Methods

    private func calculateRiskScore(fraudEvents: [FraudDetectionEvent]) -> Double {
        guard !fraudEvents.isEmpty else { return 0.0 }

        var score: Double = 0.0
        let recentEvents = fraudEvents.filter { $0.timestamp >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date() }

        for event in recentEvents {
            switch event.severity {
            case .low: score += 0.1
            case .medium: score += 0.3
            case .high: score += 0.6
            case .critical: score += 1.0
            }
        }

        return min(score, 1.0)
    }

    private func generateRecommendations(
        entitlements: [SubscriptionEntitlement],
        fraudEvents: [FraudDetectionEvent]
    ) -> [AdminRecommendation] {

        var recommendations: [AdminRecommendation] = []

        // Check for expired entitlements
        let expiredEntitlements = entitlements.filter { $0.expirationDate <= Date() && $0.isActive }
        if !expiredEntitlements.isEmpty {
            recommendations.append(.deactivateExpiredEntitlements)
        }

        // Check for high fraud risk
        let riskScore = calculateRiskScore(fraudEvents: fraudEvents)
        if riskScore > 0.7 {
            recommendations.append(.investigateFraudRisk)
        }

        // Check for unusual patterns
        let recentEntitlements = entitlements.filter { $0.purchaseDate >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }
        if recentEntitlements.count > 3 {
            recommendations.append(.reviewRecentActivity)
        }

        return recommendations
    }

    private func logAdminAction(_ action: AdminAction) async throws {
        try await adminAuditRepository.logAction(action)
    }
}

// MARK: - Supporting Types

public struct SubscriptionDashboard {
    public let totalActiveSubscriptions: Int
    public let totalExpiredSubscriptions: Int
    public let totalInGracePeriod: Int
    public let totalFraudEvents: Int
    public let recentActivations: [SubscriptionEntitlement]
    public let recentExpirations: [SubscriptionEntitlement]
    public let fraudAlerts: [FraudDetectionEvent]
    public let systemHealth: SystemHealth

    public init(
        totalActiveSubscriptions: Int,
        totalExpiredSubscriptions: Int,
        totalInGracePeriod: Int,
        totalFraudEvents: Int,
        recentActivations: [SubscriptionEntitlement],
        recentExpirations: [SubscriptionEntitlement],
        fraudAlerts: [FraudDetectionEvent],
        systemHealth: SystemHealth
    ) {
        self.totalActiveSubscriptions = totalActiveSubscriptions
        self.totalExpiredSubscriptions = totalExpiredSubscriptions
        self.totalInGracePeriod = totalInGracePeriod
        self.totalFraudEvents = totalFraudEvents
        self.recentActivations = recentActivations
        self.recentExpirations = recentExpirations
        self.fraudAlerts = fraudAlerts
        self.systemHealth = systemHealth
    }
}

public struct FamilySubscriptionDetails {
    public let familyID: String
    public let currentEntitlement: SubscriptionEntitlement?
    public let allEntitlements: [SubscriptionEntitlement]
    public let fraudEvents: [FraudDetectionEvent]
    public let auditLogs: [ValidationAuditLog]
    public let riskScore: Double
    public let recommendations: [AdminRecommendation]

    public init(
        familyID: String,
        currentEntitlement: SubscriptionEntitlement?,
        allEntitlements: [SubscriptionEntitlement],
        fraudEvents: [FraudDetectionEvent],
        auditLogs: [ValidationAuditLog],
        riskScore: Double,
        recommendations: [AdminRecommendation]
    ) {
        self.familyID = familyID
        self.currentEntitlement = currentEntitlement
        self.allEntitlements = allEntitlements
        self.fraudEvents = fraudEvents
        self.auditLogs = auditLogs
        self.riskScore = riskScore
        self.recommendations = recommendations
    }
}

public struct ManualEntitlementRequest {
    public let familyID: String
    public let subscriptionTier: SubscriptionTier
    public let expirationDate: Date
    public let reason: String
    public let supportTicketID: String?

    public init(
        familyID: String,
        subscriptionTier: SubscriptionTier,
        expirationDate: Date,
        reason: String,
        supportTicketID: String? = nil
    ) {
        self.familyID = familyID
        self.subscriptionTier = subscriptionTier
        self.expirationDate = expirationDate
        self.reason = reason
        self.supportTicketID = supportTicketID
    }
}

public struct AdminAction {
    public let id: String
    public let adminUserID: String
    public let action: AdminActionType
    public let targetFamilyID: String
    public let timestamp: Date
    public let details: [String: String]

    public init(
        id: String = UUID().uuidString,
        adminUserID: String,
        action: AdminActionType,
        targetFamilyID: String,
        timestamp: Date = Date(),
        details: [String: String] = [:]
    ) {
        self.id = id
        self.adminUserID = adminUserID
        self.action = action
        self.targetFamilyID = targetFamilyID
        self.timestamp = timestamp
        self.details = details
    }
}

public enum AdminActionType: String, CaseIterable {
    case manualEntitlementGrant = "manual_entitlement_grant"
    case entitlementRevocation = "entitlement_revocation"
    case entitlementExtension = "entitlement_extension"
    case fraudFlagClear = "fraud_flag_clear"
    case fraudInvestigation = "fraud_investigation"
    case gracePeriodOverride = "grace_period_override"
    case refundProcessed = "refund_processed"
}

public enum AdminRecommendation: String, CaseIterable {
    case deactivateExpiredEntitlements = "deactivate_expired_entitlements"
    case investigateFraudRisk = "investigate_fraud_risk"
    case reviewRecentActivity = "review_recent_activity"
    case contactCustomerSupport = "contact_customer_support"
    case extendGracePeriod = "extend_grace_period"
}

public enum SystemHealth: String, CaseIterable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
}

public struct SubscriptionAnalyticsReport {
    public let dateRange: DateRange
    public let totalRevenue: Double
    public let newSubscriptions: Int
    public let renewals: Int
    public let cancellations: Int
    public let fraudEvents: Int
    public let averageLifetimeValue: Double
    public let churnRate: Double
    public let conversionRate: Double

    public init(
        dateRange: DateRange,
        totalRevenue: Double,
        newSubscriptions: Int,
        renewals: Int,
        cancellations: Int,
        fraudEvents: Int,
        averageLifetimeValue: Double,
        churnRate: Double,
        conversionRate: Double
    ) {
        self.dateRange = dateRange
        self.totalRevenue = totalRevenue
        self.newSubscriptions = newSubscriptions
        self.renewals = renewals
        self.cancellations = cancellations
        self.fraudEvents = fraudEvents
        self.averageLifetimeValue = averageLifetimeValue
        self.churnRate = churnRate
        self.conversionRate = conversionRate
    }
}

public enum AdminError: LocalizedError {
    case entitlementNotFound
    case invalidDate
    case unauthorizedAccess
    case invalidParameters

    public var errorDescription: String? {
        switch self {
        case .entitlementNotFound:
            return "Subscription entitlement not found"
        case .invalidDate:
            return "Invalid date provided"
        case .unauthorizedAccess:
            return "Unauthorized access to admin functions"
        case .invalidParameters:
            return "Invalid parameters provided"
        }
    }
}

// MARK: - Admin Audit Repository Protocol

public protocol AdminAuditRepository {
    func logAction(_ action: AdminAction) async throws
    func fetchRecentActions(limit: Int) async throws -> [AdminAction]
    func fetchActionsForFamily(_ familyID: String) async throws -> [AdminAction]
    func fetchActionsByAdmin(_ adminUserID: String) async throws -> [AdminAction]
}