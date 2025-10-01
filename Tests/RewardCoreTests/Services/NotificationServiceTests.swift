import XCTest
import UserNotifications
@testable import RewardCore
@testable import SharedModels

class NotificationServiceTests: XCTestCase {
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
    
    func testRequestAuthorization() async throws {
        let authorized = try await notificationService.requestAuthorization()
        XCTAssertTrue(authorized)
        XCTAssertTrue(mockNotificationCenter.authorizationRequested)
    }
    
    func testScheduleNotificationWhenGloballyDisabled() async throws {
        let childProfile = createMockChildProfile()
        let preferences = NotificationPreferences(notificationsEnabled: false)
        
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // No notifications should be scheduled
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    func testScheduleNotificationWhenEventTypeDisabled() async throws {
        let childProfile = createMockChildProfile()
        var preferences = NotificationPreferences()
        preferences.enabledNotifications = [] // Disable all notification types
        
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // No notifications should be scheduled
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    func testScheduleNotificationWithinQuietHours() async throws {
        let childProfile = createMockChildProfile()
        var preferences = NotificationPreferences()
        
        // Set quiet hours to current time
        let now = Date()
        preferences.quietHoursStart = Calendar.current.date(byAdding: .hour, value: -1, to: now)
        preferences.quietHoursEnd = Calendar.current.date(byAdding: .hour, value: 1, to: now)
        
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // No notifications should be scheduled during quiet hours
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    func testScheduleNotificationSuccess() async throws {
        let childProfile = createMockChildProfile()
        let preferences = NotificationPreferences()
        
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // Notification should be scheduled
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 1)
        
        let request = mockNotificationCenter.addedRequests.first!
        XCTAssertEqual(request.content.title, "\(childProfile.name) earned points!")
        XCTAssertTrue(request.content.body.contains("10 points"))
    }
    
    func testCancelAllNotifications() async throws {
        try await notificationService.cancelAllNotifications()
        
        XCTAssertTrue(mockNotificationCenter.removedAllPendingRequests)
        XCTAssertTrue(mockNotificationCenter.removedAllDeliveredNotifications)
    }
    
    func testUpdateAndGetPreferences() async throws {
        let childProfileID = "test-child-id"
        let preferences = NotificationPreferences(
            enabledNotifications: [.pointsEarned, .goalAchieved],
            quietHoursStart: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()),
            quietHoursEnd: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()),
            digestMode: true,
            notificationsEnabled: true
        )
        
        try await notificationService.updatePreferences(preferences, for: childProfileID)
        
        let retrievedPreferences = try await notificationService.getPreferences(for: childProfileID)
        
        XCTAssertEqual(retrievedPreferences.enabledNotifications, preferences.enabledNotifications)
        XCTAssertEqual(retrievedPreferences.quietHoursStart, preferences.quietHoursStart)
        XCTAssertEqual(retrievedPreferences.quietHoursEnd, preferences.quietHoursEnd)
        XCTAssertEqual(retrievedPreferences.digestMode, preferences.digestMode)
        XCTAssertEqual(retrievedPreferences.notificationsEnabled, preferences.notificationsEnabled)
    }
    
    // MARK: - Helper Methods
    
    private func createMockChildProfile() -> ChildProfile {
        ChildProfile(
            id: "mock-child-id",
            familyID: "mock-family-id",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 500
        )
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