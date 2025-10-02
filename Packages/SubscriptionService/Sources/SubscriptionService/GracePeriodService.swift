import Foundation
import Combine
import SharedModels
import UserNotifications

@available(iOS 15.0, macOS 12.0, *)
public final class GracePeriodService: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var isInGracePeriod: Bool = false
    @Published public private(set) var gracePeriodDaysRemaining: Int = 0
    @Published public private(set) var gracePeriodExpiry: Date?
    @Published public private(set) var billingRetryStatus: BillingRetryStatus = .none

    // MARK: - Private Properties

    private let entitlementRepository: SubscriptionEntitlementRepository
    private let auditRepository: ValidationAuditRepository
    private let notificationService: BillingNotificationService
    private let gracePeriodDays: Int = 16

    private var gracePeriodTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        entitlementRepository: SubscriptionEntitlementRepository,
        auditRepository: ValidationAuditRepository,
        notificationService: BillingNotificationService
    ) {
        self.entitlementRepository = entitlementRepository
        self.auditRepository = auditRepository
        self.notificationService = notificationService

        setupGracePeriodTimer()
    }

    deinit {
        gracePeriodTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Initiates grace period for subscription billing issues
    public func startGracePeriod(for entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        guard entitlement.gracePeriodExpiresAt == nil else {
            throw GracePeriodError.gracePeriodAlreadyActive
        }

        // Calculate grace period expiry (16 days from now)
        let gracePeriodExpiry = Calendar.current.date(byAdding: .day, value: gracePeriodDays, to: Date())
        guard let gracePeriodExpiry = gracePeriodExpiry else {
            throw GracePeriodError.invalidDate
        }

        // Update entitlement with grace period
        var updatedEntitlement = entitlement
        updatedEntitlement.gracePeriodExpiresAt = gracePeriodExpiry
        updatedEntitlement.isActive = true // Keep active during grace period

        let savedEntitlement = try await entitlementRepository.updateEntitlement(updatedEntitlement)

        // Log grace period start
        let auditLog = ValidationAuditLog(
            familyID: entitlement.familyID,
            transactionID: entitlement.transactionID,
            productID: entitlement.subscriptionTier.rawValue,
            eventType: .gracePeriodStarted,
            metadata: [
                "grace_period_days": String(gracePeriodDays),
                "expiry_date": ISO8601DateFormatter().string(from: gracePeriodExpiry),
                "reason": "billing_issue"
            ]
        )
        _ = try await auditRepository.createAuditLog(auditLog)

        // Update published properties
        await MainActor.run {
            self.isInGracePeriod = true
            self.gracePeriodExpiry = gracePeriodExpiry
            self.gracePeriodDaysRemaining = self.calculateDaysRemaining(until: gracePeriodExpiry)
            self.billingRetryStatus = .retrying
        }

        // Schedule billing retry notifications
        try await scheduleGracePeriodNotifications(
            familyID: entitlement.familyID,
            expiryDate: gracePeriodExpiry
        )

        return savedEntitlement
    }

    /// Ends grace period and revokes access if billing not resolved
    public func endGracePeriod(for entitlement: SubscriptionEntitlement, reason: GracePeriodEndReason) async throws -> SubscriptionEntitlement {
        guard entitlement.gracePeriodExpiresAt != nil else {
            throw GracePeriodError.noActiveGracePeriod
        }

        // Update entitlement - remove grace period and deactivate if billing failed
        var updatedEntitlement = entitlement
        updatedEntitlement.gracePeriodExpiresAt = nil

        switch reason {
        case .billingResolved:
            updatedEntitlement.isActive = true
        case .gracePeriodExpired, .manualRevocation:
            updatedEntitlement.isActive = false
        }

        let savedEntitlement = try await entitlementRepository.updateEntitlement(updatedEntitlement)

        // Log grace period end
        let auditLog = ValidationAuditLog(
            familyID: entitlement.familyID,
            transactionID: entitlement.transactionID,
            productID: entitlement.subscriptionTier.rawValue,
            eventType: .gracePeriodEnded,
            metadata: [
                "reason": reason.rawValue,
                "final_status": updatedEntitlement.isActive ? "active" : "revoked"
            ]
        )
        _ = try await auditRepository.createAuditLog(auditLog)

        // Update published properties
        await MainActor.run {
            self.isInGracePeriod = false
            self.gracePeriodExpiry = nil
            self.gracePeriodDaysRemaining = 0
            self.billingRetryStatus = reason == .billingResolved ? .resolved : .failed
        }

        // Cancel pending notifications if grace period resolved
        if reason == .billingResolved {
            await notificationService.cancelGracePeriodNotifications(familyID: entitlement.familyID)
        }

        return savedEntitlement
    }

    /// Checks current grace period status for an entitlement
    public func checkGracePeriodStatus(for entitlement: SubscriptionEntitlement) async -> GracePeriodStatus {
        guard let gracePeriodExpiry = entitlement.gracePeriodExpiresAt else {
            await MainActor.run {
                self.isInGracePeriod = false
                self.gracePeriodDaysRemaining = 0
                self.gracePeriodExpiry = nil
            }
            return .notInGracePeriod
        }

        let now = Date()
        if gracePeriodExpiry <= now {
            // Grace period has expired, end it
            do {
                _ = try await endGracePeriod(for: entitlement, reason: .gracePeriodExpired)
                return .expired
            } catch {
                print("Failed to end expired grace period: \(error)")
                return .expired
            }
        }

        // Still in grace period
        let daysRemaining = calculateDaysRemaining(until: gracePeriodExpiry)

        await MainActor.run {
            self.isInGracePeriod = true
            self.gracePeriodDaysRemaining = daysRemaining
            self.gracePeriodExpiry = gracePeriodExpiry
        }

        return .active(daysRemaining: daysRemaining)
    }

    /// Handles successful billing retry during grace period
    public func handleBillingResolved(for entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        return try await endGracePeriod(for: entitlement, reason: .billingResolved)
    }

    /// Manually revokes access during grace period (admin function)
    public func revokeAccess(for entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        return try await endGracePeriod(for: entitlement, reason: .manualRevocation)
    }

    /// Checks all entitlements for expired grace periods (background task)
    public func processExpiredGracePeriods() async {
        // This would typically be called by a background task
        // For now, we'll focus on the specific family's entitlement
        print("Processing expired grace periods...")
    }

    // MARK: - Private Methods

    private func setupGracePeriodTimer() {
        // Check grace period status every hour
        gracePeriodTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.processExpiredGracePeriods()
            }
        }
    }

    private func calculateDaysRemaining(until date: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: date)
        return max(0, components.day ?? 0)
    }

    private func scheduleGracePeriodNotifications(familyID: String, expiryDate: Date) async throws {
        // Schedule notifications for days 3, 7, 14, and final day
        let notificationDays = [3, 7, 14, 16]

        for day in notificationDays {
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: -day, to: expiryDate) else {
                continue
            }

            let daysRemaining = day
            let isUrgent = daysRemaining <= 3

            try await notificationService.scheduleBillingRetryNotification(
                familyID: familyID,
                daysRemaining: daysRemaining,
                scheduledDate: notificationDate,
                isUrgent: isUrgent
            )
        }
    }
}

// MARK: - Supporting Types

public enum GracePeriodStatus {
    case notInGracePeriod
    case active(daysRemaining: Int)
    case expired
}

public enum GracePeriodEndReason: String, CaseIterable {
    case billingResolved = "billing_resolved"
    case gracePeriodExpired = "grace_period_expired"
    case manualRevocation = "manual_revocation"
}

public enum BillingRetryStatus {
    case none
    case retrying
    case resolved
    case failed
}

public enum GracePeriodError: LocalizedError {
    case gracePeriodAlreadyActive
    case noActiveGracePeriod
    case invalidDate
    case billingSystemUnavailable

    public var errorDescription: String? {
        switch self {
        case .gracePeriodAlreadyActive:
            return "Grace period is already active for this subscription"
        case .noActiveGracePeriod:
            return "No active grace period found for this subscription"
        case .invalidDate:
            return "Invalid date provided for grace period calculation"
        case .billingSystemUnavailable:
            return "Billing system is currently unavailable"
        }
    }
}

// MARK: - Billing Notification Service

public protocol BillingNotificationService {
    func scheduleBillingRetryNotification(
        familyID: String,
        daysRemaining: Int,
        scheduledDate: Date,
        isUrgent: Bool
    ) async throws

    func cancelGracePeriodNotifications(familyID: String) async
    func sendImmediateBillingAlert(familyID: String, message: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public final class DefaultBillingNotificationService: BillingNotificationService {

    private let notificationCenter: UNUserNotificationCenter

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    public func scheduleBillingRetryNotification(
        familyID: String,
        daysRemaining: Int,
        scheduledDate: Date,
        isUrgent: Bool
    ) async throws {

        let content = UNMutableNotificationContent()
        content.title = "Subscription Payment Issue"

        switch daysRemaining {
        case 16:
            content.body = "We're having trouble processing your subscription payment. Your access will continue for 16 more days while we retry."
        case 14:
            content.body = "Subscription payment retry in progress. 14 days remaining."
        case 7:
            content.body = "⚠️ Subscription payment issue continues. 7 days remaining."
        case 3:
            content.body = "🚨 Urgent: Subscription payment required. Only 3 days remaining."
        case 1:
            content.body = "🚨 Final notice: Subscription expires tomorrow. Please update your payment method."
        default:
            content.body = "Subscription payment retry. \(daysRemaining) days remaining."
        }

        content.sound = isUrgent ? .defaultCritical : .default
        content.categoryIdentifier = "BILLING_RETRY"
        content.userInfo = [
            "familyID": familyID,
            "daysRemaining": daysRemaining,
            "type": "grace_period"
        ]

        // Schedule notification
        let identifier = "grace_period_\(familyID)_\(daysRemaining)"
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, scheduledDate.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    public func cancelGracePeriodNotifications(familyID: String) async {
        let identifiers = (1...16).map { "grace_period_\(familyID)_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func sendImmediateBillingAlert(familyID: String, message: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Alert"
        content.body = message
        content.sound = .defaultCritical
        content.categoryIdentifier = "BILLING_ALERT"
        content.userInfo = [
            "familyID": familyID,
            "type": "immediate_alert"
        ]

        let identifier = "billing_alert_\(familyID)_\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }
}