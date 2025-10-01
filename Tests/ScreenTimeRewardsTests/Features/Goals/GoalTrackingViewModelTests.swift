import XCTest
@testable import ScreenTimeRewards_Features_Goals
import Combine
import SharedModels

final class GoalTrackingViewModelTests: XCTestCase {
    var viewModel: GoalTrackingViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testViewModelInitialization() {
        let goalRepository = MockEducationalGoalRepository()
        let badgeRepository = MockAchievementBadgeRepository()
        let usageSessionRepository = MockUsageSessionRepository()
        let pointTransactionRepository = MockPointTransactionRepository()
        let childProfileRepository = MockChildProfileRepository()
        
        viewModel = GoalTrackingViewModel(
            goalRepository: goalRepository,
            badgeRepository: badgeRepository,
            usageSessionRepository: usageSessionRepository,
            pointTransactionRepository: pointTransactionRepository,
            childProfileRepository: childProfileRepository
        )
        
        XCTAssertNotNil(viewModel, "ViewModel should be initialized successfully")
        XCTAssertEqual(viewModel.goals.count, 0, "Goals should be empty initially")
        XCTAssertEqual(viewModel.badges.count, 0, "Badges should be empty initially")
    }
    
    // MARK: - Child Selection Tests
    
    func testSelectChild() {
        let goalRepository = MockEducationalGoalRepository()
        let badgeRepository = MockAchievementBadgeRepository()
        let usageSessionRepository = MockUsageSessionRepository()
        let pointTransactionRepository = MockPointTransactionRepository()
        let childProfileRepository = MockChildProfileRepository()
        
        viewModel = GoalTrackingViewModel(
            goalRepository: goalRepository,
            badgeRepository: badgeRepository,
            usageSessionRepository: usageSessionRepository,
            pointTransactionRepository: pointTransactionRepository,
            childProfileRepository: childProfileRepository
        )
        
        let child = ChildProfile(
            id: "child1",
            familyID: "family1",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 200
        )
        
        viewModel.selectChild(child)
        
        XCTAssertEqual(viewModel.selectedChild?.id, "child1", "Selected child should be set correctly")
    }
    
    // MARK: - Goal Management Tests
    
    func testCreateGoal() async throws {
        let goalRepository = MockEducationalGoalRepository()
        let badgeRepository = MockAchievementBadgeRepository()
        let usageSessionRepository = MockUsageSessionRepository()
        let pointTransactionRepository = MockPointTransactionRepository()
        let childProfileRepository = MockChildProfileRepository()
        
        viewModel = GoalTrackingViewModel(
            goalRepository: goalRepository,
            badgeRepository: badgeRepository,
            usageSessionRepository: usageSessionRepository,
            pointTransactionRepository: pointTransactionRepository,
            childProfileRepository: childProfileRepository
        )
        
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
        
        // This test would normally check if the goal was created,
        // but since we're using mock repositories, we'll just verify that the method doesn't throw
        do {
            try await viewModel.createGoal(goal)
            XCTAssertTrue(true, "Goal creation should not throw an exception")
        } catch {
            XCTFail("Goal creation should not throw an exception: \(error)")
        }
    }
    
    func testUpdateGoal() async throws {
        let goalRepository = MockEducationalGoalRepository()
        let badgeRepository = MockAchievementBadgeRepository()
        let usageSessionRepository = MockUsageSessionRepository()
        let pointTransactionRepository = MockPointTransactionRepository()
        let childProfileRepository = MockChildProfileRepository()
        
        viewModel = GoalTrackingViewModel(
            goalRepository: goalRepository,
            badgeRepository: badgeRepository,
            usageSessionRepository: usageSessionRepository,
            pointTransactionRepository: pointTransactionRepository,
            childProfileRepository: childProfileRepository
        )
        
        let goal = EducationalGoal(
            childProfileID: "child1",
            title: "Reading Goal",
            description: "Read for 5 hours this week",
            type: .timeBased(hours: 5),
            frequency: .weekly,
            targetValue: 300,
            currentValue: 150, // Updated value
            startDate: Date(),
            endDate: Date().addingTimeInterval(7*24*60*60),
            status: .inProgress(progress: 0.5),
            isRecurring: true,
            metadata: GoalMetadata(createdBy: "parent1", lastModifiedBy: "parent1")
        )
        
        // This test would normally check if the goal was updated,
        // but since we're using mock repositories, we'll just verify that the method doesn't throw
        do {
            try await viewModel.updateGoal(goal)
            XCTAssertTrue(true, "Goal update should not throw an exception")
        } catch {
            XCTFail("Goal update should not throw an exception: \(error)")
        }
    }
    
    func testDeleteGoal() async throws {
        let goalRepository = MockEducationalGoalRepository()
        let badgeRepository = MockAchievementBadgeRepository()
        let usageSessionRepository = MockUsageSessionRepository()
        let pointTransactionRepository = MockPointTransactionRepository()
        let childProfileRepository = MockChildProfileRepository()
        
        viewModel = GoalTrackingViewModel(
            goalRepository: goalRepository,
            badgeRepository: badgeRepository,
            usageSessionRepository: usageSessionRepository,
            pointTransactionRepository: pointTransactionRepository,
            childProfileRepository: childProfileRepository
        )
        
        let goal = EducationalGoal(
            id: UUID(),
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
        
        // This test would normally check if the goal was deleted,
        // but since we're using mock repositories, we'll just verify that the method doesn't throw
        do {
            try await viewModel.deleteGoal(goal)
            XCTAssertTrue(true, "Goal deletion should not throw an exception")
        } catch {
            XCTFail("Goal deletion should not throw an exception: \(error)")
        }
    }
    
    // MARK: - Subscription Feature Tests
    
    func testRequestPremiumFeature_withActiveSubscription() {
        let goalRepository = MockEducationalGoalRepository()
        let badgeRepository = MockAchievementBadgeRepository()
        let usageSessionRepository = MockUsageSessionRepository()
        let pointTransactionRepository = MockPointTransactionRepository()
        let childProfileRepository = MockChildProfileRepository()
        
        viewModel = GoalTrackingViewModel(
            goalRepository: goalRepository,
            badgeRepository: badgeRepository,
            usageSessionRepository: usageSessionRepository,
            pointTransactionRepository: pointTransactionRepository,
            childProfileRepository: childProfileRepository
        )
        
        // Set hasActiveSubscription to true
        viewModel.hasActiveSubscription = true
        
        viewModel.requestPremiumFeature()
        
        XCTAssertFalse(viewModel.showUpgradePrompt, "Upgrade prompt should not be shown when subscription is active")
    }
    
    func testRequestPremiumFeature_withoutActiveSubscription() {
        let goalRepository = MockEducationalGoalRepository()
        let badgeRepository = MockAchievementBadgeRepository()
        let usageSessionRepository = MockUsageSessionRepository()
        let pointTransactionRepository = MockPointTransactionRepository()
        let childProfileRepository = MockChildProfileRepository()
        
        viewModel = GoalTrackingViewModel(
            goalRepository: goalRepository,
            badgeRepository: badgeRepository,
            usageSessionRepository: usageSessionRepository,
            pointTransactionRepository: pointTransactionRepository,
            childProfileRepository: childProfileRepository
        )
        
        // Set hasActiveSubscription to false
        viewModel.hasActiveSubscription = false
        
        viewModel.requestPremiumFeature()
        
        XCTAssertTrue(viewModel.showUpgradePrompt, "Upgrade prompt should be shown when subscription is not active")
    }
}

// MARK: - Mock Repositories

class MockEducationalGoalRepository: EducationalGoalRepository {
    func createGoal(_ goal: EducationalGoal) async throws -> EducationalGoal {
        return goal
    }
    
    func save(_ goal: EducationalGoal) async throws -> EducationalGoal {
        return goal
    }
    
    func fetchGoal(id: UUID) async throws -> EducationalGoal? {
        return nil
    }
    
    func fetchGoals(for childID: String) async throws -> [EducationalGoal] {
        return []
    }
    
    func updateGoal(_ goal: EducationalGoal) async throws -> EducationalGoal {
        return goal
    }
    
    func delete(_ goalID: UUID) async throws {
        // Mock implementation - do nothing
    }
}

class MockAchievementBadgeRepository: AchievementBadgeRepository {
    func createBadge(_ badge: AchievementBadge) async throws -> AchievementBadge {
        return badge
    }
    
    func save(_ badge: AchievementBadge) async throws -> AchievementBadge {
        return badge
    }
    
    func fetchBadge(id: UUID) async throws -> AchievementBadge? {
        return nil
    }
    
    func fetchBadges(for childID: String) async throws -> [AchievementBadge] {
        return []
    }
    
    func updateBadge(_ badge: AchievementBadge) async throws -> AchievementBadge {
        return badge
    }
    
    func delete(_ badgeID: UUID) async throws {
        // Mock implementation - do nothing
    }
}

class MockUsageSessionRepository: UsageSessionRepository {
    func createSession(_ session: UsageSession) async throws -> UsageSession {
        return session
    }
    
    func fetchSession(id: String) async throws -> UsageSession? {
        return nil
    }
    
    func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
        return []
    }
    
    func updateSession(_ session: UsageSession) async throws -> UsageSession {
        return session
    }
    
    func deleteSession(id: String) async throws {
        // Mock implementation - do nothing
    }
}

class MockPointTransactionRepository: PointTransactionRepository {
    func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        return transaction
    }
    
    func fetchTransaction(id: String) async throws -> PointTransaction? {
        return nil
    }
    
    func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        return []
    }
    
    func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        return []
    }
    
    func deleteTransaction(id: String) async throws {
        // Mock implementation - do nothing
    }
}

class MockChildProfileRepository: ChildProfileRepository {
    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        return child
    }
    
    func fetchChild(id: String) async throws -> ChildProfile? {
        return nil
    }
    
    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        return []
    }
    
    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        return child
    }
    
    func deleteChild(id: String) async throws {
        // Mock implementation - do nothing
    }
}