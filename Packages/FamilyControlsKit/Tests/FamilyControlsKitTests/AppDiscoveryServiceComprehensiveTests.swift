import XCTest
@testable import FamilyControlsKit
import SharedModels

final class AppDiscoveryServiceComprehensiveTests: XCTestCase {
    var appDiscoveryService: AppDiscoveryService!

    override func setUp() {
        super.setUp()
        appDiscoveryService = AppDiscoveryService()
    }

    override func tearDown() {
        appDiscoveryService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testAppDiscoveryServiceInitialization() {
        XCTAssertNotNil(appDiscoveryService, "AppDiscoveryService should be successfully initialized")
    }

    // MARK: - Fetch Installed Apps Tests

    func testFetchInstalledApps_Success() async throws {
        // When
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then
        XCTAssertFalse(apps.isEmpty, "Should return some mock apps")
        XCTAssertEqual(apps.count, 5, "Should return 5 mock apps")
    }

    func testFetchInstalledApps_Structure() async throws {
        // When
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then
        for app in apps {
            XCTAssertFalse(app.id.isEmpty, "Each app should have a non-empty ID")
            XCTAssertFalse(app.bundleID.isEmpty, "Each app should have a non-empty bundle ID")
            XCTAssertFalse(app.displayName.isEmpty, "Each app should have a non-empty display name")
            XCTAssertNotNil(app.isSystemApp, "Each app should have a isSystemApp value")
        }
    }

    func testFetchInstalledApps_ExpectedApps() async throws {
        // When
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then
        let bundleIDs = apps.map { $0.bundleID }
        XCTAssertTrue(bundleIDs.contains("com.apple.Maps"), "Should contain Maps app")
        XCTAssertTrue(bundleIDs.contains("com.apple.MobileSMS"), "Should contain Messages app")
        XCTAssertTrue(bundleIDs.contains("com.apple.MobileSafari"), "Should contain Safari app")
        XCTAssertTrue(bundleIDs.contains("com.example.learningapp"), "Should contain Learning App")
        XCTAssertTrue(bundleIDs.contains("com.example.game"), "Should contain Fun Game")
    }

    func testFetchInstalledApps_DisplayNames() async throws {
        // When
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then
        let displayNames = apps.map { $0.displayName }
        XCTAssertTrue(displayNames.contains("Maps"), "Should contain Maps")
        XCTAssertTrue(displayNames.contains("Messages"), "Should contain Messages")
        XCTAssertTrue(displayNames.contains("Safari"), "Should contain Safari")
        XCTAssertTrue(displayNames.contains("Learning App"), "Should contain Learning App")
        XCTAssertTrue(displayNames.contains("Fun Game"), "Should contain Fun Game")
    }

    func testFetchInstalledApps_SystemApps() async throws {
        // When
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then
        let systemApps = apps.filter { $0.isSystemApp }
        let nonSystemApps = apps.filter { !$0.isSystemApp }
        
        XCTAssertEqual(systemApps.count, 3, "Should have 3 system apps")
        XCTAssertEqual(nonSystemApps.count, 2, "Should have 2 non-system apps")
        
        XCTAssertTrue(systemApps.allSatisfy { $0.isSystemApp }, "All system apps should be marked as system apps")
        XCTAssertTrue(nonSystemApps.allSatisfy { !$0.isSystemApp }, "All non-system apps should be marked as non-system apps")
    }

    func testFetchInstalledApps_UniqueIDs() async throws {
        // When
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then
        let ids = apps.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All app IDs should be unique")
    }

    // MARK: - App Metadata Tests

    func testAppMetadata_Initialization() async throws {
        // Given
        let id = UUID().uuidString
        let bundleID = "com.test.app"
        let displayName = "Test App"
        let isSystemApp = false
        let iconData: Data? = nil

        // When
        let appMetadata = AppMetadata(
            id: id,
            bundleID: bundleID,
            displayName: displayName,
            isSystemApp: isSystemApp,
            iconData: iconData
        )

        // Then
        XCTAssertEqual(appMetadata.id, id)
        XCTAssertEqual(appMetadata.bundleID, bundleID)
        XCTAssertEqual(appMetadata.displayName, displayName)
        XCTAssertEqual(appMetadata.isSystemApp, isSystemApp)
        XCTAssertEqual(appMetadata.iconData, iconData)
    }

    func testAppMetadata_Equatability() async throws {
        // Given
        let id = UUID().uuidString
        let bundleID = "com.test.app"
        let displayName = "Test App"
        let isSystemApp = false
        let iconData: Data? = nil

        let app1 = AppMetadata(
            id: id,
            bundleID: bundleID,
            displayName: displayName,
            isSystemApp: isSystemApp,
            iconData: iconData
        )

        let app2 = AppMetadata(
            id: id,
            bundleID: bundleID,
            displayName: displayName,
            isSystemApp: isSystemApp,
            iconData: iconData
        )

        let app3 = AppMetadata(
            id: UUID().uuidString,
            bundleID: bundleID,
            displayName: displayName,
            isSystemApp: isSystemApp,
            iconData: iconData
        )

        // Then
        XCTAssertEqual(app1, app2, "Apps with same properties should be equal")
        XCTAssertNotEqual(app1, app3, "Apps with different IDs should not be equal")
    }

    func testAppMetadata_Identifiable() async throws {
        // Given
        let id = UUID().uuidString
        let appMetadata = AppMetadata(
            id: id,
            bundleID: "com.test.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: nil
        )

        // Then
        XCTAssertEqual(appMetadata.id, id, "AppMetadata should conform to Identifiable")
    }

    func testAppMetadata_Codable() async throws {
        // Given
        let id = UUID().uuidString
        let appMetadata = AppMetadata(
            id: id,
            bundleID: "com.test.app",
            displayName: "Test App",
            isSystemApp: true,
            iconData: nil
        )

        // When
        let data = try JSONEncoder().encode(appMetadata)
        let decodedApp = try JSONDecoder().decode(AppMetadata.self, from: data)

        // Then
        XCTAssertEqual(appMetadata.id, decodedApp.id)
        XCTAssertEqual(appMetadata.bundleID, decodedApp.bundleID)
        XCTAssertEqual(appMetadata.displayName, decodedApp.displayName)
        XCTAssertEqual(appMetadata.isSystemApp, decodedApp.isSystemApp)
        XCTAssertEqual(appMetadata.iconData, decodedApp.iconData)
    }

    // MARK: - Edge Case Tests

    func testFetchInstalledApps_MultipleCalls() async throws {
        // When
        let apps1 = try await appDiscoveryService.fetchInstalledApps()
        let apps2 = try await appDiscoveryService.fetchInstalledApps()

        // Then
        XCTAssertEqual(apps1.count, apps2.count, "Multiple calls should return the same number of apps")
        // Note: IDs will be different because they're generated with UUID()
    }

    func testFetchInstalledApps_WithIconData() async throws {
        // This test is for future implementation when icon data is added
        // For now, just verify that iconData can be nil
        let apps = try await appDiscoveryService.fetchInstalledApps()
        let appWithNilIcon = apps.first { $0.iconData == nil }
        XCTAssertNotNil(appWithNilIcon, "Apps can have nil icon data")
    }

    // MARK: - Performance Tests

    func testFetchInstalledApps_Performance() async {
        measure {
            Task {
                do {
                    let _ = try await appDiscoveryService.fetchInstalledApps()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Concurrency Tests

    func testFetchInstalledApps_ConcurrentCalls() async throws {
        // When
        async let apps1 = appDiscoveryService.fetchInstalledApps()
        async let apps2 = appDiscoveryService.fetchInstalledApps()
        async let apps3 = appDiscoveryService.fetchInstalledApps()

        let results = try await [apps1, apps2, apps3]

        // Then
        XCTAssertEqual(results.count, 3, "Should complete all concurrent calls")
        XCTAssertTrue(results.allSatisfy { $0.count == 5 }, "All results should have 5 apps")
    }

    // MARK: - Error Handling Tests

    func testFetchInstalledApps_DoesNotThrow() async {
        // The mock implementation should not throw
        do {
            let apps = try await appDiscoveryService.fetchInstalledApps()
            XCTAssertNotNil(apps, "Should return apps without throwing")
        } catch {
            XCTFail("Fetch installed apps should not throw in mock implementation: \(error)")
        }
    }
}