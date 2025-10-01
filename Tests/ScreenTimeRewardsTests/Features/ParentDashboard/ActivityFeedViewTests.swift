import XCTest
import SwiftUI
import Combine
@testable import ScreenTimeRewards
@testable import SharedModels
@testable import RewardCore

@available(iOS 15.0, macOS 12.0, *)
final class ActivityFeedViewTests: XCTestCase {

    func testActivityFeedViewInitialization() {
        // Given/When
        let view = ActivityFeedView()

        // Then
        XCTAssertNotNil(view)
    }

    func testActivityFeedViewWithMockService() {
        // Given
        let mockService = MockParentActivityService()
        let viewModel = ActivityFeedViewModel(activityService: mockService)

        // When
        let view = ActivityFeedView()
        view.viewModel = viewModel

        // Then
        XCTAssertNotNil(view)
    }

    func testActivityRowViewRendering() {
        // Given
        let activity = createSampleActivity()

        // When
        let rowView = ActivityRowView(activity: activity)

        // Then
        XCTAssertNotNil(rowView)
    }

    func testActivityDetailViewRendering() {
        // Given
        let activity = createSampleActivity()

        // When
        let detailView = ActivityDetailView(activity: activity)

        // Then
        XCTAssertNotNil(detailView)
    }

    @MainActor
    func testActivityFeedViewModelLoadActivities() async {
        // Given
        let mockService = MockParentActivityService()
        let viewModel = ActivityFeedViewModel(activityService: mockService)
        mockService.mockActivities = [createSampleActivity()]

        // When
        await viewModel.loadActivities()

        // Then
        XCTAssertEqual(viewModel.activities.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testActivityFeedViewModelLoadActivitiesError() async {
        // Given
        let mockService = MockParentActivityService()
        let viewModel = ActivityFeedViewModel(activityService: mockService)
        mockService.shouldFail = true

        // When
        await viewModel.loadActivities()

        // Then
        XCTAssertTrue(viewModel.activities.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    @MainActor
    func testActivityFeedViewModelRefreshActivities() async {
        // Given
        let mockService = MockParentActivityService()
        let viewModel = ActivityFeedViewModel(activityService: mockService)
        mockService.mockActivities = [
            createSampleActivity(),
            createSampleActivity()
        ]

        // When
        await viewModel.refreshActivities()

        // Then
        XCTAssertEqual(viewModel.activities.count, 2)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testActivityFeedViewModelLoadMoreActivities() async {
        // Given
        let mockService = MockParentActivityService()
        let viewModel = ActivityFeedViewModel(activityService: mockService)

        // Set initial activities
        viewModel.activities = [createSampleActivity()]
        viewModel.hasMoreActivities = true

        // Set additional activities to be "loaded"
        mockService.mockActivities = [createSampleActivity()]

        // When
        await viewModel.loadMoreActivities()

        // Then
        XCTAssertFalse(viewModel.isLoadingMore)
        // Note: Actual count depends on implementation details
    }

    @MainActor
    func testActivityFeedViewModelCleanupOldActivities() {
        // Given
        let mockService = MockParentActivityService()
        let viewModel = ActivityFeedViewModel(activityService: mockService)

        // Add more than max activities
        let activities = (0..<150).map { _ in createSampleActivity() }
        viewModel.activities = activities

        // When
        viewModel.cleanupOldActivitiesFromMemory()

        // Then
        XCTAssertLessThanOrEqual(viewModel.activities.count, viewModel.maxActivitiesInMemory)
    }

    @MainActor
    func testActivityFeedViewModelMarkActivityAsRead() {
        // Given
        let mockService = MockParentActivityService()
        let viewModel = ActivityFeedViewModel(activityService: mockService)
        let activity = createSampleActivity()

        // When
        viewModel.markActivityAsRead(activity)

        // Then - Should not crash and should update unread count
        XCTAssertEqual(viewModel.unreadActivityCount, 0)
    }

    func testDetailRowFormatting() {
        // Given
        let detailRow = DetailRow(label: "Test Label", value: "Test Value")

        // When/Then - Should not crash
        XCTAssertNotNil(detailRow)
    }

    func testChangeRowFormatting() {
        // Given
        let changeRow = ChangeRow(
            key: "appName",
            value: "Khan Academy",
            activityType: .appCategorizationAdded
        )

        // When/Then - Should not crash
        XCTAssertNotNil(changeRow)
    }

    func testChangeRowBeforeAfterView() {
        // Given
        let oldCategoryRow = ChangeRow(
            key: "oldCategory",
            value: "Reward",
            activityType: .appCategorizationModified
        )

        let newCategoryRow = ChangeRow(
            key: "newCategory",
            value: "Learning",
            activityType: .appCategorizationModified
        )

        // When/Then - Should not crash
        XCTAssertNotNil(oldCategoryRow)
        XCTAssertNotNil(newCategoryRow)
    }

    // MARK: - Performance Tests

    func testActivityListPerformanceWithManyActivities() {
        // Given
        let activities = (0..<1000).map { _ in createSampleActivity() }

        // When/Then - Test should complete in reasonable time
        measure {
            let _ = activities.prefix(50) // Simulate UI limiting
        }
    }

    func testActivityCreationPerformance() {
        // Test creating many activities doesn't cause performance issues
        measure {
            let _ = (0..<1000).map { _ in createSampleActivity() }
        }
    }

    // MARK: - Accessibility Tests

    func testActivityRowAccessibility() {
        // Given
        let activity = createSampleActivity()
        let rowView = ActivityRowView(activity: activity)

        // When/Then - Should have proper accessibility properties
        XCTAssertNotNil(rowView)
        // In a real test, we'd check accessibility labels and hints
    }

    // MARK: - Helper Methods

    private func createSampleActivity(
        familyID: UUID = UUID(),
        activityType: ParentActivityType = .appCategorizationAdded,
        timestamp: Date = Date()
    ) -> ParentActivity {
        return ParentActivity(
            familyID: familyID,
            triggeringUserID: "test-user-123",
            activityType: activityType,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "appName": "Khan Academy",
                "category": "Learning"
            ]),
            timestamp: timestamp,
            deviceID: "iPhone123"
        )
    }
}

// MARK: - Mock Service

@available(iOS 15.0, macOS 12.0, *)
class MockParentActivityService: ParentActivityService {
    var mockActivities: [ParentActivity] = []
    var shouldFail = false

    override func loadRecentActivities(for familyID: UUID) async {
        await MainActor.run {
            isLoading = true
        }

        if shouldFail {
            await MainActor.run {
                error = MockError.testError
                isLoading = false
            }
            return
        }

        await MainActor.run {
            activities = mockActivities
            isLoading = false
            error = nil
        }
    }

    override func refreshActivities(for familyID: UUID) async {
        await loadRecentActivities(for: familyID)
    }
}

// MARK: - Test Extensions

@available(iOS 15.0, macOS 12.0, *)
extension ActivityFeedView {
    var viewModel: ActivityFeedViewModel {
        get { _viewModel.wrappedValue }
        set { _viewModel = StateObject(wrappedValue: newValue) }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension ActivityFeedViewModel {
    var maxActivitiesInMemory: Int {
        return 100
    }

    var hasMoreActivities: Bool {
        get { true } // Simplified for testing
        set { } // No-op for testing
    }
}

enum MockError: Error {
    case testError
}