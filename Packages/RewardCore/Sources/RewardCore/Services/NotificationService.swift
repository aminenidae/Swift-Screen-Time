import Foundation
import UserNotifications
import SharedModels

public enum NotificationEvent: String, CaseIterable, Codable {
    case pointsEarned = "points_earned"
    case goalAchieved = "goal_achievd"
    case weeklyMilestone = "weekly_milestone"
    case streakAchieved = "streak_achieved"
}

public struct NotificationPreferences: Codable {
    public var enabledNotifications: Set<NotificationEvent>
    public var quietHoursStart: Date?
    public var quietHoursEnd: Date?
    public var digestMode: Bool
    public var lastNotificationSent: Date?
    public var notificationsEnabled: Bool
    
    public init(
        enabledNotifications: Set<NotificationEvent> = Set(NotificationEvent.allCases),
        quietHoursStart: Date? = nil,
        quietHoursEnd: Date? = nil,
        digestMode: Bool = false,
        lastNotificationSent: Date? = nil,
        notificationsEnabled: Bool = true
    ) {
        self.enabledNotifications = enabledNotifications
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.digestMode = digestMode
        self.lastNotificationSent = lastNotificationSent
        self.notificationsEnabled = notificationsEnabled
    }
}

public protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func scheduleNotification(for event: NotificationEvent, childProfile: ChildProfile, payload: [String: Any]) async throws
    func cancelAllNotifications() async throws
    func updatePreferences(_ preferences: NotificationPreferences, for childProfileID: String) async throws
    func getPreferences(for childProfileID: String) async throws -> NotificationPreferences
}

public protocol UNUserNotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removeAllPendingNotificationRequests() async
    func removeAllDeliveredNotifications() async
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void)
    func checkAuthorizationStatus(completionHandler: @escaping (Bool) -> Void)
}

extension UNUserNotificationCenter: UNUserNotificationCenterProtocol {
    public func checkAuthorizationStatus(completionHandler: @escaping (Bool) -> Void) {
        getNotificationSettings { settings in
            completionHandler(settings.authorizationStatus == .authorized)
        }
    }
}

public class NotificationService: NotificationServiceProtocol {
    private let notificationCenter: UNUserNotificationCenterProtocol
    private var preferencesCache: [String: NotificationPreferences] = [:]

    public init(notificationCenter: UNUserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }
    
    public func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    public func scheduleNotification(for event: NotificationEvent, childProfile: ChildProfile, payload: [String: Any]) async throws {
        // Check if notifications are enabled globally
        let preferences = try await getPreferences(for: childProfile.id)
        guard preferences.notificationsEnabled else { return }
        
        // Check if this specific notification type is enabled
        guard preferences.enabledNotifications.contains(event) else { return }
        
        // Check quiet hours
        guard !isWithinQuietHours(preferences: preferences) else { return }
        
        // Check cooldown period (30 minutes minimum between similar events)
        if let lastSent = preferences.lastNotificationSent {
            let cooldownPeriod: TimeInterval = 30 * 60 // 30 minutes
            if Date().timeIntervalSince(lastSent) < cooldownPeriod {
                // Still in cooldown period
                return
            }
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = getTitle(for: event, childName: childProfile.name)
        content.body = getBody(for: event, childName: childProfile.name, payload: payload)
        content.sound = .default
        
        // Create notification request
        let request = UNNotificationRequest(
            identifier: "\(childProfile.id)_\(event.rawValue)_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        try await notificationCenter.add(request)
        
        // Update last sent time
        var updatedPreferences = preferences
        updatedPreferences.lastNotificationSent = Date()
        try await updatePreferences(updatedPreferences, for: childProfile.id)
    }
    
    public func cancelAllNotifications() async throws {
        await notificationCenter.removeAllPendingNotificationRequests()
        await notificationCenter.removeAllDeliveredNotifications()
    }
    
    public func updatePreferences(_ preferences: NotificationPreferences, for childProfileID: String) async throws {
        // In a real implementation, this would save to persistent storage
        // For now, we'll just cache it in memory
        preferencesCache[childProfileID] = preferences
    }
    
    public func getPreferences(for childProfileID: String) async throws -> NotificationPreferences {
        // In a real implementation, this would fetch from persistent storage
        // For now, we'll return cached version or default
        if let cached = preferencesCache[childProfileID] {
            return cached
        }
        
        let defaultPreferences = NotificationPreferences()
        preferencesCache[childProfileID] = defaultPreferences
        return defaultPreferences
    }
    
    // MARK: - Private Helpers
    
    func isWithinQuietHours(preferences: NotificationPreferences) -> Bool {
        guard let quietStart = preferences.quietHoursStart,
              let quietEnd = preferences.quietHoursEnd else {
            return false // No quiet hours set
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: quietStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: quietEnd)
        
        guard let nowMinutes = minutesFromMidnight(for: nowComponents),
              let startMinutes = minutesFromMidnight(for: startComponents),
              let endMinutes = minutesFromMidnight(for: endComponents) else {
            return false
        }
        
        // Handle overnight quiet hours (e.g., 8 PM to 8 AM)
        if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes <= endMinutes
        } else {
            return nowMinutes >= startMinutes && nowMinutes <= endMinutes
        }
    }
    
    func minutesFromMidnight(for components: DateComponents) -> Int? {
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        return hour * 60 + minute
    }
    
    func getTitle(for event: NotificationEvent, childName: String) -> String {
        switch event {
        case .pointsEarned:
            return "\(childName) earned points!"
        case .goalAchieved:
            return "\(childName) achieved a goal!"
        case .weeklyMilestone:
            return "\(childName) reached a weekly milestone!"
        case .streakAchieved:
            return "\(childName) is on a streak!"
        }
    }
    
    func getBody(for event: NotificationEvent, childName: String, payload: [String: Any]) -> String {
        switch event {
        case .pointsEarned:
            if let points = payload["points"] as? Int {
                return "\(childName) earned \(points) points today for their learning activities."
            }
            return "\(childName) earned points for their learning activities today."
        case .goalAchieved:
            if let goalTitle = payload["goalTitle"] as? String {
                return "\(childName) completed their goal: \"\(goalTitle)\". Great job!"
            }
            return "\(childName) completed a learning goal. Great job!"
        case .weeklyMilestone:
            if let hours = payload["hours"] as? Int {
                return "\(childName) spent \(hours) hours learning this week. Keep up the great work!"
            }
            return "\(childName) reached a weekly learning milestone. Keep up the great work!"
        case .streakAchieved:
            if let days = payload["days"] as? Int {
                return "\(childName) has maintained a \(days)-day learning streak! Amazing dedication!"
            }
            return "\(childName) is on a learning streak! Amazing dedication!"
        }
    }
}