import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels
@testable import RewardCore

class NotificationSettingsViewModelTests: XCTestCase {
    var viewModel: NotificationSettingsViewModel!
    var mockNotificationService: MockNotificationService!
    
    override func setUp() {
        super.setUp()
        mockNotificationService = MockNotificationService()
        viewModel = NotificationSettingsViewModel(
            childProfileID: "test-child-id",
            notificationService: mockNotificationService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockNotificationService = nil
        super.tearDown()
    }
    
    func testInitialValues() {
        XCTAssertTrue(viewModel.notificationsEnabled)
        XCTAssertEqual(viewModel.enabledNotifications, Set(NotificationEvent.allCases))
        XCTAssertNotNil(viewModel.quietHoursStart)
        XCTAssertNotNil(viewModel.quietHoursEnd)
        XCTAssertFalse(viewModel.digestMode)
    }
    
    func testUpdateNotificationsEnabled() {
        viewModel.notificationsEnabled = false
        XCTAssertFalse(viewModel.notificationsEnabled)
        XCTAssertTrue(mockNotificationService.savedPreferencesCount > 0)
    }
    
    func testEnableNotificationType() {
        // Start with empty set
        viewModel.enabledNotifications = []
        
        // Enable points earned notifications
        viewModel.enabledNotifications.insert(.pointsEarned)
        
        XCTAssertTrue(viewModel.enabledNotifications.contains(.pointsEarned))
        XCTAssertTrue(mockNotificationService.savedPreferencesCount > 0)
    }
    
    func testDisableNotificationType() {
        // Start with all notifications enabled
        viewModel.enabledNotifications = Set(NotificationEvent.allCases)
        
        // Disable points earned notifications
        viewModel.enabledNotifications.remove(.pointsEarned)
        
        XCTAssertFalse(viewModel.enabledNotifications.contains(.pointsEarned))
        XCTAssertTrue(mockNotificationService.savedPreferencesCount > 0)
    }
    
    func testUpdateQuietHours() {
        let newStartTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
        let newEndTime = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!
        
        viewModel.quietHoursStart = newStartTime
        viewModel.quietHoursEnd = newEndTime
        
        XCTAssertEqual(viewModel.quietHoursStart, newStartTime)
        XCTAssertEqual(viewModel.quietHoursEnd, newEndTime)
        XCTAssertTrue(mockNotificationService.savedPreferencesCount > 0)
    }
    
    func testUpdateDigestMode() {
        viewModel.digestMode = true
        XCTAssertTrue(viewModel.digestMode)
        XCTAssertTrue(mockNotificationService.savedPreferencesCount > 0)
    }
    
    func testLoadPreferences() async throws {
        let testPreferences = NotificationPreferences(
            enabledNotifications: [.pointsEarned, .goalAchieved],
            quietHoursStart: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()),
            quietHoursEnd: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()),
            digestMode: true,
            notificationsEnabled: false
        )
        
        mockNotificationService.stubbedPreferences = testPreferences
        
        viewModel.loadPreferences()
        
        // Wait a bit for the async operation to complete
        let expectation = XCTestExpectation(description: "Preferences loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.enabledNotifications, testPreferences.enabledNotifications)
        XCTAssertEqual(viewModel.quietHoursStart, testPreferences.quietHoursStart)
        XCTAssertEqual(viewModel.quietHoursEnd, testPreferences.quietHoursEnd)
        XCTAssertEqual(viewModel.digestMode, testPreferences.digestMode)
        XCTAssertEqual(viewModel.notificationsEnabled, testPreferences.notificationsEnabled)
    }
}

// MARK: - Mock Notification Service

class MockNotificationService: NotificationServiceProtocol {
    var savedPreferencesCount = 0
    var stubbedPreferences: NotificationPreferences?
    
    func requestAuthorization() async throws -> Bool {
        return true
    }
    
    func scheduleNotification(for event: NotificationEvent, childProfile: SharedModels.ChildProfile, payload: [String : Any]) async throws {
        // No-op for testing
    }
    
    func cancelAllNotifications() async throws {
        // No-op for testing
    }
    
    func updatePreferences(_ preferences: NotificationPreferences, for childProfileID: String) async throws {
        savedPreferencesCount += 1
    }
    
    func getPreferences(for childProfileID: String) async throws -> NotificationPreferences {
        if let stubbed = stubbedPreferences {
            return stubbed
        }
        return NotificationPreferences()
    }
}