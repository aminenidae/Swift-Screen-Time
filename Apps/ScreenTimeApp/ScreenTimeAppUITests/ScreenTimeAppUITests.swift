//
//  ScreenTimeAppUITests.swift
//  ScreenTimeAppUITests
//
//  Created by Amine Nidae on 2025-09-25.
//

import XCTest

final class ScreenTimeAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Test onboarding flow
        let parentButton = app.buttons["I'm a Parent"]
        let childButton = app.buttons["I'm a Child"]

        // Check that onboarding buttons exist
        XCTAssertTrue(parentButton.waitForExistence(timeout: 5))
        XCTAssertTrue(childButton.waitForExistence(timeout: 5))

        // Test parent role selection
        parentButton.tap()

        // After parent selection, should navigate to main parent interface
        // Add assertions for parent interface elements
    }

    @MainActor
    func testChildDashboardFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Select child role
        let childButton = app.buttons["I'm a Child"]
        XCTAssertTrue(childButton.waitForExistence(timeout: 5))
        childButton.tap()

        // Verify child dashboard elements appear
        let dashboardTab = app.buttons["Dashboard"]
        let rewardsTab = app.buttons["Rewards"]
        let profileTab = app.buttons["Profile"]

        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5))
        XCTAssertTrue(rewardsTab.waitForExistence(timeout: 5))
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))

        // Test tab navigation
        rewardsTab.tap()
        profileTab.tap()
        dashboardTab.tap()
    }

    @MainActor
    func testParentDashboardFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Select parent role
        let parentButton = app.buttons["I'm a Parent"]
        XCTAssertTrue(parentButton.waitForExistence(timeout: 5))
        parentButton.tap()

        // Verify parent dashboard tabs
        let familyTab = app.buttons["Family"]
        let activityTab = app.buttons["Activity"]
        let settingsTab = app.buttons["Settings"]

        XCTAssertTrue(familyTab.waitForExistence(timeout: 5))
        XCTAssertTrue(activityTab.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))

        // Test tab navigation
        activityTab.tap()
        settingsTab.tap()
        familyTab.tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
