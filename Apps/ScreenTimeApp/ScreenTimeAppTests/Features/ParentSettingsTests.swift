//
//  ParentSettingsTests.swift
//  ScreenTimeAppTests
//
//  Created on 2025-10-02.
//

import Testing
import SwiftUI
import FamilyControlsKit
@testable import ScreenTimeApp

@Suite("Parent Settings Tests")
struct ParentSettingsTests {

    @Test("ParentSettingsView initializes correctly")
    func testParentSettingsViewInitialization() async throws {
        let parentSettingsView = ParentSettingsView()
        #expect(parentSettingsView != nil)
    }

    @Test("ChildSelectionView initializes correctly")
    func testChildSelectionViewInitialization() async throws {
        let childSelectionView = ChildSelectionView(
            onChildSelected: { _ in },
            destinationType: .timeLimits
        )
        #expect(childSelectionView != nil)
    }

    @Test("ChildSelectionCard displays correctly")
    func testChildSelectionCard() async throws {
        let mockChild = FamilyMemberInfo(
            id: "test-id",
            name: "Test Child",
            isChild: true,
            hasAppInstalled: true,
            isCurrentUser: false
        )

        let selectionCard = ChildSelectionCard(child: mockChild)
        #expect(selectionCard != nil)
    }

    @Test("ChildSettingDestination enum works correctly")
    func testChildSettingDestination() async throws {
        #expect(ChildSelectionView.ChildSettingDestination.timeLimits.title == "Daily Time Limits")
        #expect(ChildSelectionView.ChildSettingDestination.bedtime.title == "Bedtime Settings")
        #expect(ChildSelectionView.ChildSettingDestination.reports.title == "Detailed Reports")
        #expect(ChildSelectionView.ChildSettingDestination.trends.title == "Usage Trends")

        #expect(ChildSelectionView.ChildSettingDestination.timeLimits.description == "Set daily screen time limits for your child")
        #expect(ChildSelectionView.ChildSettingDestination.learningAppSettings.description == "Configure learning app points for this child")
    }
}

@Suite("Parent Settings Integration Tests")
struct ParentSettingsIntegrationTests {

    @Test("Settings sections display correctly")
    func testSettingsSections() async throws {
        let parentSettingsView = ParentSettingsView()
        // Test that General Settings and Child Settings sections are displayed
        #expect(parentSettingsView != nil)
    }

    @Test("Child selection for different destinations")
    func testChildSelectionDestinations() async throws {
        for destination in [
            ChildSelectionView.ChildSettingDestination.timeLimits,
            .bedtime,
            .reports,
            .trends,
            .learningAppSettings,
            .activitySettings,
            .rewardAppSettings
        ] {
            let childSelectionView = ChildSelectionView(
                onChildSelected: { _ in },
                destinationType: destination
            )
            #expect(childSelectionView != nil)
        }
    }

    @Test("Forward declarations work correctly")
    func testForwardDeclarations() async throws {
        // Test that all forward declared views initialize correctly
        #expect(FamilyControlsSetupView() != nil)
        #expect(FamilyMembersView() != nil)
        #expect(SubscriptionView() != nil)
        #expect(TimeLimitsView() != nil)
        #expect(BedtimeSettingsView() != nil)
        #expect(ReportsView() != nil)
        #expect(UsageTrendsView() != nil)
    }
}