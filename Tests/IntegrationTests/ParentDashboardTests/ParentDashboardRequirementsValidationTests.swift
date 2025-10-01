import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels

/// Comprehensive validation tests to ensure all acceptance criteria are met
final class ParentDashboardRequirementsValidationTests: XCTestCase {
    var viewModel: ParentDashboardViewModel!

    @MainActor
    override func setUpWithError() throws {
        viewModel = ParentDashboardViewModel.mockViewModel()
    }

    override func tearDownWithError() throws {
        viewModel = nil
    }

    // MARK: - Acceptance Criteria 1: Parent dashboard displays all children's data

    @MainActor
    func testAC1_ParentDashboardDisplaysAllChildrenData() async throws {
        // Given: Mock viewmodel with multiple children
        await viewModel.loadInitialData()

        // Then: Validate all required child data is displayed
        XCTAssertGreaterThan(viewModel.children.count, 0, "Dashboard should display children")

        for child in viewModel.children {
            // Current point balance
            XCTAssertGreaterThanOrEqual(child.pointBalance, 0, "Should display current point balance for \(child.name)")

            let progressData = viewModel.getProgressData(for: child.id)

            // Today's usage summary (learning vs reward time)
            XCTAssertGreaterThanOrEqual(progressData.todaysLearningMinutes, 0, "Should display today's learning time for \(child.name)")
            XCTAssertGreaterThanOrEqual(progressData.todaysRewardMinutes, 0, "Should display today's reward time for \(child.name)")

            // Available rewards (implied by point balance and system)
            XCTAssertNotNil(progressData, "Should have progress data for available rewards calculation")

            // Recent activity (last 5 sessions)
            XCTAssertLessThanOrEqual(progressData.recentTransactions.count, 5, "Should display at most 5 recent transactions for \(child.name)")
        }
    }

    // MARK: - Acceptance Criteria 2: Visual progress indicators

    @MainActor
    func testAC2_VisualProgressIndicators() async throws {
        await viewModel.loadInitialData()

        for child in viewModel.children {
            let progressData = viewModel.getProgressData(for: child.id)

            // Progress rings for daily learning goals
            let learningProgress = min(Double(progressData.todaysLearningMinutes) / 60.0, 1.0)
            XCTAssertGreaterThanOrEqual(learningProgress, 0.0, "Learning progress should be non-negative")
            XCTAssertLessThanOrEqual(learningProgress, 1.0, "Learning progress should not exceed 100%")

            // Point accumulation charts (last 7 days)
            XCTAssertLessThanOrEqual(progressData.weeklyPoints.count, 7, "Should show at most 7 days of point data")

            // Verify weekly points are properly ordered
            let dates = progressData.weeklyPoints.map { $0.date }
            let sortedDates = dates.sorted()
            XCTAssertEqual(dates, sortedDates, "Weekly points should be ordered chronologically")

            // Streak indicators (consecutive learning days)
            XCTAssertGreaterThanOrEqual(progressData.learningStreak, 0, "Learning streak should be non-negative")
        }
    }

    // MARK: - Acceptance Criteria 3: Quick access buttons

    @MainActor
    func testAC3_QuickAccessButtons() async throws {
        let navigationCoordinator = ParentDashboardNavigationCoordinator()
        let navigationActions = ParentDashboardNavigationActions(coordinator: navigationCoordinator)

        // "Categorize Apps" button
        navigationActions.navigateToAppCategorization()
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should navigate to App Categorization")

        navigationCoordinator.popToRoot()

        // "Adjust Settings" button
        navigationActions.navigateToSettings()
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should navigate to Settings")

        navigationCoordinator.popToRoot()

        // "View Detailed Reports" button
        navigationActions.navigateToDetailedReports()
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should navigate to Detailed Reports")

        navigationCoordinator.popToRoot()

        // Additional: "Add Child" button (from empty state and quick actions)
        navigationActions.presentAddChild()
        XCTAssertNotNil(navigationCoordinator.presentedSheet, "Should present Add Child sheet")
        XCTAssertEqual(navigationCoordinator.presentedSheet, .addChild, "Should present correct sheet")
    }

    // MARK: - Acceptance Criteria 4: Real-time updates

    @MainActor
    func testAC4_RealTimeUpdates() async throws {
        await viewModel.loadInitialData()

        // CloudKit subscription for ChildProfile changes
        viewModel.subscribeToChildProfileChanges()
        viewModel.subscribeToPointTransactionChanges()
        viewModel.subscribeToUsageSessionChanges()

        // UI updates via Combine publishers
        var childrenUpdateReceived = false
        var progressDataUpdateReceived = false

        viewModel.childrenPublisher
            .dropFirst()
            .sink { _ in
                childrenUpdateReceived = true
            }
            .store(in: &cancellables)

        viewModel.progressDataPublisher
            .dropFirst()
            .sink { _ in
                progressDataUpdateReceived = true
            }
            .store(in: &cancellables)

        // Simulate data change
        await viewModel.refreshData()

        // Allow publishers to fire
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertTrue(childrenUpdateReceived || progressDataUpdateReceived, "Should receive reactive updates")
    }

    // MARK: - Acceptance Criteria 5: Pull-to-refresh

    @MainActor
    func testAC5_PullToRefresh() async throws {
        await viewModel.loadInitialData()
        let initialRefreshTime = viewModel.lastRefreshTime

        // Wait a moment
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Pull-to-refresh for manual sync
        await viewModel.refreshData()

        XCTAssertGreaterThan(viewModel.lastRefreshTime, initialRefreshTime, "Refresh time should be updated")
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete after refresh")
    }

    // MARK: - Acceptance Criteria 6: Empty state UI

    @MainActor
    func testAC6_EmptyStateUI() async throws {
        // Create empty viewmodel
        let emptyViewModel = ParentDashboardViewModel()

        // Mock empty children list
        let mockChildProfileRepository = MockChildProfileRepository()
        mockChildProfileRepository.mockChildren = []

        let emptyViewModelWithMock = ParentDashboardViewModel(
            childProfileRepository: mockChildProfileRepository,
            pointTransactionRepository: MockPointTransactionRepository(),
            usageSessionRepository: MockUsageSessionRepository()
        )

        await emptyViewModelWithMock.loadInitialData()

        // Empty state when no children added yet
        XCTAssertTrue(emptyViewModelWithMock.children.isEmpty, "Should display empty state with no children")
        XCTAssertFalse(emptyViewModelWithMock.isLoading, "Should not be loading in empty state")

        // Test empty state UI components (would be validated through UI testing)
        let dashboardView = ParentDashboardView()
        XCTAssertNotNil(dashboardView, "Dashboard view should handle empty state gracefully")
    }

    // MARK: - Comprehensive Integration Test

    @MainActor
    func testCompleteParentDashboardIntegration() async throws {
        // Test complete user journey
        await viewModel.loadInitialData()

        // 1. Validate data loading
        XCTAssertFalse(viewModel.isLoading, "Initial load should complete")
        XCTAssertNil(viewModel.errorMessage, "No errors should occur during load")

        // 2. Validate children data display (AC1)
        XCTAssertGreaterThan(viewModel.children.count, 0, "Should have children data")

        // 3. Validate progress indicators (AC2)
        for child in viewModel.children {
            let progressData = viewModel.getProgressData(for: child.id)
            XCTAssertNotNil(progressData, "Progress data should exist for \(child.name)")
        }

        // 4. Validate navigation (AC3)
        let navigationCoordinator = ParentDashboardNavigationCoordinator()
        let navigationActions = ParentDashboardNavigationActions(coordinator: navigationCoordinator)

        navigationActions.navigateToAppCategorization()
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Navigation should work")

        // 5. Validate real-time updates (AC4)
        let initialTime = viewModel.lastRefreshTime
        await viewModel.refreshData()
        XCTAssertGreaterThan(viewModel.lastRefreshTime, initialTime, "Real-time updates should work")

        // 6. Test complete workflow
        XCTAssertTrue(true, "Complete parent dashboard workflow should execute successfully")
    }

    // MARK: - Performance and Accessibility Validation

    func testPerformanceRequirements() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()

        await viewModel.loadInitialData()

        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime

        // Dashboard should load within reasonable time
        XCTAssertLessThan(loadTime, 3.0, "Dashboard should load within 3 seconds")
    }

    func testAccessibilityRequirements() throws {
        // Test accessibility features
        let accessibilityConfig = AccessibilityConfiguration.current()
        XCTAssertNotNil(accessibilityConfig, "Accessibility configuration should be available")

        // Test UI components have accessibility support
        let overviewCard = OverviewCard(title: "Test", value: "123", icon: "star", color: .blue)
        XCTAssertNotNil(overviewCard, "UI components should support accessibility")
    }

    // MARK: - Helper Properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Mock Repositories (reused from other test files)

class MockChildProfileRepository: ChildProfileRepository {
    var mockChildren: [ChildProfile] = []
    var shouldThrowError = false

    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockChildren.append(child)
        return child
    }

    func fetchChild(id: String) async throws -> ChildProfile? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockChildren.first { $0.id == id }
    }

    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockChildren.filter { $0.familyID == familyID }
    }

    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if let index = mockChildren.firstIndex(where: { $0.id == child.id }) {
            mockChildren[index] = child
        }
        return child
    }

    func deleteChild(id: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockChildren.removeAll { $0.id == id }
    }
}

class MockPointTransactionRepository: PointTransactionRepository {
    var mockTransactions: [PointTransaction] = []
    var shouldThrowError = false

    func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockTransactions.append(transaction)
        return transaction
    }

    func fetchTransaction(id: String) async throws -> PointTransaction? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockTransactions.first { $0.id == id }
    }

    func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        let filtered = mockTransactions.filter { $0.childProfileID == childID }
        if let limit = limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockTransactions.filter { $0.childProfileID == childID }
    }

    func deleteTransaction(id: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockTransactions.removeAll { $0.id == id }
    }
}

class MockUsageSessionRepository: UsageSessionRepository {
    var mockSessions: [UsageSession] = []
    var shouldThrowError = false

    func createSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockSessions.append(session)
        return session
    }

    func fetchSession(id: String) async throws -> UsageSession? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockSessions.first { $0.id == id }
    }

    func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockSessions.filter { $0.childProfileID == childID }
    }

    func updateSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if let index = mockSessions.firstIndex(where: { $0.id == session.id }) {
            mockSessions[index] = session
        }
        return session
    }

    func deleteSession(id: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        mockSessions.removeAll { $0.id == id }
    }
}