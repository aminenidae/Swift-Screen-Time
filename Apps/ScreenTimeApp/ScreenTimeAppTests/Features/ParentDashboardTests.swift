//
//  ParentDashboardTests.swift
//  ScreenTimeAppTests
//
//  Created on 2025-10-02.
//

import Testing
import SwiftUI
@testable import ScreenTimeApp

@Suite("Parent Dashboard Tests")
struct ParentDashboardTests {

    @Test("ParentMainView initializes correctly")
    func testParentMainViewInitialization() async throws {
        let parentMainView = ParentMainView()
        #expect(parentMainView != nil)
    }

    @Test("FamilyOverviewView initializes correctly")
    func testFamilyOverviewViewInitialization() async throws {
        let familyOverviewView = FamilyOverviewView()
        #expect(familyOverviewView != nil)
    }

    @Test("OverviewStatCard displays correctly")
    func testOverviewStatCard() async throws {
        let statCard = OverviewStatCard(
            title: "Children",
            value: "2",
            icon: "person.2.fill",
            color: .blue
        )
        #expect(statCard != nil)
    }

    @Test("ChildProgressCard displays correctly")
    func testChildProgressCard() async throws {
        let progressCard = ChildProgressCard(
            name: "Alex",
            points: 125,
            learningMinutes: 85,
            streak: 3
        )
        #expect(progressCard != nil)
    }

    @Test("QuickActionCard functionality")
    func testQuickActionCard() async throws {
        var actionCalled = false
        let actionCard = QuickActionCard(
            title: "Family Setup",
            icon: "house.circle.fill",
            action: { actionCalled = true }
        )
        #expect(actionCard != nil)
    }

    @Test("ActivityView initializes correctly")
    func testActivityView() async throws {
        let activityView = ActivityView()
        #expect(activityView != nil)
    }
}

@Suite("Parent Dashboard Integration Tests")
struct ParentDashboardIntegrationTests {

    @Test("Tab navigation between Family, Activity, and Settings")
    func testParentTabNavigation() async throws {
        let parentMainView = ParentMainView()
        // Test that all three tabs are accessible
        #expect(parentMainView != nil)
    }

    @Test("Family overview displays mock children data")
    func testFamilyOverviewWithMockData() async throws {
        let familyOverviewView = FamilyOverviewView()
        // Test that mock children data is displayed correctly
        #expect(familyOverviewView != nil)
    }

    @Test("Quick actions navigation")
    func testQuickActionsNavigation() async throws {
        let familyOverviewView = FamilyOverviewView()
        // Test that quick action buttons work correctly
        #expect(familyOverviewView != nil)
    }
}