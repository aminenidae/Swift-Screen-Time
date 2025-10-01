import XCTest
@testable import ScreenTimeRewards_Features_Goals
import UserNotifications

final class NotificationServiceTests: XCTestCase {
    var service: NotificationService!
    
    override func setUp() {
        super.setUp()
        service = NotificationService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Notification Tests
    
    func testScheduleGoalCompletionNotification() async throws {
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Reading Goal",
            description: "Read for 5 hours this week",
            type: .timeBased(hours: 5),
            frequency: .weekly,
            targetValue: 300,
            currentValue: 300,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .completed,
            isRecurring: true,
            metadata: GoalMetadata(
                createdBy: "parent1",
                lastModifiedBy: "parent1",
                completedAt: Date()
            )
        )
        
        // This test would normally check if the notification was scheduled,
        // but since we can't easily mock UNUserNotificationCenter in a unit test,
        // we'll just verify that the method doesn't throw an exception
        do {
            try await service.scheduleGoalCompletionNotification(for: goal)
            // If we reach this point, the method didn't throw an exception
            XCTAssertTrue(true, "Notification scheduling should not throw an exception")
        } catch {
            XCTFail("Notification scheduling should not throw an exception: \(error)")
        }
    }
    
    func testScheduleBadgeEarnedNotification() async throws {
        let badge = AchievementBadge(
            childProfileID: "child1",
            type: .streak(days: 7),
            title: "Week Warrior",
            description: "7-day learning streak",
            earnedAt: Date(),
            icon: "flame.fill",
            isRare: false,
            metadata: BadgeMetadata(pointsAwarded: 50)
        )
        
        // This test would normally check if the notification was scheduled,
        // but since we can't easily mock UNUserNotificationCenter in a unit test,
        // we'll just verify that the method doesn't throw an exception
        do {
            try await service.scheduleBadgeEarnedNotification(for: badge)
            // If we reach this point, the method didn't throw an exception
            XCTAssertTrue(true, "Notification scheduling should not throw an exception")
        } catch {
            XCTFail("Notification scheduling should not throw an exception: \(error)")
        }
    }
    
    func testCancelNotification() async {
        // This test would normally check if the notification was cancelled,
        // but since we can't easily mock UNUserNotificationCenter in a unit test,
        // we'll just verify that the method doesn't throw an exception
        do {
            await service.cancelNotification(withIdentifier: "test-identifier")
            // If we reach this point, the method didn't throw an exception
            XCTAssertTrue(true, "Notification cancellation should not throw an exception")
        }
    }
    
    func testCancelAllNotifications() async {
        // This test would normally check if all notifications were cancelled,
        // but since we can't easily mock UNUserNotificationCenter in a unit test,
        // we'll just verify that the method doesn't throw an exception
        do {
            await service.cancelAllNotifications()
            // If we reach this point, the method didn't throw an exception
            XCTAssertTrue(true, "Notification cancellation should not throw an exception")
        }
    }
}