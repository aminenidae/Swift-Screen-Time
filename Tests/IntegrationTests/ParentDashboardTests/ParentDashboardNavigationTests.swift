import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels

final class ParentDashboardNavigationTests: XCTestCase {
    var navigationCoordinator: ParentDashboardNavigationCoordinator!
    var navigationActions: ParentDashboardNavigationActions!

    @MainActor
    override func setUpWithError() throws {
        navigationCoordinator = ParentDashboardNavigationCoordinator()
        navigationActions = ParentDashboardNavigationActions(coordinator: navigationCoordinator)
    }

    override func tearDownWithError() throws {
        navigationCoordinator = nil
        navigationActions = nil
    }

    @MainActor
    func testNavigationToAppCategorization() throws {
        // Given
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty, "Navigation path should start empty")

        // When
        navigationActions.navigateToAppCategorization()

        // Then
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should have one item in navigation path")
    }

    @MainActor
    func testNavigationToSettings() throws {
        // Given
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty)

        // When
        navigationActions.navigateToSettings()

        // Then
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should navigate to settings")
    }

    @MainActor
    func testNavigationToDetailedReports() throws {
        // Given
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty)

        // When
        navigationActions.navigateToDetailedReports()

        // Then
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should navigate to detailed reports")
    }

    @MainActor
    func testPresentAddChild() throws {
        // Given
        XCTAssertNil(navigationCoordinator.presentedSheet, "No sheet should be presented initially")

        // When
        navigationActions.presentAddChild()

        // Then
        XCTAssertNotNil(navigationCoordinator.presentedSheet, "Sheet should be presented")
        XCTAssertEqual(navigationCoordinator.presentedSheet, .addChild, "Should present add child sheet")
    }

    @MainActor
    func testNavigateToChildDetail() throws {
        // Given
        let childID = "test-child-id"
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty)

        // When
        navigationActions.navigateToChildDetail(childID)

        // Then
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should navigate to child detail")
    }

    @MainActor
    func testDismissSheet() throws {
        // Given
        navigationActions.presentAddChild()
        XCTAssertNotNil(navigationCoordinator.presentedSheet)

        // When
        navigationCoordinator.dismissSheet()

        // Then
        XCTAssertNil(navigationCoordinator.presentedSheet, "Sheet should be dismissed")
    }

    @MainActor
    func testPopToRoot() throws {
        // Given - Navigate to multiple screens
        navigationActions.navigateToAppCategorization()
        navigationActions.navigateToSettings()
        navigationActions.navigateToDetailedReports()
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 3)

        // When
        navigationCoordinator.popToRoot()

        // Then
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty, "Should pop to root")
    }

    @MainActor
    func testPopSingleLevel() throws {
        // Given
        navigationActions.navigateToAppCategorization()
        navigationActions.navigateToSettings()
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 2)

        // When
        navigationCoordinator.pop()

        // Then
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 1, "Should pop one level")
    }

    @MainActor
    func testPopFromEmptyPath() throws {
        // Given
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty)

        // When
        navigationCoordinator.pop()

        // Then
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty, "Should remain empty when popping from empty path")
    }

    @MainActor
    func testMultipleNavigationActions() throws {
        // Given
        XCTAssertTrue(navigationCoordinator.navigationPath.isEmpty)
        XCTAssertNil(navigationCoordinator.presentedSheet)

        // When - Perform multiple navigation actions
        navigationActions.navigateToAppCategorization()
        navigationActions.presentAddChild()
        navigationActions.navigateToSettings()

        // Then
        XCTAssertEqual(navigationCoordinator.navigationPath.count, 2, "Should have 2 pushed views")
        XCTAssertEqual(navigationCoordinator.presentedSheet, .addChild, "Should have add child sheet presented")
    }

    func testNavigationDestinationEquality() throws {
        // Test that navigation destinations can be compared properly
        let destination1: ParentDashboardDestination = .appCategorization
        let destination2: ParentDashboardDestination = .appCategorization
        let destination3: ParentDashboardDestination = .settings

        XCTAssertEqual(destination1, destination2, "Same destinations should be equal")
        XCTAssertNotEqual(destination1, destination3, "Different destinations should not be equal")

        let childDetail1: ParentDashboardDestination = .childDetail(childID: "child-1")
        let childDetail2: ParentDashboardDestination = .childDetail(childID: "child-1")
        let childDetail3: ParentDashboardDestination = .childDetail(childID: "child-2")

        XCTAssertEqual(childDetail1, childDetail2, "Child details with same ID should be equal")
        XCTAssertNotEqual(childDetail1, childDetail3, "Child details with different IDs should not be equal")
    }

    func testPlaceholderViewsCreation() throws {
        // Test that placeholder views can be created without crashing
        let appCategorizationView = AppCategorizationView()
        let settingsView = SettingsView()
        let detailedReportsView = DetailedReportsView()
        let addChildView = AddChildView()
        let childDetailView = ChildDetailView(childID: "test-id")

        XCTAssertNotNil(appCategorizationView, "AppCategorizationView should be created")
        XCTAssertNotNil(settingsView, "SettingsView should be created")
        XCTAssertNotNil(detailedReportsView, "DetailedReportsView should be created")
        XCTAssertNotNil(addChildView, "AddChildView should be created")
        XCTAssertNotNil(childDetailView, "ChildDetailView should be created")
    }
}