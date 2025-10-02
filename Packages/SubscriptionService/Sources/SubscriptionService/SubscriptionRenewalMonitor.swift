import Foundation
import StoreKit
import UserNotifications
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class SubscriptionRenewalMonitor: ObservableObject {
    @Published public private(set) var renewalStatus: RenewalStatus = .unknown
    @Published public private(set) var nextRenewalDate: Date?
    @Published public private(set) var billingIssueCount: Int = 0
    @Published public private(set) var gracePeriodEndDate: Date?

    private let notificationCenter: UNUserNotificationCenter
    private let gracePeriodDays: Int = 16

    // Callbacks for different renewal events
    public var onRenewalSuccess: ((String) -> Void)?
    public var onRenewalFailure: ((String, BillingIssueReason) -> Void)?
    public var onGracePeriodStarted: ((Date) -> Void)?
    public var onAutoRenewStatusChanged: ((Bool) -> Void)?

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    /// Start monitoring subscription renewal events
    public func startMonitoring() async {
        await requestNotificationPermissions()
        await scheduleRenewalReminders()
    }

    /// Process subscription status changes for renewal monitoring
    public func processStatusChange(
        from oldStatus: SharedModels.SubscriptionStatus?,
        to newStatus: SharedModels.SubscriptionStatus,
        entitlement: SubscriptionEntitlementInfo?
    ) async {
        guard let entitlement = entitlement else { return }

        // Update renewal status
        await updateRenewalStatus(newStatus: newStatus, entitlement: entitlement)

        // Handle specific status transitions
        switch (oldStatus, newStatus) {
        case (_, .active):
            await handleSuccessfulRenewal(entitlement: entitlement)
        case (.active, .gracePeriod), (.trial, .gracePeriod):
            await handleBillingIssue(entitlement: entitlement)
        case (.gracePeriod, .expired):
            await handleRenewalFailure(entitlement: entitlement)
        case (_, .revoked):
            await handleSubscriptionRevoked(entitlement: entitlement)
        default:
            break
        }
    }

    /// Check for billing issues and grace period status
    public func checkBillingStatus(for entitlement: SubscriptionEntitlementInfo) async {
        let now = Date()

        if let expirationDate = entitlement.nextBillingDate {
            if now > expirationDate {
                let gracePeriodEnd = Calendar.current.date(byAdding: .day, value: gracePeriodDays, to: expirationDate) ?? expirationDate

                if now <= gracePeriodEnd {
                    // In grace period
                    gracePeriodEndDate = gracePeriodEnd
                    billingIssueCount += 1
                    await scheduleGracePeriodNotification(endDate: gracePeriodEnd)

                    onGracePeriodStarted?(gracePeriodEnd)
                } else {
                    // Past grace period - subscription failed
                    await handleRenewalFailure(entitlement: entitlement)
                }
            }
        }
    }

    /// Schedule reminder notifications for upcoming renewals
    public func scheduleRenewalReminders() async {
        // Remove existing renewal reminder notifications
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["renewal_reminder"])

        guard let renewalDate = nextRenewalDate else { return }

        // Schedule notification 3 days before renewal
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: renewalDate) {
            let content = UNMutableNotificationContent()
            content.title = "Subscription Renewal Reminder"
            content.body = "Your subscription will renew on \(formatDate(renewalDate)). Make sure your payment method is up to date."
            content.sound = .default
            content.categoryIdentifier = "subscription_renewal"

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "renewal_reminder",
                content: content,
                trigger: trigger
            )

            try? await notificationCenter.add(request)
        }
    }

    // MARK: - Private Methods

    private func updateRenewalStatus(newStatus: SharedModels.SubscriptionStatus, entitlement: SubscriptionEntitlementInfo) async {
        nextRenewalDate = entitlement.nextBillingDate

        switch newStatus {
        case .active:
            renewalStatus = entitlement.willAutoRenew ? .autoRenewEnabled : .autoRenewDisabled
        case .trial:
            renewalStatus = .inTrial
        case .gracePeriod:
            renewalStatus = .billingRetry
        case .expired:
            renewalStatus = .expired
        case .revoked:
            renewalStatus = .cancelled
        }
    }

    private func handleSuccessfulRenewal(entitlement: SubscriptionEntitlementInfo) async {
        billingIssueCount = 0
        gracePeriodEndDate = nil

        await sendRenewalSuccessNotification()
        onRenewalSuccess?(entitlement.productID)
    }

    private func handleBillingIssue(entitlement: SubscriptionEntitlementInfo) async {
        billingIssueCount += 1

        let gracePeriodEnd = Calendar.current.date(
            byAdding: .day,
            value: gracePeriodDays,
            to: entitlement.nextBillingDate ?? Date()
        ) ?? Date()

        gracePeriodEndDate = gracePeriodEnd

        await sendBillingIssueNotification(gracePeriodEnd: gracePeriodEnd)
        onRenewalFailure?(entitlement.productID, .paymentDeclined)
    }

    private func handleRenewalFailure(entitlement: SubscriptionEntitlementInfo) async {
        await sendRenewalFailureNotification()
        onRenewalFailure?(entitlement.productID, .subscriptionExpired)
    }

    private func handleSubscriptionRevoked(entitlement: SubscriptionEntitlementInfo) async {
        billingIssueCount = 0
        gracePeriodEndDate = nil
        renewalStatus = .cancelled

        await sendSubscriptionRevokedNotification()
        onRenewalFailure?(entitlement.productID, .refunded)
    }

    private func requestNotificationPermissions() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            if !granted {
                print("Notification permissions not granted")
            }
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }

    private func sendRenewalSuccessNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewed"
        content.body = "Your subscription has been successfully renewed. Thanks for being a valued customer!"
        content.sound = .default
        content.categoryIdentifier = "subscription_renewal"

        let request = UNNotificationRequest(
            identifier: "renewal_success_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func sendBillingIssueNotification(gracePeriodEnd: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Billing Issue - Action Required"
        content.body = "We couldn't process your payment. Please update your payment method by \(formatDate(gracePeriodEnd)) to continue your subscription."
        content.sound = .default
        content.categoryIdentifier = "billing_issue"

        let request = UNNotificationRequest(
            identifier: "billing_issue_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func sendRenewalFailureNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Expired"
        content.body = "Your subscription has expired. Tap to renew and continue enjoying premium features."
        content.sound = .default
        content.categoryIdentifier = "subscription_expired"

        let request = UNNotificationRequest(
            identifier: "renewal_failure_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func sendSubscriptionRevokedNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Cancelled"
        content.body = "Your subscription has been cancelled. Your access will continue until the end of your billing period."
        content.sound = .default
        content.categoryIdentifier = "subscription_cancelled"

        let request = UNNotificationRequest(
            identifier: "subscription_revoked_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func scheduleGracePeriodNotification(endDate: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Grace Period Ending Soon"
        content.body = "Your subscription grace period ends on \(formatDate(endDate)). Please update your payment method to avoid service interruption."
        content.sound = .default
        content.categoryIdentifier = "grace_period_ending"

        // Schedule notification 1 day before grace period ends
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) {
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "grace_period_reminder",
                content: content,
                trigger: trigger
            )

            try? await notificationCenter.add(request)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

public enum RenewalStatus: String, Codable {
    case unknown = "unknown"
    case autoRenewEnabled = "autoRenewEnabled"
    case autoRenewDisabled = "autoRenewDisabled"
    case inTrial = "inTrial"
    case billingRetry = "billingRetry"
    case expired = "expired"
    case cancelled = "cancelled"
}

public enum BillingIssueReason: String, Codable {
    case paymentDeclined = "paymentDeclined"
    case cardExpired = "cardExpired"
    case insufficientFunds = "insufficientFunds"
    case subscriptionExpired = "subscriptionExpired"
    case refunded = "refunded"
    case unknown = "unknown"
}