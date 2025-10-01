import XCTest
@testable import ScreenTimeRewards
@testable import SharedModels
@testable import RewardCore

class NotificationIntegrationTests: XCTestCase {
    var notificationService: NotificationService!
    var mockNotificationCenter: MockUNUserNotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockNotificationCenter = MockUNUserNotificationCenter()
        notificationService = NotificationService(notificationCenter: mockNotificationCenter)
    }
    
    override func tearDown() {
        notificationService = nil
        mockNotificationCenter = nil
        super.tearDown()
    }
    
    func testCompleteNotificationFlow() async throws {
        // 1. Request authorization
        let authorized = try await notificationService.requestAuthorization()
        XCTAssertTrue(authorized)
        XCTAssertTrue(mockNotificationCenter.authorizationRequested)
        
        // 2. Create a child profile
        let childProfile = ChildProfile(
            id: "test-child-1",
            familyID: "test-family-1",
            name: "Alice",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 50,
            totalPointsEarned: 200
        )
        
        // 3. Set up notification preferences
        var preferences = NotificationPreferences()
        preferences.notificationsEnabled = true
        preferences.enabledNotifications = [.pointsEarned, .goalAchieved]
        preferences.quietHoursStart = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())
        preferences.quietHoursEnd = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date())
        
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // 4. Schedule a points earned notification
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 25, "totalPoints": 225]
        )
        
        // 5. Verify notification was scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 1)
        let pointsRequest = mockNotificationCenter.addedRequests[0]
        XCTAssertEqual(pointsRequest.content.title, "Alice earned points!")
        XCTAssertTrue(pointsRequest.content.body.contains("25 points"))
        
        // 6. Schedule a goal achieved notification
        try await notificationService.scheduleNotification(
            for: .goalAchieved,
            childProfile: childProfile,
            payload: ["goalTitle": "Read 30 minutes daily", "streakDays": 7]
        )
        
        // 7. Verify second notification was scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 2)
        let goalRequest = mockNotificationCenter.addedRequests[1]
        XCTAssertEqual(goalRequest.content.title, "Alice achieved a goal!")
        XCTAssertTrue(goalRequest.content.body.contains("Read 30 minutes daily"))
        
        // 8. Try to schedule a disabled notification type
        try await notificationService.scheduleNotification(
            for: .weeklyMilestone,
            childProfile: childProfile,
            payload: ["hours": 10]
        )
        
        // 9. Verify no additional notification was scheduled (weeklyMilestone is disabled)
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 2)
        
        // 10. Disable all notifications
        preferences.notificationsEnabled = false
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // 11. Try to schedule a notification with all notifications disabled
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 50]
        )
        
        // 12. Verify no additional notification was scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 2)
        
        // 13. Cancel all notifications
        try await notificationService.cancelAllNotifications()
        
        // 14. Verify all notifications were cancelled
        XCTAssertTrue(mockNotificationCenter.removedAllPendingRequests)
        XCTAssertTrue(mockNotificationCenter.removedAllDeliveredNotifications)
    }
    
    func testQuietHoursEnforcement() async throws {
        // Create a child profile
        let childProfile = ChildProfile(
            id: "test-child-2",
            familyID: "test-family-2",
            name: "Bob",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 75,
            totalPointsEarned: 300
        )
        
        // Set up notification preferences with quiet hours that include current time
        var preferences = NotificationPreferences()
        preferences.notificationsEnabled = true
        preferences.enabledNotifications = [.pointsEarned]
        
        // Set quiet hours to current time +/- 1 hour
        let now = Date()
        preferences.quietHoursStart = Calendar.current.date(byAdding: .hour, value: -1, to: now)
        preferences.quietHoursEnd = Calendar.current.date(byAdding: .hour, value: 1, to: now)
        
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // Try to schedule a notification during quiet hours
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // Verify no notification was scheduled
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    func testCooldownPeriodEnforcement() async throws {
        // Create a child profile
        let childProfile = ChildProfile(
            id: "test-child-3",
            familyID: "test-family-3",
            name: "Charlie",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 400
        )
        
        // Set up notification preferences
        var preferences = NotificationPreferences()
        preferences.notificationsEnabled = true
        preferences.enabledNotifications = [.pointsEarned]
        preferences.lastNotificationSent = Date() // Set last sent to now
        
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // Try to schedule a notification immediately after the last one (within cooldown period)
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 15]
        )
        
        // Verify no notification was scheduled due to cooldown
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
        
        // Update preferences with last notification sent 31 minutes ago (beyond cooldown)
        preferences.lastNotificationSent = Calendar.current.date(byAdding: .minute, value: -31, to: Date())
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // Try to schedule a notification again
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 20]
        )
        
        // Verify notification was scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 1)
    }
}

// MARK: - Mock UNUserNotificationCenter

class MockUNUserNotificationCenter: UNUserNotificationCenter {
    var authorizationRequested = false
    var addedRequests: [UNNotificationRequest] = []
    var removedAllPendingRequests = false
    var removedAllDeliveredNotifications = false
    
    override func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authorizationRequested = true
        return true
    }
    
    override func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
    
    override func removeAllPendingNotificationRequests() {
        removedAllPendingRequests = true
    }
    
    override func removeAllDeliveredNotifications() {
        removedAllDeliveredNotifications = true
    }
}