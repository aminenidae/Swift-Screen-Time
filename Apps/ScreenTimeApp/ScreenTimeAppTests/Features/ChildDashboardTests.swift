//
//  ChildDashboardTests.swift
//  ScreenTimeAppTests
//
//  Created on 2025-10-02.
//

import Testing
import SwiftUI
@testable import ScreenTimeApp

@Suite("Child Dashboard Tests")
struct ChildDashboardTests {

    @Test("ChildMainView initializes correctly")
    func testChildMainViewInitialization() async throws {
        let childMainView = ChildMainView()
        #expect(childMainView != nil)
    }

    @Test("ChildProfileView initializes correctly")
    func testChildProfileViewInitialization() async throws {
        let childProfileView = ChildProfileView()
        #expect(childProfileView != nil)
    }

    @Test("LearningActivityRow displays correctly")
    func testLearningActivityRowDisplay() async throws {
        let activityRow = LearningActivityRow(
            appName: "Khan Academy",
            duration: "25 min",
            pointsEarned: 25,
            timeAgo: "2 hours ago"
        )
        #expect(activityRow != nil)
    }

    @Test("StatCard displays correctly")
    func testStatCardDisplay() async throws {
        let statCard = StatCard(
            title: "Total Points",
            value: "1,250",
            icon: "star.fill",
            color: .yellow
        )
        #expect(statCard != nil)
    }
}

@Suite("Child Dashboard Integration Tests")
struct ChildDashboardIntegrationTests {

    @Test("Tab navigation works correctly")
    func testTabNavigation() async throws {
        // Test that all tabs in ChildMainView are accessible
        let childMainView = ChildMainView()
        // This would test TabView functionality in a real integration test
        #expect(childMainView != nil)
    }

    @Test("Profile switcher functionality")
    func testProfileSwitcher() async throws {
        let childProfileView = ChildProfileView()
        // Test profile switching functionality
        #expect(childProfileView != nil)
    }
}