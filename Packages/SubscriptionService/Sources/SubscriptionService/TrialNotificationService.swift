import Foundation
import UserNotifications
import SharedModels

/// Service responsible for scheduling and managing trial reminder notifications
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class TrialNotificationService: ObservableObject {
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: AppError?

    private let notificationCenter: UNUserNotificationCenter
    private let familyRepository: FamilyRepository

    public init(familyRepository: FamilyRepository, notificationCenter: UNUserNotificationCenter = .current()) {
        self.familyRepository = familyRepository
        self.notificationCenter = notificationCenter
    }

    /// Schedule all trial reminder notifications for a family
    /// - Parameter familyID: The family ID to schedule notifications for
    public func scheduleTrialNotifications(for familyID: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            // Request notification permissions first
            try await requestNotificationPermissions()

            // Get family trial information
            guard let family = try await familyRepository.fetchFamily(id: familyID),
                  let metadata = family.subscriptionMetadata,
                  let trialEndDate = metadata.trialEndDate else {
                await updateError(.familyAccessDenied)
                return
            }

            // Cancel any existing trial notifications for this family
            await cancelTrialNotifications(for: familyID)

            // Schedule notifications at specific intervals
            await scheduleNotification(
                familyID: familyID,
                daysBeforeExpiration: 7,
                trialEndDate: trialEndDate
            )

            await scheduleNotification(
                familyID: familyID,
                daysBeforeExpiration: 3,
                trialEndDate: trialEndDate
            )

            await scheduleNotification(
                familyID: familyID,
                daysBeforeExpiration: 1,
                trialEndDate: trialEndDate
            )

            // Schedule trial expiration notification
            await scheduleExpirationNotification(
                familyID: familyID,
                trialEndDate: trialEndDate
            )

        } catch {
            await updateError(error as? AppError ?? .systemError(error.localizedDescription))
        }
    }

    /// Cancel all trial notifications for a family
    /// - Parameter familyID: The family ID to cancel notifications for
    public func cancelTrialNotifications(for familyID: String) async {
        let identifiers = [
            trialReminderIdentifier(familyID: familyID, days: 7),
            trialReminderIdentifier(familyID: familyID, days: 3),
            trialReminderIdentifier(familyID: familyID, days: 1),
            trialExpirationIdentifier(familyID: familyID)
        ]

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Check if notification permissions are granted
    public func checkNotificationPermissions() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Get pending trial notifications for a family
    public func getPendingTrialNotifications(for familyID: String) async -> [UNNotificationRequest] {
        let allPending = await notificationCenter.pendingNotificationRequests()

        return allPending.filter { request in
            request.identifier.hasPrefix("trial_\(familyID)")
        }
    }

    // MARK: - Private Methods

    private func requestNotificationPermissions() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        let granted = try await notificationCenter.requestAuthorization(options: options)

        if !granted {
            throw AppError.operationNotAllowed("Notification permissions denied")
        }
    }

    private func scheduleNotification(
        familyID: String,
        daysBeforeExpiration: Int,
        trialEndDate: Date
    ) async {
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBeforeExpiration,
            to: trialEndDate
        )!

        // Don't schedule if the notification date is in the past
        if notificationDate <= Date() {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Trial Reminder"
        content.body = createReminderMessage(daysRemaining: daysBeforeExpiration)
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TRIAL_REMINDER"
        content.userInfo = [
            "familyID": familyID,
            "type": "trial_reminder",
            "daysRemaining": daysBeforeExpiration
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: trialReminderIdentifier(familyID: familyID, days: daysBeforeExpiration),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            await updateError(.systemError("Failed to schedule notification: \(error.localizedDescription)"))
        }
    }

    private func scheduleExpirationNotification(
        familyID: String,
        trialEndDate: Date
    ) async {
        // Schedule notification for 1 hour after trial expires
        let notificationDate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: trialEndDate
        )!

        let content = UNMutableNotificationContent()
        content.title = "Trial Expired"
        content.body = "Your free trial has ended. Subscribe now to continue using premium features!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TRIAL_EXPIRED"
        content.userInfo = [
            "familyID": familyID,
            "type": "trial_expired"
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: trialExpirationIdentifier(familyID: familyID),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            await updateError(.systemError("Failed to schedule expiration notification: \(error.localizedDescription)"))
        }
    }

    private func createReminderMessage(daysRemaining: Int) -> String {
        switch daysRemaining {
        case 7:
            return "Your free trial ends in 1 week. Subscribe now to continue enjoying premium features!"
        case 3:
            return "Only 3 days left in your free trial. Don't lose access to premium features - subscribe today!"
        case 1:
            return "Last chance! Your free trial ends tomorrow. Subscribe now to keep your premium access."
        default:
            return "Your free trial is ending soon. Subscribe to continue using premium features."
        }
    }

    private func trialReminderIdentifier(familyID: String, days: Int) -> String {
        return "trial_\(familyID)_reminder_\(days)d"
    }

    private func trialExpirationIdentifier(familyID: String) -> String {
        return "trial_\(familyID)_expired"
    }

    private func updateError(_ error: AppError) async {
        await MainActor.run {
            self.error = error
        }
    }
}

// MARK: - Notification Categories

@available(iOS 15.0, macOS 12.0, *)
extension TrialNotificationService {
    /// Set up notification categories for trial notifications
    public func setupNotificationCategories() {
        let subscribeAction = UNNotificationAction(
            identifier: "SUBSCRIBE_ACTION",
            title: "Subscribe",
            options: [.foreground]
        )

        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER_ACTION",
            title: "Remind Later",
            options: []
        )

        let trialReminderCategory = UNNotificationCategory(
            identifier: "TRIAL_REMINDER",
            actions: [subscribeAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )

        let trialExpiredCategory = UNNotificationCategory(
            identifier: "TRIAL_EXPIRED",
            actions: [subscribeAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            trialReminderCategory,
            trialExpiredCategory
        ])
    }

    /// Handle notification action responses
    public func handleNotificationAction(
        _ actionIdentifier: String,
        for notification: UNNotification
    ) async {
        let userInfo = notification.request.content.userInfo

        switch actionIdentifier {
        case "SUBSCRIBE_ACTION":
            // Handle subscribe action - would trigger paywall presentation
            break

        case "REMIND_LATER_ACTION":
            // Reschedule reminder for tomorrow
            if let familyID = userInfo["familyID"] as? String,
               let daysRemaining = userInfo["daysRemaining"] as? Int {
                await rescheduleReminder(familyID: familyID, daysRemaining: daysRemaining - 1)
            }

        default:
            break
        }
    }

    private func rescheduleReminder(familyID: String, daysRemaining: Int) async {
        guard daysRemaining > 0 else { return }

        // Schedule a new reminder for tomorrow
        let notificationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let content = UNMutableNotificationContent()
        content.title = "Trial Reminder"
        content.body = createReminderMessage(daysRemaining: daysRemaining)
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TRIAL_REMINDER"
        content.userInfo = [
            "familyID": familyID,
            "type": "trial_reminder",
            "daysRemaining": daysRemaining
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "trial_\(familyID)_reminder_rescheduled",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            await updateError(.systemError("Failed to reschedule reminder: \(error.localizedDescription)"))
        }
    }
}