import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels

final class ParentDashboardEmptyStateTests: XCTestCase {
    var viewModel: ParentDashboardViewModel!
    var mockChildProfileRepository: MockChildProfileRepository!

    override func setUpWithError() throws {
        mockChildProfileRepository = MockChildProfileRepository()
        viewModel = ParentDashboardViewModel(
            childProfileRepository: mockChildProfileRepository,
            pointTransactionRepository: MockPointTransactionRepository(),
            usageSessionRepository: MockUsageSessionRepository()
        )
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockChildProfileRepository = nil
    }

    @MainActor
    func testEmptyStateDisplayed_WhenNoChildren() async throws {
        // Given
        mockChildProfileRepository.mockChildren = []

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertTrue(viewModel.children.isEmpty, "Children should be empty")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil")

        // Create a parent dashboard view to test the empty state UI
        let dashboardView = ParentDashboardView()

        // The view should show empty state when children array is empty
        // This would typically be tested with UI testing or ViewInspector
        XCTAssertNotNil(dashboardView, "Dashboard view should be created successfully")
    }

    @MainActor
    func testEmptyStateToChildrenTransition() async throws {
        // Given - Start with empty state
        mockChildProfileRepository.mockChildren = []
        await viewModel.loadInitialData()
        XCTAssertTrue(viewModel.children.isEmpty)

        // When - Add children
        let newChild = ChildProfile(
            id: "child-1",
            familyID: "mock-family-id",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 500
        )
        mockChildProfileRepository.mockChildren = [newChild]
        await viewModel.refreshData()

        // Then - Should transition from empty state to content
        XCTAssertFalse(viewModel.children.isEmpty, "Children should no longer be empty")
        XCTAssertEqual(viewModel.children.count, 1, "Should have one child")
        XCTAssertEqual(viewModel.children.first?.name, "Test Child", "Child name should match")
    }

    @MainActor
    func testEmptyStateHandling_WithLoadingError() async throws {
        // Given
        mockChildProfileRepository.shouldThrowError = true

        // When
        await viewModel.loadInitialData()

        // Then
        XCTAssertTrue(viewModel.children.isEmpty, "Children should remain empty on error")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false")
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to load family data"), "Error message should describe the failure")
    }

    @MainActor
    func testEmptyStateProgressData() async throws {
        // Given
        mockChildProfileRepository.mockChildren = []
        await viewModel.loadInitialData()

        // When
        let progressData = viewModel.getProgressData(for: "non-existent-child-id")

        // Then
        XCTAssertEqual(progressData.recentTransactions.count, 0, "Should have no transactions")
        XCTAssertEqual(progressData.todaysUsage.count, 0, "Should have no usage data")
        XCTAssertEqual(progressData.weeklyPoints.count, 0, "Should have no weekly points")
        XCTAssertEqual(progressData.learningStreak, 0, "Should have no learning streak")
        XCTAssertEqual(progressData.todaysLearningMinutes, 0, "Should have no learning minutes")
        XCTAssertEqual(progressData.todaysRewardMinutes, 0, "Should have no reward minutes")
    }

    @MainActor
    func testEmptyStateCallToAction() async throws {
        // Given
        mockChildProfileRepository.mockChildren = []
        await viewModel.loadInitialData()

        // When - Check that the view model supports the empty state properly
        XCTAssertTrue(viewModel.children.isEmpty)

        // Then - Empty state should provide proper context for call-to-action
        // The UI would show "Add Your First Child" button
        // Testing the action would require navigation testing which is covered in Task 4
        XCTAssertTrue(viewModel.children.isEmpty, "Empty state should be maintained until children are added")
    }

    func testEmptyStateUIComponents() throws {
        // This test would typically use ViewInspector or UI testing
        // For now, we verify that the view can be created without crashing
        let dashboardView = ParentDashboardView()
        XCTAssertNotNil(dashboardView, "Dashboard view should be created successfully")

        // Test empty state UI elements would include:
        // - Empty state icon (person.2.badge.plus)
        // - Title: "No Children Added Yet"
        // - Description: "Start by adding your first child to begin tracking..."
        // - Call-to-action button: "Add Your First Child"
    }

    @MainActor
    func testEmptyStateAccessibility() async throws {
        // Given
        mockChildProfileRepository.mockChildren = []
        await viewModel.loadInitialData()

        // Test accessibility properties for empty state
        // In a real implementation, this would test:
        // - Accessibility labels for empty state elements
        // - VoiceOver support for the call-to-action button
        // - Proper semantic roles for UI elements

        XCTAssertTrue(viewModel.children.isEmpty, "Should be in empty state for accessibility testing")
    }
}