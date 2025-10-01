import XCTest
@testable import ScreenTimeRewards_Features_Goals

final class GoalTrackingServiceTests: XCTestCase {
    var service: GoalTrackingService!
    
    override func setUp() {
        super.setUp()
        service = GoalTrackingService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Progress Calculation Tests
    
    func testCalculateGoalProgress_timeBasedGoal() {
        // Create a time-based goal for 5 hours
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Reading Goal",
            description: "Read for 5 hours this week",
            type: .timeBased(hours: 5),
            frequency: .weekly,
            targetValue: 300, // 5 hours in minutes
            currentValue: 0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .notStarted,
            isRecurring: true,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        // Create some usage sessions totaling 2.5 hours (150 minutes)
        let sessions = [
            UsageSession(
                id: "1",
                childProfileID: "child1",
                appBundleID: "com.example.reading",
                category: .learning,
                startTime: Date(),
                endTime: Date().addingTimeInterval(60*60), // 1 hour
                duration: 60*60
            ),
            UsageSession(
                id: "2",
                childProfileID: "child1",
                appBundleID: "com.example.reading",
                category: .learning,
                startTime: Date(),
                endTime: Date().addingTimeInterval(90*60), // 1.5 hours
                duration: 90*60
            )
        ]
        
        let progress = service.calculateGoalProgress(goal: goal, sessions: sessions, transactions: [])
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Progress should be 50% for 2.5 hours out of 5 hours")
    }
    
    func testCalculateGoalProgress_pointBasedGoal() {
        // Create a point-based goal for 100 points
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Math Points",
            description: "Earn 100 math points",
            type: .pointBased(points: 100),
            frequency: .weekly,
            targetValue: 100,
            currentValue: 0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .notStarted,
            isRecurring: false,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        // Create some point transactions totaling 75 points
        let transactions = [
            PointTransaction(id: "1", childProfileID: "child1", points: 25, reason: "Math app usage", timestamp: Date()),
            PointTransaction(id: "2", childProfileID: "child1", points: 50, reason: "Math app usage", timestamp: Date())
        ]
        
        let progress = service.calculateGoalProgress(goal: goal, sessions: [], transactions: transactions)
        XCTAssertEqual(progress, 0.75, accuracy: 0.01, "Progress should be 75% for 75 points out of 100 points")
    }
    
    func testCalculateGoalProgress_appSpecificGoal() {
        // Create an app-specific goal for 3 hours on Duolingo
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Duolingo Streak",
            description: "Spend 3 hours on Duolingo this week",
            type: .appSpecific(bundleID: "com.duolingo", hours: 3),
            frequency: .weekly,
            targetValue: 180, // 3 hours in minutes
            currentValue: 0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .notStarted,
            isRecurring: true,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        // Create some app sessions totaling 1.5 hours (90 minutes) on Duolingo
        let sessions = [
            UsageSession(
                id: "1",
                childProfileID: "child1",
                appBundleID: "com.duolingo",
                category: .learning,
                startTime: Date(),
                endTime: Date().addingTimeInterval(45*60), // 45 minutes
                duration: 45*60
            ),
            UsageSession(
                id: "2",
                childProfileID: "child1",
                appBundleID: "com.duolingo",
                category: .learning,
                startTime: Date(),
                endTime: Date().addingTimeInterval(45*60), // 45 minutes
                duration: 45*60
            ),
            // This session should not count toward the goal
            UsageSession(
                id: "3",
                childProfileID: "child1",
                appBundleID: "com.otherapp",
                category: .learning,
                startTime: Date(),
                endTime: Date().addingTimeInterval(60*60), // 1 hour
                duration: 60*60
            )
        ]
        
        let progress = service.calculateGoalProgress(goal: goal, sessions: sessions, transactions: [])
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Progress should be 50% for 1.5 hours out of 3 hours on Duolingo")
    }
    
    // MARK: - Goal Status Update Tests
    
    func testUpdateGoalStatus_notStarted() {
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Reading Goal",
            description: "Read for 5 hours this week",
            type: .timeBased(hours: 5),
            frequency: .weekly,
            targetValue: 300,
            currentValue: 0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .notStarted,
            isRecurring: true,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        let status = service.updateGoalStatus(goal: goal, progress: 0.0)
        XCTAssertEqual(status, .notStarted, "Goal should remain not started with 0% progress")
    }
    
    func testUpdateGoalStatus_inProgress() {
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Reading Goal",
            description: "Read for 5 hours this week",
            type: .timeBased(hours: 5),
            frequency: .weekly,
            targetValue: 300,
            currentValue: 0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .notStarted,
            isRecurring: true,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        let status = service.updateGoalStatus(goal: goal, progress: 0.5)
        if case .inProgress(let progress) = status {
            XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Goal should be in progress with 50% progress")
        } else {
            XCTFail("Goal status should be inProgress")
        }
    }
    
    func testUpdateGoalStatus_completed() {
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Reading Goal",
            description: "Read for 5 hours this week",
            type: .timeBased(hours: 5),
            frequency: .weekly,
            targetValue: 300,
            currentValue: 0,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .notStarted,
            isRecurring: true,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        let status = service.updateGoalStatus(goal: goal, progress: 1.0)
        XCTAssertEqual(status, .completed, "Goal should be completed with 100% progress")
    }
    
    func testUpdateGoalStatus_failed() {
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Reading Goal",
            description: "Read for 5 hours this week",
            type: .timeBased(hours: 5),
            frequency: .weekly,
            targetValue: 300,
            currentValue: 0,
            startDate: Date().addingTimeInterval(-14*24*60*60), // 2 weeks ago
            endDate: Date().addingTimeInterval(-7*24*60*60), // 1 week ago
            status: .notStarted,
            isRecurring: true,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        let status = service.updateGoalStatus(goal: goal, progress: 0.5)
        XCTAssertEqual(status, .failed, "Goal should be failed if it's expired")
    }
    
    // MARK: - Badge Criteria Tests
    
    func testCheckBadgeCriteria_streak() {
        let sessions = [
            // Create sessions for 5 consecutive days
            UsageSession(id: "1", childProfileID: "child1", appBundleID: "com.example.app", category: .learning, startTime: Date().addingTimeInterval(-4*24*60*60), endTime: Date().addingTimeInterval(-4*24*60*60 + 60*60), duration: 60*60),
            UsageSession(id: "2", childProfileID: "child1", appBundleID: "com.example.app", category: .learning, startTime: Date().addingTimeInterval(-3*24*60*60), endTime: Date().addingTimeInterval(-3*24*60*60 + 60*60), duration: 60*60),
            UsageSession(id: "3", childProfileID: "child1", appBundleID: "com.example.app", category: .learning, startTime: Date().addingTimeInterval(-2*24*60*60), endTime: Date().addingTimeInterval(-2*24*60*60 + 60*60), duration: 60*60),
            UsageSession(id: "4", childProfileID: "child1", appBundleID: "com.example.app", category: .learning, startTime: Date().addingTimeInterval(-1*24*60*60), endTime: Date().addingTimeInterval(-1*24*60*60 + 60*60), duration: 60*60),
            UsageSession(id: "5", childProfileID: "child1", appBundleID: "com.example.app", category: .learning, startTime: Date(), endTime: Date().addingTimeInterval(60*60), duration: 60*60)
        ]
        
        let result = service.checkBadgeCriteria(badge: .streak(days: 5), childID: "child1", sessions: sessions, transactions: [])
        XCTAssertTrue(result, "Badge criteria should be met for 5-day streak")
    }
    
    func testCheckBadgeCriteria_points() {
        let transactions = [
            PointTransaction(id: "1", childProfileID: "child1", points: 50, reason: "App usage", timestamp: Date()),
            PointTransaction(id: "2", childProfileID: "child1", points: 75, reason: "App usage", timestamp: Date())
        ]
        
        let result = service.checkBadgeCriteria(badge: .points(points: 100), childID: "child1", sessions: [], transactions: transactions)
        XCTAssertTrue(result, "Badge criteria should be met for 125 points earned")
    }
    
    func testCheckBadgeCriteria_time() {
        let sessions = [
            UsageSession(id: "1", childProfileID: "child1", appBundleID: "com.example.app", category: .learning, startTime: Date(), endTime: Date().addingTimeInterval(6*60*60), duration: 6*60*60), // 6 hours
            UsageSession(id: "2", childProfileID: "child1", appBundleID: "com.example.app", category: .learning, startTime: Date(), endTime: Date().addingTimeInterval(5*60*60), duration: 5*60*60)  // 5 hours
        ]
        
        let result = service.checkBadgeCriteria(badge: .time(hours: 10), childID: "child1", sessions: sessions, transactions: [])
        XCTAssertTrue(result, "Badge criteria should be met for 11 hours of learning")
    }
}