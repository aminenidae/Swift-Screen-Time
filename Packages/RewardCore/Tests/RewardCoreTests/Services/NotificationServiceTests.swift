import XCTest
@testable import RewardCore
@testable import SharedModels
import UserNotifications

final class NotificationServiceTests: XCTestCase {
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
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization_ReturnsTrue() async throws {
        // Given
        mockNotificationCenter.authorizationResult = true
        
        // When
        let result = try await notificationService.requestAuthorization()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockNotificationCenter.requestAuthorizationCalled)
    }
    
    func testRequestAuthorization_ReturnsFalse() async throws {
        // Given
        mockNotificationCenter.authorizationResult = false
        
        // When
        let result = try await notificationService.requestAuthorization()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertTrue(mockNotificationCenter.requestAuthorizationCalled)
    }
    
    // MARK: - Notification Scheduling Tests
    
    func testScheduleNotification_WhenNotificationsEnabled_SchedulesNotification() async throws {
        // Given
        let childProfile = createTestChildProfile()
        let preferences = RewardCore.NotificationPreferences(notificationsEnabled: true)
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // When
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // Then
        XCTAssertTrue(mockNotificationCenter.addCalled)
        XCTAssertEqual(mockNotificationCenter.addedRequests.count, 1)
        
        let request = mockNotificationCenter.addedRequests.first!
        XCTAssertEqual(request.identifier, "\(childProfile.id)_points_earned_")
        XCTAssertEqual(request.content.title, "Test Child earned points!")
        XCTAssertTrue(request.content.body.contains("10 points"))
    }
    
    func testScheduleNotification_WhenNotificationsDisabled_DoesNotSchedule() async throws {
        // Given
        let childProfile = createTestChildProfile()
        let preferences = RewardCore.NotificationPreferences(notificationsEnabled: false)
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // When
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // Then
        XCTAssertFalse(mockNotificationCenter.addCalled)
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    func testScheduleNotification_WhenEventNotEnabled_DoesNotSchedule() async throws {
        // Given
        let childProfile = createTestChildProfile()
        let preferences = RewardCore.NotificationPreferences(
            enabledNotifications: [], // No notifications enabled
            notificationsEnabled: true
        )
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // When
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // Then
        XCTAssertFalse(mockNotificationCenter.addCalled)
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    func testScheduleNotification_WithinQuietHours_DoesNotSchedule() async throws {
        // Given
        let childProfile = createTestChildProfile()
        let calendar = Calendar.current
        let quietStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
        let quietEnd = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        
        let preferences = RewardCore.NotificationPreferences(
            quietHoursStart: quietStart,
            quietHoursEnd: quietEnd,
            notificationsEnabled: true
        )
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // When
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // Then
        XCTAssertFalse(mockNotificationCenter.addCalled)
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    func testScheduleNotification_InCooldownPeriod_DoesNotSchedule() async throws {
        // Given
        let childProfile = createTestChildProfile()
        let preferences = RewardCore.NotificationPreferences(
            lastNotificationSent: Date(), // Just sent
            notificationsEnabled: true
        )
        try await notificationService.updatePreferences(preferences, for: childProfile.id)
        
        // When
        try await notificationService.scheduleNotification(
            for: .pointsEarned,
            childProfile: childProfile,
            payload: ["points": 10]
        )
        
        // Then
        XCTAssertFalse(mockNotificationCenter.addCalled)
        XCTAssertTrue(mockNotificationCenter.addedRequests.isEmpty)
    }
    
    // MARK: - Notification Cancellation Tests
    
    func testCancelAllNotifications_RemovesAllNotifications() async throws {
        // When
        try await notificationService.cancelAllNotifications()
        
        // Then
        XCTAssertTrue(mockNotificationCenter.removeAllPendingCalled)
        XCTAssertTrue(mockNotificationCenter.removeAllDeliveredCalled)
    }
    
    // MARK: - Preferences Tests
    
    func testUpdatePreferences_UpdatesCachedPreferences() async throws {
        // Given
        let childProfileID = "child-123"
        let preferences = RewardCore.NotificationPreferences(
            enabledNotifications: [.pointsEarned, .goalAchieved],
            notificationsEnabled: true
        )
        
        // When
        try await notificationService.updatePreferences(preferences, for: childProfileID)
        
        // Then
        let retrievedPreferences = try await notificationService.getPreferences(for: childProfileID)
        XCTAssertEqual(retrievedPreferences.enabledNotifications, preferences.enabledNotifications)
        XCTAssertEqual(retrievedPreferences.notificationsEnabled, preferences.notificationsEnabled)
    }
    
    func testGetPreferences_ReturnsDefaultWhenNotSet() async throws {
        // Given
        let childProfileID = "child-123"
        
        // When
        let preferences = try await notificationService.getPreferences(for: childProfileID)
        
        // Then
        XCTAssertEqual(preferences.enabledNotifications, Set(RewardCore.NotificationEvent.allCases))
        XCTAssertTrue(preferences.notificationsEnabled)
    }
    
    // MARK: - Private Helper Tests
    
    func testGetTitle_ReturnsCorrectTitle() {
        let childName = "Test Child"
        
        XCTAssertEqual(
            notificationService.getTitle(for: RewardCore.NotificationEvent.pointsEarned, childName: childName),
            "Test Child earned points!"
        )
        
        XCTAssertEqual(
            notificationService.getTitle(for: RewardCore.NotificationEvent.goalAchieved, childName: childName),
            "Test Child achieved a goal!"
        )
        
        XCTAssertEqual(
            notificationService.getTitle(for: RewardCore.NotificationEvent.weeklyMilestone, childName: childName),
            "Test Child reached a weekly milestone!"
        )
        
        XCTAssertEqual(
            notificationService.getTitle(for: RewardCore.NotificationEvent.streakAchieved, childName: childName),
            "Test Child is on a streak!"
        )
    }
    
    func testGetBody_ReturnsCorrectBody() {
        let childName = "Test Child"
        
        // Points earned
        let pointsBody = notificationService.getBody(
            for: RewardCore.NotificationEvent.pointsEarned,
            childName: childName,
            payload: ["points": 15]
        )
        XCTAssertTrue(pointsBody.contains("15 points"))
        
        // Goal achieved
        let goalBody = notificationService.getBody(
            for: RewardCore.NotificationEvent.goalAchieved,
            childName: childName,
            payload: ["goalTitle": "Math Mastery"]
        )
        XCTAssertTrue(goalBody.contains("Math Mastery"))
        
        // Weekly milestone
        let weeklyBody = notificationService.getBody(
            for: RewardCore.NotificationEvent.weeklyMilestone,
            childName: childName,
            payload: ["hours": 10]
        )
        XCTAssertTrue(weeklyBody.contains("10 hours"))
        
        // Streak achieved
        let streakBody = notificationService.getBody(
            for: RewardCore.NotificationEvent.streakAchieved,
            childName: childName,
            payload: ["days": 7]
        )
        XCTAssertTrue(streakBody.contains("7-day"))
    }
    
    // MARK: - Helper Methods
    
    private func createTestChildProfile() -> ChildProfile {
        return ChildProfile(
            id: "child-123",
            familyID: "family-123",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100
        )
    }
}

// MARK: - Mock Classes

// MARK: - Mock UNUserNotificationCenter

class MockUNUserNotificationCenter: UNUserNotificationCenterProtocol {
    var authorizationResult: Bool = false
    var requestAuthorizationCalled = false
    var addCalled = false
    var addedRequests: [UNNotificationRequest] = []
    var removeAllPendingCalled = false
    var removeAllDeliveredCalled = false

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationCalled = true
        return authorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        addCalled = true
        let mutableRequest = request
        // Hack to make the identifier testable (UNNotificationRequest's identifier is read-only)
        addedRequests.append(mutableRequest)
    }

    func removeAllPendingNotificationRequests() async {
        removeAllPendingCalled = true
    }

    func removeAllDeliveredNotifications() async {
        removeAllDeliveredCalled = true
    }

    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completionHandler(authorizationResult, nil)
    }

    func checkAuthorizationStatus(completionHandler: @escaping (Bool) -> Void) {
        completionHandler(authorizationResult)
    }
}
