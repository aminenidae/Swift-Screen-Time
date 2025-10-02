import XCTest
@testable import FamilyControlsKit
import SharedModels

final class FamilyControlsKitIntegrationTests: XCTestCase {

    // MARK: - Full Workflow Tests

    func testFullAppDiscoveryAndCategorizationWorkflow() async throws {
        // Given
        let appDiscoveryService = AppDiscoveryService()
        let familyControlsService = FamilyControlsService()

        // When - Discover apps
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then - Verify app discovery
        XCTAssertFalse(apps.isEmpty, "Should discover apps")
        XCTAssertTrue(apps.allSatisfy { !$0.bundleID.isEmpty }, "All apps should have bundle IDs")
        XCTAssertTrue(apps.allSatisfy { !$0.displayName.isEmpty }, "All apps should have display names")

        // When - Try to categorize apps (mock implementation)
        for app in apps {
            let token = ApplicationToken(app.bundleID)
            let category = familyControlsService.categorizeApplication(token)
            
            // Then - Verify categorization (mock returns .other)
            XCTAssertEqual(category, ApplicationCategory.other, "Mock implementation should return .other")
        }
    }

    func testTimeAllocationWorkflow() async throws {
        // Given
        let familyControlsService = FamilyControlsService()
        // Simulate authorized state for testing
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved

        let redemption = PointToTimeRedemption(
            id: "workflow-test-redemption",
            childProfileID: "test-child",
            appCategorizationID: "test-app-cat",
            pointsSpent: 300,
            timeGrantedMinutes: 30,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 3600), // 24 hours
            timeUsedMinutes: 0,
            status: .active
        )
        let appBundleID = "com.example.rewardapp"

        // When - Allocate reward time
        let allocationResult = try await familyControlsService.allocateRewardTime(
            for: redemption,
            appBundleID: appBundleID
        )

        // Then - Verify appropriate handling in test environment
        if case .systemError = allocationResult {
            // Expected in test environment where Family Controls APIs are not available
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected systemError in test environment, got \(allocationResult)")
        }

        // When - Update time usage
        let usageResult = try await familyControlsService.updateTimeUsage(
            redemptionID: redemption.id,
            appBundleID: appBundleID,
            usedMinutes: 15
        )

        // Then - Verify usage update handling
        if case .success(let allocatedMinutes) = usageResult {
            XCTAssertEqual(allocatedMinutes, 15, "Should return the used minutes")
        } else {
            XCTFail("Expected success for usage update, got \(usageResult)")
        }

        // When - Revoke remaining time
        let revokeResult = try await familyControlsService.revokeRewardTime(
            redemptionID: redemption.id,
            appBundleID: appBundleID
        )

        // Then - Verify revocation handling
        if case .systemError = revokeResult {
            // Expected in test environment
            XCTAssertTrue(true)
        } else if case .success(let allocatedMinutes) = revokeResult {
            XCTAssertEqual(allocatedMinutes, 0, "Revoking should return 0 allocated minutes")
        } else {
            XCTFail("Expected systemError or success for revoke, got \(revokeResult)")
        }
    }

    func testTimeAllocationWithAppCategorizationWorkflow() async throws {
        // Given
        let familyControlsService = FamilyControlsService()
        // Simulate authorized state for testing
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved

        let redemption = PointToTimeRedemption(
            id: "categorization-test-redemption",
            childProfileID: "test-child",
            appCategorizationID: "test-app-cat",
            pointsSpent: 200,
            timeGrantedMinutes: 20,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(12 * 3600), // 12 hours
            timeUsedMinutes: 5,
            status: .active
        )
        
        let appCategorization = AppCategorization(
            id: "app-cat-1",
            appBundleID: "com.example.learninggame",
            category: .learning,
            childProfileID: "test-child",
            pointsPerHour: 60,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When - Allocate reward time using app categorization
        let result = try await familyControlsService.allocateRewardTime(for: redemption, using: appCategorization)

        // Then - Verify appropriate handling in test environment
        if case .systemError = result {
            // Expected in test environment where Family Controls APIs are not available
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected systemError in test environment, got \(result)")
        }
    }

    // MARK: - Edge Case Integration Tests

    func testIntegrationWithInvalidRedemption() async throws {
        // Given
        let familyControlsService = FamilyControlsService()
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved

        let expiredRedemption = PointToTimeRedemption(
            id: "expired-redemption",
            childProfileID: "test-child",
            appCategorizationID: "test-app-cat",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            expiresAt: Date().addingTimeInterval(-1800), // 30 minutes ago (expired)
            timeUsedMinutes: 0,
            status: .active
        )
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: expiredRedemption, appBundleID: appBundleID)

        // Then
        if case .redemptionExpired = result {
            // Expected result
            XCTAssertTrue(true)
        } else {
            XCTFail("Should return expired for expired redemption, got \(result)")
        }
    }

    func testIntegrationWithUsedUpRedemption() async throws {
        // Given
        let familyControlsService = FamilyControlsService()
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved

        let usedUpRedemption = PointToTimeRedemption(
            id: "used-up-redemption",
            childProfileID: "test-child",
            appCategorizationID: "test-app-cat",
            pointsSpent: 200,
            timeGrantedMinutes: 20,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            timeUsedMinutes: 20, // All used up
            status: .active
        )
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: usedUpRedemption, appBundleID: appBundleID)

        // Then
        if case .noTimeRemaining = result {
            // Expected result
            XCTAssertTrue(true)
        } else {
            XCTFail("Should return no time remaining when all time is used, got \(result)")
        }
    }

    func testIntegrationWithoutAuthorization() async throws {
        // Given
        let familyControlsService = FamilyControlsService()
        // Do NOT set authorized state

        let redemption = PointToTimeRedemption(
            id: "unauthorized-redemption",
            childProfileID: "test-child",
            appCategorizationID: "test-app-cat",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            timeUsedMinutes: 0,
            status: .active
        )
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: redemption, appBundleID: appBundleID)

        // Then
        if case .authorizationRequired = result {
            // Expected result
            XCTAssertTrue(true)
        } else {
            XCTFail("Should require authorization when not authorized, got \(result)")
        }
    }

    // MARK: - Time Conversion Integration Tests

    func testTimeConversionIntegration() async throws {
        // Given
        let appDiscoveryService = AppDiscoveryService()
        let familyControlsService = FamilyControlsService()

        // When - Discover apps
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then - Verify time conversion works with discovered apps
        for app in apps {
            // Test that we can work with time intervals
            let usageTime = TimeInterval.minutes(30)
            let usageHours = usageTime.hours
            let usageMinutes = usageTime.minutes
            
            XCTAssertEqual(usageMinutes, 30, "30 minutes should convert correctly")
            XCTAssertEqual(usageHours, 0.5, "30 minutes should be 0.5 hours")
        }
    }

    func testTimeAllocationValidationIntegration() async throws {
        // Given
        let familyControlsService = FamilyControlsService()

        // When & Then - Test various time allocations
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 1), "1 minute should be valid")
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 240), "240 minutes (4 hours) should be valid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 241), "241 minutes should be invalid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 0), "0 minutes should be invalid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: -1), "Negative time should be invalid")
    }

    // MARK: - Error Handling Integration Tests

    func testErrorHandlingIntegration() async throws {
        // Given
        let familyControlsService = FamilyControlsService()

        // Test FamilyControlsError
        let authError = FamilyControlsError.authorizationRequired
        let simulatorError = FamilyControlsError.simulatorNotSupported
        let notImplementedError = FamilyControlsError.notImplemented("Test feature")

        XCTAssertNotNil(authError.localizedDescription)
        XCTAssertNotNil(simulatorError.localizedDescription)
        XCTAssertNotNil(notImplementedError.localizedDescription)

        // Test RewardTimeAllocationResult error messages
        let authResult = RewardTimeAllocationResult.authorizationRequired
        let expiredResult = RewardTimeAllocationResult.redemptionExpired
        let noTimeResult = RewardTimeAllocationResult.noTimeRemaining

        XCTAssertNotNil(authResult.errorMessage)
        XCTAssertNotNil(expiredResult.errorMessage)
        XCTAssertNotNil(noTimeResult.errorMessage)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentAppDiscoveryAndTimeAllocation() async throws {
        // Given
        let appDiscoveryService = AppDiscoveryService()
        let familyControlsService = FamilyControlsService()
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved

        // When - Run concurrent operations
        async let apps = appDiscoveryService.fetchInstalledApps()
        async let validation1 = familyControlsService.validateTimeAllocation(timeMinutes: 60)
        async let validation2 = familyControlsService.validateTimeAllocation(timeMinutes: 120)

        let (discoveredApps, isValid1, isValid2) = try await (apps, validation1, validation2)

        // Then - Verify all operations completed successfully
        XCTAssertFalse(discoveredApps.isEmpty, "Should discover apps concurrently")
        XCTAssertTrue(isValid1, "60 minutes should be valid")
        XCTAssertTrue(isValid2, "120 minutes should be valid")
    }

    // MARK: - Performance Integration Tests

    func testPerformanceIntegration() async throws {
        // Given
        let appDiscoveryService = AppDiscoveryService()
        let familyControlsService = FamilyControlsService()

        // Measure the performance of integrated operations
        measure {
            Task {
                do {
                    // Discover apps
                    let apps = try await appDiscoveryService.fetchInstalledApps()
                    
                    // Validate time allocations
                    let isValid = familyControlsService.validateTimeAllocation(timeMinutes: 120)
                    
                    // Verify results
                    XCTAssertFalse(apps.isEmpty)
                    XCTAssertTrue(isValid)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Data Consistency Tests

    func testDataConsistencyAcrossServices() async throws {
        // Given
        let appDiscoveryService = AppDiscoveryService()
        let familyControlsService = FamilyControlsService()

        // When - Get apps from discovery service
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then - Verify consistency with FamilyControlsService
        for app in apps {
            let token = ApplicationToken(app.bundleID)
            let appInfo = familyControlsService.getApplicationInfo(for: token)
            
            // In mock implementation, should return nil
            XCTAssertNil(appInfo, "Mock implementation should return nil")
        }
    }

    // MARK: - Boundary Condition Tests

    func testBoundaryConditions() async throws {
        // Given
        let familyControlsService = FamilyControlsService()
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved

        // Test maximum valid time allocation
        let maxValidRedemption = PointToTimeRedemption(
            id: "max-time-redemption",
            childProfileID: "test-child",
            appCategorizationID: "test-app-cat",
            pointsSpent: 2400, // 240 minutes at 10 points/minute
            timeGrantedMinutes: 240, // Maximum 4 hours
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 3600),
            timeUsedMinutes: 0,
            status: .active
        )
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: maxValidRedemption, appBundleID: appBundleID)

        // Then
        if case .systemError = result {
            // Expected in test environment
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected systemError in test environment, got \(result)")
        }

        // Test time validation at boundaries
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 1), "Minimum valid time should work")
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 240), "Maximum valid time should work")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 0), "Zero should be invalid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 241), "One over maximum should be invalid")
    }

    // MARK: - Mock Data Integration Tests

    func testMockDataIntegration() async throws {
        // Given
        let appDiscoveryService = AppDiscoveryService()

        // When
        let apps = try await appDiscoveryService.fetchInstalledApps()

        // Then - Verify mock data structure
        XCTAssertEqual(apps.count, 5, "Should return 5 mock apps")
        
        let systemApps = apps.filter { $0.isSystemApp }
        let nonSystemApps = apps.filter { !$0.isSystemApp }
        
        XCTAssertEqual(systemApps.count, 3, "Should have 3 system apps")
        XCTAssertEqual(nonSystemApps.count, 2, "Should have 2 non-system apps")
        
        // Verify specific apps
        let bundleIDs = apps.map { $0.bundleID }
        XCTAssertTrue(bundleIDs.contains("com.apple.Maps"))
        XCTAssertTrue(bundleIDs.contains("com.apple.MobileSMS"))
        XCTAssertTrue(bundleIDs.contains("com.apple.MobileSafari"))
        XCTAssertTrue(bundleIDs.contains("com.example.learningapp"))
        XCTAssertTrue(bundleIDs.contains("com.example.game"))
    }
}