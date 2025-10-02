import Foundation
import StoreKit
import UserNotifications
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class SubscriptionCancellationDetector: ObservableObject {
    @Published public private(set) var cancellationDetected: Bool = false
    @Published public private(set) var cancellationDate: Date?
    @Published public private(set) var accessEndDate: Date?
    @Published public private(set) var hasShownResubscriptionOffer: Bool = false

    private let notificationCenter: UNUserNotificationCenter
    private var previousAutoRenewStatus: Bool = false

    // Callbacks for cancellation events
    public var onCancellationDetected: ((Date) -> Void)?
    public var onAccessEnding: ((Date) -> Void)?
    public var onResubscriptionOfferShown: (() -> Void)?

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    /// Process subscription status changes to detect cancellations
    public func processStatusChange(
        from oldStatus: SharedModels.SubscriptionStatus?,
        to newStatus: SharedModels.SubscriptionStatus,
        entitlement: SubscriptionEntitlementInfo?
    ) async {
        guard let entitlement = entitlement else { return }

        // Check for auto-renewal status changes
        let currentAutoRenew = entitlement.willAutoRenew

        if previousAutoRenewStatus && !currentAutoRenew {
            // Auto-renewal was turned off - cancellation detected
            await handleCancellationDetected(entitlement: entitlement)
        }

        previousAutoRenewStatus = currentAutoRenew

        // Handle specific status transitions that indicate cancellation
        switch newStatus {
        case .revoked:
            await handleSubscriptionRevoked(entitlement: entitlement)
        case .expired:
            if oldStatus == .active || oldStatus == .trial {
                await handleSubscriptionExpired(entitlement: entitlement)
            }
        default:
            break
        }
    }

    /// Check if user has cancelled subscription but still has access
    public func checkCancellationWithAccess(entitlement: SubscriptionEntitlementInfo) -> Bool {
        let now = Date()

        // If auto-renewal is off but subscription hasn't expired yet
        if !entitlement.willAutoRenew,
           let expirationDate = entitlement.nextBillingDate,
           now < expirationDate {
            return true
        }

        return false
    }

    /// Present resubscription offer if appropriate
    public func presentResubscriptionOfferIfNeeded(entitlement: SubscriptionEntitlementInfo?) async {
        guard let entitlement = entitlement,
              !hasShownResubscriptionOffer,
              cancellationDetected else { return }

        let now = Date()

        // Show offer if we're within 7 days of expiration
        if let expirationDate = entitlement.nextBillingDate,
           let sevenDaysBeforeExpiration = Calendar.current.date(byAdding: .day, value: -7, to: expirationDate),
           now >= sevenDaysBeforeExpiration,
           now < expirationDate {

            hasShownResubscriptionOffer = true
            await scheduleResubscriptionOffer(expirationDate: expirationDate)
            onResubscriptionOfferShown?()
        }
    }

    /// Mark that resubscription offer has been dismissed
    public func markResubscriptionOfferDismissed() {
        hasShownResubscriptionOffer = true
    }

    /// Reset cancellation state (e.g., when user resubscribes)
    public func resetCancellationState() {
        cancellationDetected = false
        cancellationDate = nil
        accessEndDate = nil
        hasShownResubscriptionOffer = false
    }
    
    #if DEBUG
    /// Test method to set cancellation detected state
    public func setCancellationDetected(_ detected: Bool, date: Date? = nil, accessEndDate: Date? = nil) {
        cancellationDetected = detected
        cancellationDate = date
        self.accessEndDate = accessEndDate
    }
    
    /// Test method to set resubscription offer shown state
    public func setHasShownResubscriptionOffer(_ shown: Bool) {
        hasShownResubscriptionOffer = shown
    }
    #endif

    // MARK: - Private Methods

    private func handleCancellationDetected(entitlement: SubscriptionEntitlementInfo) async {
        let now = Date()

        cancellationDetected = true
        cancellationDate = now
        accessEndDate = entitlement.nextBillingDate

        await sendCancellationConfirmedNotification(endDate: entitlement.nextBillingDate)
        onCancellationDetected?(now)

        // Schedule reminder notifications
        await scheduleAccessEndingReminders(endDate: entitlement.nextBillingDate)
    }

    private func handleSubscriptionRevoked(entitlement: SubscriptionEntitlementInfo) async {
        let now = Date()

        cancellationDetected = true
        cancellationDate = now
        accessEndDate = now // Access ends immediately for revoked subscriptions

        await sendSubscriptionRevokedNotification()
        onCancellationDetected?(now)
    }

    private func handleSubscriptionExpired(entitlement: SubscriptionEntitlementInfo) async {
        let now = Date()

        if cancellationDetected {
            // This is expected expiration after cancellation
            await sendSubscriptionExpiredNotification()
            onAccessEnding?(now)
        } else {
            // Unexpected expiration (billing failure)
            await sendUnexpectedExpirationNotification()
        }
    }

    private func sendCancellationConfirmedNotification(endDate: Date?) async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Cancelled"

        if let endDate = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            content.body = "Your subscription has been cancelled. You'll continue to have access until \(formatter.string(from: endDate))."
        } else {
            content.body = "Your subscription has been cancelled. Your access will continue until the end of your current billing period."
        }

        content.sound = .default
        content.categoryIdentifier = "subscription_cancelled"

        let request = UNNotificationRequest(
            identifier: "cancellation_confirmed_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func sendSubscriptionRevokedNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Refunded"
        content.body = "Your subscription has been refunded and access has been immediately revoked. Thank you for trying our service."
        content.sound = .default
        content.categoryIdentifier = "subscription_revoked"

        let request = UNNotificationRequest(
            identifier: "subscription_revoked_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func sendSubscriptionExpiredNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Ended"
        content.body = "Your subscription has ended. We'd love to have you back! Tap to resubscribe and continue enjoying premium features."
        content.sound = .default
        content.categoryIdentifier = "subscription_ended"

        let request = UNNotificationRequest(
            identifier: "subscription_expired_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func sendUnexpectedExpirationNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Issue"
        content.body = "There was an issue with your subscription. Please check your payment method or contact support."
        content.sound = .default
        content.categoryIdentifier = "subscription_issue"

        let request = UNNotificationRequest(
            identifier: "unexpected_expiration_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func scheduleAccessEndingReminders(endDate: Date?) async {
        guard let endDate = endDate else { return }

        // Remove existing reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "access_ending_7_days",
            "access_ending_1_day",
            "access_ending_1_hour"
        ])

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        // 7 days before
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate),
           reminderDate > Date() {
            await scheduleAccessEndingNotification(
                identifier: "access_ending_7_days",
                title: "Access Ending Soon",
                body: "Your subscription access ends in 7 days on \(formatter.string(from: endDate)). Resubscribe to continue.",
                date: reminderDate
            )
        }

        // 1 day before
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate),
           reminderDate > Date() {
            await scheduleAccessEndingNotification(
                identifier: "access_ending_1_day",
                title: "Access Ends Tomorrow",
                body: "Your subscription access ends tomorrow. Don't miss out - resubscribe now!",
                date: reminderDate
            )
        }

        // 1 hour before
        if let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: endDate),
           reminderDate > Date() {
            await scheduleAccessEndingNotification(
                identifier: "access_ending_1_hour",
                title: "Access Ends in 1 Hour",
                body: "Your subscription access ends in 1 hour. Last chance to resubscribe!",
                date: reminderDate
            )
        }
    }

    private func scheduleAccessEndingNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "access_ending"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    private func scheduleResubscriptionOffer(expirationDate: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Special Offer - Come Back!"
        content.body = "We miss you! Resubscribe now and get your first month at 50% off. Limited time offer."
        content.sound = .default
        content.categoryIdentifier = "resubscription_offer"

        let request = UNNotificationRequest(
            identifier: "resubscription_offer_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }
}