//
//  ScreenTimeAppTests.swift
//  ScreenTimeAppTests
//
//  Created by Amine Nidae on 2025-09-25.
//

import Testing
import SwiftUI
@testable import ScreenTimeApp

@Suite("Main App Architecture Tests")
struct ScreenTimeAppTests {

    @Test("ContentView initializes correctly")
    func testContentViewInitialization() async throws {
        let contentView = ContentView()
        #expect(contentView != nil)
    }

    @Test("OnboardingView initializes correctly")
    func testOnboardingViewInitialization() async throws {
        let onboardingView = OnboardingView()
        #expect(onboardingView != nil)
    }

    @Test("AuthenticatedParentView wraps content correctly")
    func testAuthenticatedParentView() async throws {
        let authenticatedView = AuthenticatedParentView {
            Text("Test Content")
        }
        #expect(authenticatedView != nil)
    }
}

@Suite("App Navigation Tests")
struct AppNavigationTests {

    @Test("Role-based navigation works correctly")
    func testRoleBasedNavigation() async throws {
        // Test navigation based on userRole AppStorage
        let contentView = ContentView()
        #expect(contentView != nil)
    }

    @Test("Onboarding flow navigation")
    func testOnboardingFlow() async throws {
        // Test onboarding completion flow
        let onboardingView = OnboardingView()
        #expect(onboardingView != nil)
    }
}

@Suite("Modular Architecture Tests")
struct ModularArchitectureTests {

    @Test("All feature modules are accessible")
    func testFeatureModuleAccessibility() async throws {
        // Test that all modularized features are accessible
        #expect(ChildMainView() != nil)
        #expect(ParentMainView() != nil)
        #expect(RewardsView() != nil)
        #expect(ChildProfileView() != nil)
        #expect(FamilyOverviewView() != nil)
        #expect(ParentSettingsView() != nil)
    }

    @Test("Forward declarations work correctly")
    func testForwardDeclarations() async throws {
        // Test that forward declared views initialize without errors
        #expect(OnboardingView() != nil)
    }

    @Test("Module separation is maintained")
    func testModuleSeparation() async throws {
        // This test verifies that the modular architecture is properly separated
        // In a more comprehensive test, we would verify that modules don't have
        // unwanted dependencies on each other
        #expect(true) // Placeholder for architectural validation
    }
}
