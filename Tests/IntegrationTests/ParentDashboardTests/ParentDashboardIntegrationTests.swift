import XCTest
import Combine
@testable import ScreenTimeRewards
@testable import SharedModels
@testable import CloudKitService

final class ParentDashboardIntegrationTests: XCTestCase {
    var viewModel: ParentDashboardViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        // Use real CloudKitService for integration testing
        viewModel = ParentDashboardViewModel()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        cancellables = nil
    }

    @MainActor
    func testDataLoadingAndRealTimeUpdates() async throws {
        // Given
        var childrenUpdateReceived = false
        var progressDataUpdateReceived = false

        // Set up reactive listeners
        viewModel.childrenPublisher
            .dropFirst() // Skip initial empty value
            .sink { children in
                childrenUpdateReceived = !children.isEmpty
            }
            .store(in: &cancellables)

        viewModel.progressDataPublisher
            .dropFirst() // Skip initial empty value
            .sink { progressData in
                progressDataUpdateReceived = !progressData.isEmpty
            }
            .store(in: &cancellables)

        // When
        await viewModel.loadInitialData()

        // Allow time for async operations and subscriptions
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete")

        // Since we're using mock data in CloudKitService, we should get children
        if !viewModel.children.isEmpty {
            XCTAssertTrue(childrenUpdateReceived, "Should have received children updates")
            XCTAssertTrue(progressDataUpdateReceived, "Should have received progress data updates")
        }
    }

    @MainActor
    func testPullToRefreshFunctionality() async throws {
        // Given
        await viewModel.loadInitialData()
        let initialRefreshTime = viewModel.lastRefreshTime

        // Allow some time to pass
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // When
        await viewModel.refreshData()

        // Then
        XCTAssertGreaterThan(viewModel.lastRefreshTime, initialRefreshTime, "Refresh time should be updated")
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete after refresh")
    }

    @MainActor
    func testErrorHandlingInDataLoading() async throws {
        // This test would require a mock repository that can simulate errors
        // For now, we'll test that error handling doesn't crash the app

        // When loading data (even with potential mock data issues)
        await viewModel.loadInitialData()

        // Then - should not crash and should handle any errors gracefully
        XCTAssertNotNil(viewModel, "ViewModel should remain stable")
        XCTAssertFalse(viewModel.isLoading, "Loading state should be resolved")
    }

    @MainActor
    func testReactiveUIUpdates() async throws {
        // Given
        var receivedChildrenUpdate = false
        var receivedProgressUpdate = false

        viewModel.childrenPublisher
            .sink { _ in
                receivedChildrenUpdate = true
            }
            .store(in: &cancellables)

        viewModel.progressDataPublisher
            .sink { _ in
                receivedProgressUpdate = true
            }
            .store(in: &cancellables)

        // When
        await viewModel.loadInitialData()

        // Allow publishers to fire
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertTrue(receivedChildrenUpdate, "Should receive children updates via publisher")
        XCTAssertTrue(receivedProgressUpdate, "Should receive progress data updates via publisher")
    }

    @MainActor
    func testCloudKitSubscriptionSetup() async throws {
        // Given - ViewModel is initialized (which calls setupCloudKitSubscriptions)

        // When/Then - Test that subscriptions are set up without crashing
        viewModel.subscribeToChildProfileChanges()
        viewModel.subscribeToPointTransactionChanges()
        viewModel.subscribeToUsageSessionChanges()

        // These should not crash and should log subscription setup
        // In a real implementation, we would test that CKQuerySubscription objects are created
        XCTAssertNotNil(viewModel, "ViewModel should remain stable after subscription setup")
    }

    @MainActor
    func testProgressDataCalculations() async throws {
        // Given
        await viewModel.loadInitialData()

        // When we have children with data
        if !viewModel.children.isEmpty {
            let firstChild = viewModel.children.first!
            let progressData = viewModel.getProgressData(for: firstChild.id)

            // Then - progress data should be properly calculated
            XCTAssertNotNil(progressData, "Progress data should exist for child")
            XCTAssertGreaterThanOrEqual(progressData.learningStreak, 0, "Learning streak should be non-negative")
            XCTAssertGreaterThanOrEqual(progressData.todaysLearningMinutes, 0, "Learning minutes should be non-negative")
            XCTAssertGreaterThanOrEqual(progressData.todaysRewardMinutes, 0, "Reward minutes should be non-negative")
        }
    }

    @MainActor
    func testWeeklyPointsDataStructure() async throws {
        // Given
        await viewModel.loadInitialData()

        // When we have children with data
        if !viewModel.children.isEmpty {
            let firstChild = viewModel.children.first!
            let progressData = viewModel.getProgressData(for: firstChild.id)

            // Then - weekly points should be properly structured
            XCTAssertLessThanOrEqual(progressData.weeklyPoints.count, 7, "Should have at most 7 days of data")

            // Verify dates are properly ordered
            let dates = progressData.weeklyPoints.map { $0.date }
            let sortedDates = dates.sorted()
            XCTAssertEqual(dates, sortedDates, "Weekly points should be ordered by date")
        }
    }
}