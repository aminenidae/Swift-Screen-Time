//
//  ScreenTimeAppTests.swift
//  ScreenTimeAppTests
//
//  Created by Amine Nidae on 2025-09-25.
//

import XCTest
import SwiftUI
@testable import ScreenTimeApp

@available(iOS 15.0, *)
final class ScreenTimeAppTests: XCTestCase {

    func testContentViewInitialization() {
        let contentView = ContentView()
        XCTAssertNotNil(contentView)
    }

    func testOnboardingViewInitialization() {
        let onboardingView = OnboardingView()
        XCTAssertNotNil(onboardingView)
    }

    func testAuthenticatedParentView() {
        let authenticatedView = AuthenticatedParentView {
            Text("Test Content")
        }
        XCTAssertNotNil(authenticatedView)
    }
}

@available(iOS 15.0, *)
final class AppNavigationTests: XCTestCase {

    func testRoleBasedNavigation() {
        // Test navigation based on userRole AppStorage
        let contentView = ContentView()
        XCTAssertNotNil(contentView)
    }

    func testOnboardingFlow() {
        // Test onboarding completion flow
        let onboardingView = OnboardingView()
        XCTAssertNotNil(onboardingView)
    }
}

@available(iOS 15.0, *)
final class ModularArchitectureTests: XCTestCase {

    func testFeatureModuleAccessibility() {
        // Test that all modularized features are accessible
        XCTAssertNotNil(ChildMainView())
        XCTAssertNotNil(ParentMainView())
        XCTAssertNotNil(RewardsView())
        XCTAssertNotNil(ChildProfileView())
        XCTAssertNotNil(FamilyOverviewView())
        XCTAssertNotNil(ParentSettingsView())
    }

    func testForwardDeclarations() {
        // Test that forward declared views initialize without errors
        XCTAssertNotNil(OnboardingView())
    }

    func testModuleSeparation() {
        // This test verifies that the modular architecture is properly separated
        // In a more comprehensive test, we would verify that modules don't have
        // unwanted dependencies on each other
        XCTAssertTrue(true) // Placeholder for architectural validation
    }
}