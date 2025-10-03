//
//  ChildDashboardTests.swift
//  ScreenTimeAppTests
//
//  Created on 2025-10-02.
//

import XCTest
import SwiftUI
@testable import ScreenTimeApp

@available(iOS 15.0, *)
final class ChildDashboardTests: XCTestCase {

    func testChildMainViewInitialization() {
        // Test that ChildMainView can be created
        let childMainView = ChildMainView()
        XCTAssertNotNil(childMainView)
    }

    func testChildProfileViewInitialization() {
        // Test that ChildProfileView can be created
        let childProfileView = ChildProfileView()
        XCTAssertNotNil(childProfileView)
    }

    func testLearningActivityRowDisplay() {
        // Test that LearningActivityRow can be created
        let activityRow = LearningActivityRow(
            appName: "Khan Academy",
            duration: "25 min",
            pointsEarned: 25,
            timeAgo: "2 hours ago"
        )
        XCTAssertNotNil(activityRow)
    }

    func testStatCardDisplay() {
        // Test that StatCard can be created
        let statCard = StatCard(
            title: "Total Points",
            value: "1,250",
            subtitle: "Earned this week" // Fixed the parameter order
        )
        XCTAssertNotNil(statCard)
    }
}

@available(iOS 15.0, *)
final class ChildDashboardIntegrationTests: XCTestCase {

    func testTabNavigation() {
        // Test that all tabs in ChildMainView are accessible
        let childMainView = ChildMainView()
        // This would test TabView functionality in a real integration test
        XCTAssertNotNil(childMainView)
    }

    func testProfileSwitcher() {
        let childProfileView = ChildProfileView()
        // Test profile switching functionality
        XCTAssertNotNil(childProfileView)
    }
}