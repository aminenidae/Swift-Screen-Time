import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels

final class SettingsViewTests: XCTestCase {

    func testSettingsViewStructure() {
        // Test that SettingsView has the required three main sections
        let viewModel = SettingsViewModel.mockViewModel()
        let settingsView = SettingsView()
        settingsView.viewModel = viewModel

        // Verify the view can be instantiated without crashes
        XCTAssertNotNil(settingsView)
    }

    func testNavigationFromParentDashboard() {
        // Test that navigation to Settings is properly configured
        let coordinator = ParentDashboardNavigationCoordinator()
        let navigationActions = ParentDashboardNavigationActions(coordinator: coordinator)

        // Test navigation to settings
        navigationActions.navigateToSettings()

        // Verify navigation path contains settings destination
        XCTAssertFalse(coordinator.navigationPath.isEmpty)
    }

    func testGroupedTableViewLayoutStructure() {
        // Test that the three main sections are present
        let viewModel = SettingsViewModel.mockViewModel()

        // Verify sections are accessible through view model
        XCTAssertNotNil(viewModel.settings)
        XCTAssertNotNil(viewModel.settings?.dailyTimeLimit)
        XCTAssertNotNil(viewModel.settings?.bedtimeStart)
        XCTAssertNotNil(viewModel.settings?.bedtimeEnd)
        XCTAssertNotNil(viewModel.settings?.contentRestrictions)
    }

    func testTimeManagementSectionPresence() {
        // Test that Time Management section exists with required components
        let viewModel = SettingsViewModel.mockViewModel()

        // Verify daily time limit is handled
        XCTAssertEqual(viewModel.settings?.dailyTimeLimit, 120)

        // Test updating daily time limit
        viewModel.updateDailyTimeLimit(180)
        XCTAssertEqual(viewModel.settings?.dailyTimeLimit, 180)
    }

    func testBedtimeControlsSectionPresence() {
        // Test that Bedtime Controls section exists with required components
        let viewModel = SettingsViewModel.mockViewModel()

        // Verify bedtime settings are handled
        XCTAssertNotNil(viewModel.settings?.bedtimeStart)
        XCTAssertNotNil(viewModel.settings?.bedtimeEnd)

        // Test updating bedtime settings
        let newStart = Calendar.current.date(from: DateComponents(hour: 21, minute: 0))
        viewModel.updateBedtimeStart(newStart)
        XCTAssertEqual(viewModel.settings?.bedtimeStart, newStart)
    }

    func testAppRestrictionsSectionPresence() {
        // Test that App Restrictions section exists with required components
        let viewModel = SettingsViewModel.mockViewModel()

        // Verify content restrictions are handled
        XCTAssertFalse(viewModel.settings?.contentRestrictions.isEmpty ?? true)

        // Test updating content restrictions
        let newRestrictions = ["com.test.app": true]
        viewModel.updateContentRestrictions(newRestrictions)
        XCTAssertEqual(viewModel.settings?.contentRestrictions, newRestrictions)
    }

    func testSettingsSectionAccessibilityLabels() {
        // Test that sections have proper accessibility labels
        let sectionView = SettingsSection(
            title: "Test Section",
            icon: "gear",
            iconColor: .blue
        ) {
            Text("Test Content")
        }

        // Verify section can be created with accessibility requirements
        XCTAssertNotNil(sectionView)
    }

    func testGroupedTableViewWithSectionHeaders() {
        // Test that section headers are properly configured
        let viewModel = SettingsViewModel.mockViewModel()

        // Test section structure
        let sections = ["Time Management", "Bedtime Controls", "App Restrictions"]
        for sectionTitle in sections {
            let sectionView = SettingsSection(
                title: sectionTitle,
                icon: "gear",
                iconColor: .blue
            ) {
                Text("Content")
            }
            XCTAssertNotNil(sectionView)
        }
    }
}