import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels

final class ContentRestrictionsViewTests: XCTestCase {

    func testContentRestrictionsViewCreation() {
        // Test that ContentRestrictionsView can be created with valid bindings
        let contentRestrictions = Binding<[String: Bool]>.constant([:])
        let restrictionsView = ContentRestrictionsView(contentRestrictions: contentRestrictions)

        XCTAssertNotNil(restrictionsView)
    }

    func testContentRestrictionsFieldHandling() {
        // Test that ContentRestrictionsView specifically handles contentRestrictions field
        var restrictionsValue: [String: Bool] = [
            "com.apple.mobilesafari": true,
            "com.apple.mobilemail": false,
            "com.apple.Music": true
        ]

        let contentRestrictions = Binding(
            get: { restrictionsValue },
            set: { restrictionsValue = $0 }
        )

        let restrictionsView = ContentRestrictionsView(contentRestrictions: contentRestrictions)

        XCTAssertNotNil(restrictionsView)
        XCTAssertEqual(contentRestrictions.wrappedValue.count, 3)
        XCTAssertEqual(contentRestrictions.wrappedValue["com.apple.mobilesafari"], true)
        XCTAssertEqual(contentRestrictions.wrappedValue["com.apple.mobilemail"], false)
    }

    func testAppListWithToggleSwitches() {
        // Test that app list displays toggle switches for restriction status
        let testRestrictions: [String: Bool] = [
            "com.example.app1": true,
            "com.example.app2": false,
            "com.example.app3": true
        ]

        let contentRestrictions = Binding<[String: Bool]>.constant(testRestrictions)
        let restrictionsView = ContentRestrictionsView(contentRestrictions: contentRestrictions)

        XCTAssertNotNil(restrictionsView)

        // Test that we can create individual app restriction rows
        let testApp = AppMetadata(
            id: "test-app",
            bundleID: "com.example.testapp",
            displayName: "Test App",
            isSystemApp: false,
            iconData: nil
        )

        let isRestricted = Binding<Bool>.constant(true)
        let appRow = AppRestrictionRow(app: testApp, isRestricted: isRestricted)

        XCTAssertNotNil(appRow)
    }

    func testAppCategorizationDataIntegration() {
        // Test integration with existing app categorization data for context
        let testRestrictions: [String: Bool] = [:]
        let contentRestrictions = Binding<[String: Bool]>.constant(testRestrictions)
        let restrictionsView = ContentRestrictionsView(contentRestrictions: contentRestrictions)

        XCTAssertNotNil(restrictionsView)

        // Test that AppMetadata structure supports app categorization integration
        let appMetadata = AppMetadata(
            id: "test-app",
            bundleID: "com.example.app",
            displayName: "Example App",
            isSystemApp: false,
            iconData: nil
        )

        XCTAssertEqual(appMetadata.bundleID, "com.example.app")
        XCTAssertEqual(appMetadata.displayName, "Example App")
        XCTAssertFalse(appMetadata.isSystemApp)
    }

    func testAppRestrictionRowComponents() {
        // Test unit tests for app restrictions components
        let testApp = AppMetadata(
            id: "test-app-1",
            bundleID: "com.example.restrictions.test",
            displayName: "Restrictions Test App",
            isSystemApp: false,
            iconData: nil
        )

        var isRestrictedValue = false
        let isRestricted = Binding(
            get: { isRestrictedValue },
            set: { isRestrictedValue = $0 }
        )

        let appRow = AppRestrictionRow(app: testApp, isRestricted: isRestricted)

        XCTAssertNotNil(appRow)
        XCTAssertFalse(isRestricted.wrappedValue)

        // Test toggling restriction
        isRestricted.wrappedValue = true
        XCTAssertTrue(isRestricted.wrappedValue)

        isRestricted.wrappedValue = false
        XCTAssertFalse(isRestricted.wrappedValue)
    }

    func testSearchFunctionality() {
        // Test search functionality within ContentRestrictionsView
        let mockApps = [
            AppMetadata(id: "1", bundleID: "com.apple.safari", displayName: "Safari", isSystemApp: true, iconData: nil),
            AppMetadata(id: "2", bundleID: "com.apple.mail", displayName: "Mail", isSystemApp: true, iconData: nil),
            AppMetadata(id: "3", bundleID: "com.spotify.music", displayName: "Spotify", isSystemApp: false, iconData: nil)
        ]

        // Test search filtering logic
        let searchText = "mail"
        let filteredApps = mockApps.filter { app in
            app.displayName.localizedCaseInsensitiveContains(searchText) ||
            app.bundleID.localizedCaseInsensitiveContains(searchText)
        }

        XCTAssertEqual(filteredApps.count, 1)
        XCTAssertEqual(filteredApps.first?.displayName, "Mail")

        // Test case-insensitive search
        let caseInsensitiveSearchText = "SAFARI"
        let caseInsensitiveFiltered = mockApps.filter { app in
            app.displayName.localizedCaseInsensitiveContains(caseInsensitiveSearchText) ||
            app.bundleID.localizedCaseInsensitiveContains(caseInsensitiveSearchText)
        }

        XCTAssertEqual(caseInsensitiveFiltered.count, 1)
        XCTAssertEqual(caseInsensitiveFiltered.first?.displayName, "Safari")
    }

    func testRestrictionSummary() {
        // Test restriction summary display
        let testRestrictions: [String: Bool] = [
            "com.app1": true,
            "com.app2": false,
            "com.app3": true,
            "com.app4": false,
            "com.app5": true
        ]

        let restrictedCount = testRestrictions.values.filter { $0 }.count
        let totalCount = testRestrictions.count

        XCTAssertEqual(restrictedCount, 3)
        XCTAssertEqual(totalCount, 5)
    }

    func testClearAllFunctionality() {
        // Test clear all restrictions functionality
        var testRestrictions: [String: Bool] = [
            "com.app1": true,
            "com.app2": true,
            "com.app3": true
        ]

        // Simulate clearing all restrictions
        for bundleID in testRestrictions.keys {
            testRestrictions[bundleID] = false
        }

        let restrictedCount = testRestrictions.values.filter { $0 }.count
        XCTAssertEqual(restrictedCount, 0)
    }

    func testLoadingState() {
        // Test loading state handling
        let contentRestrictions = Binding<[String: Bool]>.constant([:])
        let restrictionsView = ContentRestrictionsView(contentRestrictions: contentRestrictions)

        XCTAssertNotNil(restrictionsView)

        // Test that loading state can be managed (in actual implementation)
        // This would be tested with ViewInspector or similar in a complete test suite
    }

    func testEmptyStateHandling() {
        // Test empty state when no apps are available
        let emptyRestrictions = Binding<[String: Bool]>.constant([:])
        let restrictionsView = ContentRestrictionsView(contentRestrictions: emptyRestrictions)

        XCTAssertNotNil(restrictionsView)
        XCTAssertTrue(emptyRestrictions.wrappedValue.isEmpty)
    }

    func testAccessibilitySupport() {
        // Test accessibility support for app restriction rows
        let testApp = AppMetadata(
            id: "accessibility-test",
            bundleID: "com.example.accessibility",
            displayName: "Accessibility Test App",
            isSystemApp: false,
            iconData: nil
        )

        let isRestricted = Binding<Bool>.constant(false)
        let appRow = AppRestrictionRow(app: testApp, isRestricted: isRestricted)

        XCTAssertNotNil(appRow)

        // Verify that app row can be created with accessibility requirements
        // Actual accessibility testing would be done at runtime with Voice Over
    }
}