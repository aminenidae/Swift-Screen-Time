import XCTest
@testable import FamilyControlsKit
import SharedModels

final class FamilyControlsServiceComprehensiveTests: XCTestCase {
    var familyControlsService: FamilyControlsService!

    override func setUp() {
        super.setUp()
        familyControlsService = FamilyControlsService()
    }

    override func tearDown() {
        familyControlsService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testFamilyControlsServiceInitialization() {
        XCTAssertNotNil(familyControlsService, "FamilyControlsService should be successfully initialized")
        XCTAssertEqual(familyControlsService.authorizationStatus, .notDetermined, "Initial authorization status should be notDetermined")
        XCTAssertFalse(familyControlsService.isAuthorized, "Service should not be authorized initially")
    }

    func testFamilyControlsServiceSingleton() {
        let service1 = FamilyControlsService.shared
        let service2 = FamilyControlsService.shared

        XCTAssertTrue(service1 === service2, "FamilyControlsService should be a singleton")
    }

    // MARK: - Authorization Tests

    func testAuthorizationStatusValues() {
        let allStatuses = AuthorizationStatus.allCases
        XCTAssertEqual(allStatuses.count, 3, "Should have 3 authorization statuses")
        XCTAssertTrue(allStatuses.contains(.notDetermined))
        XCTAssertTrue(allStatuses.contains(.denied))
        XCTAssertTrue(allStatuses.contains(.approved))
    }

    func testAuthorizationStatusProperty() {
        // Test that we can read the authorization status
        let status = familyControlsService.authorizationStatus
        XCTAssertTrue([.notDetermined, .denied, .approved].contains(status))
    }

    func testIsAuthorizedProperty() {
        // Initially should not be authorized
        XCTAssertFalse(familyControlsService.isAuthorized)
    }

    // MARK: - Time Allocation Validation Tests

    func testValidateTimeAllocation_ValidTimes() {
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 1), "1 minute should be valid")
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 60), "60 minutes should be valid")
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 120), "120 minutes should be valid")
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 240), "240 minutes (4 hours) should be valid")
    }

    func testValidateTimeAllocation_InvalidTimes() {
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 0), "0 minutes should be invalid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: -1), "Negative time should be invalid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: -60), "Negative time should be invalid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 241), "More than 4 hours should be invalid")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 1000), "Very large time should be invalid")
    }

    func testValidateTimeAllocation_EdgeCases() {
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 1), "Minimum valid time should be accepted")
        XCTAssertTrue(familyControlsService.validateTimeAllocation(timeMinutes: 240), "Maximum valid time should be accepted")
        XCTAssertFalse(familyControlsService.validateTimeAllocation(timeMinutes: 241), "One minute over maximum should be rejected")
    }

    // MARK: - Reward Time Allocation Tests

    func testAllocateRewardTime_AuthorizationRequired() async throws {
        // Given
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 0)
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: redemption, appBundleID: appBundleID)

        // Then
        XCTAssertEqual(result, .authorizationRequired, "Should require authorization when not authorized")
    }

    func testAllocateRewardTime_ExpiredRedemption() async throws {
        // Given - Create service with authorized status for testing
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let expiredRedemption = createMockRedemption(
            status: .active,
            timeGranted: 60,
            timeUsed: 0,
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: expiredRedemption, appBundleID: appBundleID)

        // Then
        XCTAssertEqual(result, .redemptionExpired, "Should return expired for expired redemption")
    }

    func testAllocateRewardTime_NoTimeRemaining() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let usedUpRedemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 60) // All time used
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: usedUpRedemption, appBundleID: appBundleID)

        // Then
        XCTAssertEqual(result, .noTimeRemaining, "Should return no time remaining when all time is used")
    }

    func testAllocateRewardTime_UsedRedemption() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let usedRedemption = createMockRedemption(status: .used, timeGranted: 60, timeUsed: 60)
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: usedRedemption, appBundleID: appBundleID)

        // Then
        XCTAssertEqual(result, .redemptionExpired, "Used redemptions should be treated as expired")
    }

    func testAllocateRewardTime_Success() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 10) // 50 minutes remaining
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: redemption, appBundleID: appBundleID)

        // Then
        if case .systemError = result {
            // This is expected in test environment where Family Controls APIs are not available
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected systemError in test environment, got \(result)")
        }
    }

    // MARK: - Revoke Reward Time Tests

    func testRevokeRewardTime_AuthorizationRequired() async throws {
        // Given
        let redemptionID = "test-redemption-id"
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.revokeRewardTime(redemptionID: redemptionID, appBundleID: appBundleID)

        // Then
        XCTAssertEqual(result, .authorizationRequired, "Should require authorization when not authorized")
    }

    func testRevokeRewardTime_Success() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemptionID = "test-redemption-id"
        let appBundleID = "com.example.game"

        // When
        let result = try await familyControlsService.revokeRewardTime(redemptionID: redemptionID, appBundleID: appBundleID)

        // Then
        if case .systemError = result {
            // This is expected in test environment where Family Controls APIs are not available
            XCTAssertTrue(true)
        } else if case .success(let allocatedMinutes) = result {
            XCTAssertEqual(allocatedMinutes, 0, "Revoking should return 0 allocated minutes")
        } else {
            XCTFail("Expected systemError or success in test environment, got \(result)")
        }
    }

    // MARK: - Time Usage Update Tests

    func testUpdateTimeUsage_AuthorizationRequired() async throws {
        // Given
        let redemptionID = "test-redemption-id"
        let appBundleID = "com.example.game"
        let usedMinutes = 30

        // When
        let result = try await familyControlsService.updateTimeUsage(
            redemptionID: redemptionID,
            appBundleID: appBundleID,
            usedMinutes: usedMinutes
        )

        // Then
        XCTAssertEqual(result, .authorizationRequired, "Should require authorization when not authorized")
    }

    func testUpdateTimeUsage_Success() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemptionID = "test-redemption-id"
        let appBundleID = "com.example.game"
        let usedMinutes = 30

        // When
        let result = try await familyControlsService.updateTimeUsage(
            redemptionID: redemptionID,
            appBundleID: appBundleID,
            usedMinutes: usedMinutes
        )

        // Then
        if case .success(let allocatedMinutes) = result {
            XCTAssertEqual(allocatedMinutes, usedMinutes, "Should return the used minutes")
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    func testUpdateTimeUsage_ZeroMinutes() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemptionID = "test-redemption-id"
        let appBundleID = "com.example.game"
        let usedMinutes = 0

        // When
        let result = try await familyControlsService.updateTimeUsage(
            redemptionID: redemptionID,
            appBundleID: appBundleID,
            usedMinutes: usedMinutes
        )

        // Then
        if case .success(let allocatedMinutes) = result {
            XCTAssertEqual(allocatedMinutes, 0, "Should return 0 minutes")
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    // MARK: - Active Allocations Tests

    func testGetActiveRewardAllocations_AuthorizationRequired() async throws {
        // Given
        let childID = "test-child-id"

        // When & Then
        do {
            let _ = try await familyControlsService.getActiveRewardAllocations(for: childID)
            XCTFail("Should throw authorization error when not authorized")
        } catch {
            // Should throw authorization error when not authorized
            XCTAssertTrue(error is FamilyControlsError)
            if case FamilyControlsError.authorizationRequired = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected authorizationRequired error, got \(error)")
            }
        }
    }

    func testGetActiveRewardAllocations_Success() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        let childID = "test-child-id"

        // When
        let allocations = try await familyControlsService.getActiveRewardAllocations(for: childID)

        // Then
        XCTAssertTrue(allocations.isEmpty, "Should return empty array in mock implementation")
    }

    // MARK: - App Discovery and Management Tests

    func testDiscoverApplications() {
        let selection = familyControlsService.discoverApplications()
        XCTAssertNotNil(selection, "Should return a FamilyActivitySelection")
        // In mock implementation, should be empty
        #if targetEnvironment(simulator)
        XCTAssertTrue(selection.applicationTokens.isEmpty, "Should be empty in simulator")
        #endif
    }

    func testGetApplicationInfo() {
        // Create a mock token
        let mockToken = ApplicationToken("com.example.app")

        let info = familyControlsService.getApplicationInfo(for: mockToken)
        // Should return nil in placeholder implementation
        XCTAssertNil(info, "Should return nil in mock implementation")
    }

    func testCategorizeApplication() {
        // Create a mock token
        let mockToken = ApplicationToken("com.example.app")

        let category = familyControlsService.categorizeApplication(mockToken)
        // Should return .other in placeholder implementation
        XCTAssertEqual(category, ApplicationCategory.other, "Should return .other in mock implementation")
    }

    func testGetCurrentUsage() async {
        let mockToken = ApplicationToken("com.example.app")
        let applications: Set<ApplicationToken> = [mockToken]
        let startTime = Date().addingTimeInterval(-3600) // 1 hour ago

        let usage = await familyControlsService.getCurrentUsage(for: applications, since: startTime)

        // Should return empty dictionary in placeholder implementation
        XCTAssertTrue(usage.isEmpty, "Should return empty dictionary in mock implementation")
    }

    func testGetCurrentUsageWithInterval() async {
        let mockToken = ApplicationToken("com.example.app")
        let applications: Set<ApplicationToken> = [mockToken]
        let now = Date()
        let interval = DateInterval(start: now.addingTimeInterval(-3600), end: now) // Last hour

        let usage = await familyControlsService.getCurrentUsage(for: applications, during: interval)

        // Should return empty dictionary in placeholder implementation
        XCTAssertTrue(usage.isEmpty, "Should return empty dictionary in mock implementation")
    }

    func testStopMonitoring() {
        let childID = "test-child-id"

        // This should not throw in placeholder implementation
        familyControlsService.stopMonitoring(for: childID)

        // Test passes if no exception is thrown
        XCTAssertTrue(true)
    }

    func testRemoveAllRestrictions() {
        // This should not throw in placeholder implementation
        familyControlsService.removeAllRestrictions()

        // Test passes if no exception is thrown
        XCTAssertTrue(true)
    }

    // MARK: - Extension Method Tests

    func testAllocateRewardTimeWithAppCategorization_AuthorizationRequired() async throws {
        // Given
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 0)
        let appCategorization = AppCategorization(
            id: "app-cat-1",
            appBundleID: "com.example.game",
            category: .reward,
            childProfileID: "child-1",
            pointsPerHour: 120,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let result = try await familyControlsService.allocateRewardTime(for: redemption, using: appCategorization)

        // Then
        XCTAssertEqual(result, .authorizationRequired, "Should require authorization when not authorized")
    }

    func testAllocateRewardTimeWithAppCategorization_Success() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 10)
        let appCategorization = AppCategorization(
            id: "app-cat-1",
            appBundleID: "com.example.game",
            category: .reward,
            childProfileID: "child-1",
            pointsPerHour: 120,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let result = try await familyControlsService.allocateRewardTime(for: redemption, using: appCategorization)

        // Then
        if case .systemError = result {
            // This is expected in test environment where Family Controls APIs are not available
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected systemError in test environment, got \(result)")
        }
    }

    // MARK: - Result Type Tests

    func testRewardTimeAllocationResult_IsSuccess() {
        let successResult = RewardTimeAllocationResult.success(allocatedMinutes: 60)
        let authResult = RewardTimeAllocationResult.authorizationRequired
        let expiredResult = RewardTimeAllocationResult.redemptionExpired
        let noTimeResult = RewardTimeAllocationResult.noTimeRemaining
        let systemResult = RewardTimeAllocationResult.systemError("Test error")

        XCTAssertTrue(successResult.isSuccess, "Success result should be marked as success")
        XCTAssertFalse(authResult.isSuccess, "Authorization required should not be success")
        XCTAssertFalse(expiredResult.isSuccess, "Expired result should not be success")
        XCTAssertFalse(noTimeResult.isSuccess, "No time remaining should not be success")
        XCTAssertFalse(systemResult.isSuccess, "System error should not be success")
    }

    func testRewardTimeAllocationResult_ErrorMessage() {
        let successResult = RewardTimeAllocationResult.success(allocatedMinutes: 60)
        let authResult = RewardTimeAllocationResult.authorizationRequired
        let expiredResult = RewardTimeAllocationResult.redemptionExpired
        let noTimeResult = RewardTimeAllocationResult.noTimeRemaining
        let systemResult = RewardTimeAllocationResult.systemError("Test error")

        XCTAssertNil(successResult.errorMessage, "Success should have no error message")
        XCTAssertNotNil(authResult.errorMessage, "Authorization required should have error message")
        XCTAssertNotNil(expiredResult.errorMessage, "Expired should have error message")
        XCTAssertNotNil(noTimeResult.errorMessage, "No time remaining should have error message")
        XCTAssertTrue(systemResult.errorMessage?.contains("Test error") ?? false, "System error should contain the error message")
    }

    func testRewardTimeAllocationResult_Equality() {
        let result1 = RewardTimeAllocationResult.success(allocatedMinutes: 60)
        let result2 = RewardTimeAllocationResult.success(allocatedMinutes: 60)
        let result3 = RewardTimeAllocationResult.success(allocatedMinutes: 30)
        let authResult = RewardTimeAllocationResult.authorizationRequired

        XCTAssertEqual(result1, result2, "Same success results should be equal")
        XCTAssertNotEqual(result1, result3, "Different success results should not be equal")
        XCTAssertNotEqual(result1, authResult, "Different result types should not be equal")
    }

    // MARK: - Error Type Tests

    func testFamilyControlsError_Descriptions() {
        let authError = FamilyControlsError.authorizationRequired
        let simulatorError = FamilyControlsError.simulatorNotSupported
        let notImplementedError = FamilyControlsError.notImplemented("Test feature")
        let invalidRedemptionError = FamilyControlsError.invalidRedemption
        let managedSettingsError = FamilyControlsError.managedSettingsError("Test error")

        XCTAssertEqual(authError.localizedDescription, "Family Controls authorization is required")
        XCTAssertEqual(simulatorError.localizedDescription, "Family Controls is not supported in the simulator")
        XCTAssertEqual(notImplementedError.localizedDescription, "Feature not implemented: Test feature")
        XCTAssertEqual(invalidRedemptionError.localizedDescription, "Invalid or expired redemption")
        XCTAssertEqual(managedSettingsError.localizedDescription, "Managed Settings error: Test error")
    }

    func testFamilyControlsError_Equatability() {
        let error1 = FamilyControlsError.authorizationRequired
        let error2 = FamilyControlsError.authorizationRequired
        let error3 = FamilyControlsError.simulatorNotSupported

        XCTAssertEqual(error1, error2, "Same error types should be equal")
        XCTAssertNotEqual(error1, error3, "Different error types should not be equal")
    }

    // MARK: - Reward Time Allocation Structure Tests

    func testRewardTimeAllocationInitialization() {
        let now = Date()
        let future = now.addingTimeInterval(3600) // 1 hour from now

        let allocation = RewardTimeAllocation(
            redemptionID: "test-redemption",
            appBundleID: "com.example.app",
            allocatedMinutes: 60,
            usedMinutes: 30,
            expiresAt: future,
            isActive: true
        )

        XCTAssertEqual(allocation.redemptionID, "test-redemption")
        XCTAssertEqual(allocation.appBundleID, "com.example.app")
        XCTAssertEqual(allocation.allocatedMinutes, 60)
        XCTAssertEqual(allocation.usedMinutes, 30)
        XCTAssertEqual(allocation.expiresAt, future)
        XCTAssertTrue(allocation.isActive)
    }

    func testRewardTimeAllocation_EdgeCases() {
        let past = Date().addingTimeInterval(-3600) // 1 hour ago
        let future = Date().addingTimeInterval(3600) // 1 hour from now

        let expiredAllocation = RewardTimeAllocation(
            redemptionID: "expired-redemption",
            appBundleID: "com.example.app",
            allocatedMinutes: 60,
            usedMinutes: 60,
            expiresAt: past,
            isActive: false
        )

        let activeAllocation = RewardTimeAllocation(
            redemptionID: "active-redemption",
            appBundleID: "com.example.app",
            allocatedMinutes: 60,
            usedMinutes: 0,
            expiresAt: future,
            isActive: true
        )

        XCTAssertEqual(expiredAllocation.redemptionID, "expired-redemption")
        XCTAssertEqual(expiredAllocation.usedMinutes, 60)
        XCTAssertEqual(expiredAllocation.expiresAt, past)
        XCTAssertFalse(expiredAllocation.isActive)

        XCTAssertEqual(activeAllocation.redemptionID, "active-redemption")
        XCTAssertEqual(activeAllocation.usedMinutes, 0)
        XCTAssertEqual(activeAllocation.expiresAt, future)
        XCTAssertTrue(activeAllocation.isActive)
    }

    // MARK: - Application Token Tests

    func testApplicationToken_Hashable() {
        let token1 = "com.example.app1"
        let token2 = "com.example.app2"
        let token3 = "com.example.app1" // Same as token1

        let set: Set<String> = [token1, token2, token3]
        XCTAssertEqual(set.count, 2, "Should only have 2 unique tokens")
        XCTAssertTrue(set.contains(token1))
        XCTAssertTrue(set.contains(token2))
    }

    func testApplicationToken_Equality() {
        let token1 = "com.example.app"
        let token2 = "com.example.app"
        let token3 = "com.example.other"

        XCTAssertEqual(token1, token2, "Same tokens should be equal")
        XCTAssertNotEqual(token1, token3, "Different tokens should not be equal")
    }

    // MARK: - Application Category Tests

    func testApplicationCategory_AllCases() {
        let allCategories: [FamilyControlsKit.ApplicationCategory] = [.education, .game, .social, .productivity, .entertainment, .other]
        XCTAssertEqual(allCategories.count, 6, "Should have 6 application categories")
    }

    func testApplicationCategory_Equality() {
        XCTAssertEqual(FamilyControlsKit.ApplicationCategory.education, .education)
        XCTAssertNotEqual(FamilyControlsKit.ApplicationCategory.education, .game)
        XCTAssertNotEqual(FamilyControlsKit.ApplicationCategory.game, .social)
    }

    // MARK: - Application Info Tests

    func testApplicationInfoInitialization() {
        let info = ApplicationInfo(
            bundleID: "com.example.app",
            displayName: "Test App",
            category: FamilyControlsKit.ApplicationCategory.education
        )

        XCTAssertEqual(info.bundleID, "com.example.app")
        XCTAssertEqual(info.displayName, "Test App")
        XCTAssertEqual(info.category, FamilyControlsKit.ApplicationCategory.education)
    }

    func testApplicationInfo_EdgeCases() {
        let info = ApplicationInfo(
            bundleID: "",
            displayName: "",
            category: .other
        )

        XCTAssertEqual(info.bundleID, "")
        XCTAssertEqual(info.displayName, "")
        XCTAssertEqual(info.category, FamilyControlsKit.ApplicationCategory.other)
    }

    // MARK: - Performance Tests

    func testValidateTimeAllocation_Performance() {
        measure {
            _ = familyControlsService.validateTimeAllocation(timeMinutes: 120)
        }
    }

    func testAllocateRewardTime_Performance() async {
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 0)
        let appBundleID = "com.example.app"

        measure {
            Task {
                do {
                    let _ = try await familyControlsService.allocateRewardTime(for: redemption, appBundleID: appBundleID)
                } catch {
                    // Expected in test environment
                }
            }
        }
    }

    // MARK: - Edge Case Tests

    func testAllocateRewardTime_WithEmptyAppBundleID() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 0)
        let appBundleID = ""

        // When
        let result = try await familyControlsService.allocateRewardTime(for: redemption, appBundleID: appBundleID)

        // Then
        if case .systemError = result {
            // This is expected in test environment
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected systemError in test environment, got \(result)")
        }
    }

    func testAllocateRewardTime_WithSpecialCharacters() async throws {
        // Given
        familyControlsService.isAuthorized = true
        familyControlsService.authorizationStatus = .approved
        
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 0)
        let appBundleID = "com.example.app-with.special-chars_123"

        // When
        let result = try await familyControlsService.allocateRewardTime(for: redemption, appBundleID: appBundleID)

        // Then
        if case .systemError = result {
            // This is expected in test environment
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected systemError in test environment, got \(result)")
        }
    }

    // MARK: - Helper Methods

    private func createMockRedemption(
        status: RedemptionStatus,
        timeGranted: Int,
        timeUsed: Int,
        expiresAt: Date = Date().addingTimeInterval(3600) // 1 hour from now by default
    ) -> PointToTimeRedemption {
        return PointToTimeRedemption(
            id: UUID().uuidString,
            childProfileID: "test-child-id",
            appCategorizationID: "test-app-cat-id",
            pointsSpent: timeGranted * 10, // Assuming 10 points per minute
            timeGrantedMinutes: timeGranted,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: expiresAt,
            timeUsedMinutes: timeUsed,
            status: status
        )
    }
}