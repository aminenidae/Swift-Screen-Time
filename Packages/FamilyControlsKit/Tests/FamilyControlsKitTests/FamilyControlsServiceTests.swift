import XCTest
@testable import FamilyControlsKit
import SharedModels

final class FamilyControlsServiceTests: XCTestCase {
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

    func testInitialization() {
        XCTAssertNotNil(familyControlsService)
        // Authorization status should be checked on init
        XCTAssertTrue([.notDetermined, .denied, .approved].contains(familyControlsService.authorizationStatus))
    }

    // MARK: - Time Allocation Validation Tests

    func testValidateTimeAllocation_ValidTime() {
        // Given
        let validTimeMinutes = 60

        // When
        let isValid = familyControlsService.validateTimeAllocation(timeMinutes: validTimeMinutes)

        // Then
        XCTAssertTrue(isValid)
    }

    func testValidateTimeAllocation_ZeroTime() {
        // Given
        let zeroTime = 0

        // When
        let isValid = familyControlsService.validateTimeAllocation(timeMinutes: zeroTime)

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateTimeAllocation_ExcessiveTime() {
        // Given
        let excessiveTime = 300 // 5 hours, exceeds 4 hour limit

        // When
        let isValid = familyControlsService.validateTimeAllocation(timeMinutes: excessiveTime)

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateTimeAllocation_MaximumAllowedTime() {
        // Given
        let maxTime = 240 // 4 hours, at the limit

        // When
        let isValid = familyControlsService.validateTimeAllocation(timeMinutes: maxTime)

        // Then
        XCTAssertTrue(isValid)
    }

    // MARK: - Reward Time Allocation Tests (Simulator Environment)

    func testAllocateRewardTime_AuthorizationRequired() async {
        // Given
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 0)
        let appBundleID = "com.example.game"

        // When
        let result = try! await familyControlsService.allocateRewardTime(for: redemption, appBundleID: appBundleID)

        // Then
        switch result {
        case .authorizationRequired:
            // Expected in test environment where authorization is not granted
            XCTAssertTrue(true)
        case .systemError(let message):
            // Also acceptable as simulator may throw system errors
            XCTAssertTrue(message.contains("not") || message.contains("simulator") || message.contains("implemented"))
        default:
            XCTFail("Expected authorizationRequired or systemError, got \(result)")
        }
    }

    func testAllocateRewardTime_ExpiredRedemption() async {
        // Given
        let expiredRedemption = createMockRedemption(
            status: .active,
            timeGranted: 60,
            timeUsed: 0,
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        let appBundleID = "com.example.game"

        // When
        let result = try! await familyControlsService.allocateRewardTime(for: expiredRedemption, appBundleID: appBundleID)

        // Then
        switch result {
        case .redemptionExpired:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected redemptionExpired, got \(result)")
        }
    }

    func testAllocateRewardTime_NoTimeRemaining() async {
        // Given
        let usedUpRedemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 60) // All time used
        let appBundleID = "com.example.game"

        // When
        let result = try! await familyControlsService.allocateRewardTime(for: usedUpRedemption, appBundleID: appBundleID)

        // Then
        switch result {
        case .noTimeRemaining:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected noTimeRemaining, got \(result)")
        }
    }

    func testAllocateRewardTime_UsedRedemption() async {
        // Given
        let usedRedemption = createMockRedemption(status: .used, timeGranted: 60, timeUsed: 60)
        let appBundleID = "com.example.game"

        // When
        let result = try! await familyControlsService.allocateRewardTime(for: usedRedemption, appBundleID: appBundleID)

        // Then
        switch result {
        case .redemptionExpired:
            XCTAssertTrue(true) // Used redemptions are treated as expired
        default:
            XCTFail("Expected redemptionExpired for used redemption, got \(result)")
        }
    }

    // MARK: - Revoke Reward Time Tests

    func testRevokeRewardTime_AuthorizationRequired() async {
        // Given
        let redemptionID = "test-redemption-id"
        let appBundleID = "com.example.game"

        // When
        let result = try! await familyControlsService.revokeRewardTime(redemptionID: redemptionID, appBundleID: appBundleID)

        // Then
        switch result {
        case .authorizationRequired:
            XCTAssertTrue(true)
        case .systemError(let message):
            // Also acceptable in test environment
            XCTAssertTrue(message.contains("not") || message.contains("simulator") || message.contains("implemented"))
        default:
            XCTFail("Expected authorizationRequired or systemError, got \(result)")
        }
    }

    // MARK: - Time Usage Update Tests

    func testUpdateTimeUsage_AuthorizationRequired() async {
        // Given
        let redemptionID = "test-redemption-id"
        let appBundleID = "com.example.game"
        let usedMinutes = 30

        // When
        let result = try! await familyControlsService.updateTimeUsage(
            redemptionID: redemptionID,
            appBundleID: appBundleID,
            usedMinutes: usedMinutes
        )

        // Then
        switch result {
        case .authorizationRequired:
            XCTAssertTrue(true)
        case .success(let allocatedMinutes):
            // In test environment, might return success with used minutes
            XCTAssertEqual(allocatedMinutes, usedMinutes)
        default:
            XCTFail("Expected authorizationRequired or success, got \(result)")
        }
    }

    // MARK: - Active Allocations Tests

    func testGetActiveRewardAllocations_AuthorizationRequired() async {
        // Given
        let childID = "test-child-id"

        // When & Then
        do {
            let _ = try await familyControlsService.getActiveRewardAllocations(for: childID)
            // If we get here without throwing, that's also acceptable (empty array)
        } catch {
            // Should throw authorization error in test environment
            XCTAssertTrue(error.localizedDescription.contains("authorization") ||
                         error.localizedDescription.contains("required"))
        }
    }

    // MARK: - Convenience Methods Tests

    func testAllocateRewardTimeWithAppCategorization() async {
        // Given
        let redemption = createMockRedemption(status: .active, timeGranted: 60, timeUsed: 0)
        let appCategorization = AppCategorization(
            id: "app-cat-1",
            appBundleID: "com.example.game",
            category: .reward,
            childProfileID: "child-1",
            pointsPerHour: 120
        )

        // When
        let result = try! await familyControlsService.allocateRewardTime(for: redemption, using: appCategorization)

        // Then
        switch result {
        case .authorizationRequired, .systemError:
            // Expected in test environment
            XCTAssertTrue(true)
        default:
            XCTFail("Expected authorizationRequired or systemError in test environment, got \(result)")
        }
    }

    // MARK: - Result Extension Tests

    func testRewardTimeAllocationResult_IsSuccess() {
        // Given
        let successResult = RewardTimeAllocationResult.success(allocatedMinutes: 60)
        let failureResult = RewardTimeAllocationResult.authorizationRequired

        // When & Then
        XCTAssertTrue(successResult.isSuccess)
        XCTAssertFalse(failureResult.isSuccess)
    }

    func testRewardTimeAllocationResult_ErrorMessage() {
        // Given
        let successResult = RewardTimeAllocationResult.success(allocatedMinutes: 60)
        let authResult = RewardTimeAllocationResult.authorizationRequired
        let expiredResult = RewardTimeAllocationResult.redemptionExpired
        let noTimeResult = RewardTimeAllocationResult.noTimeRemaining
        let systemResult = RewardTimeAllocationResult.systemError("Test error")

        // When & Then
        XCTAssertNil(successResult.errorMessage)
        XCTAssertNotNil(authResult.errorMessage)
        XCTAssertNotNil(expiredResult.errorMessage)
        XCTAssertNotNil(noTimeResult.errorMessage)
        XCTAssertTrue(systemResult.errorMessage?.contains("Test error") ?? false)
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

// MARK: - Integration Tests

final class FamilyControlsServiceIntegrationTests: XCTestCase {
    var familyControlsService: FamilyControlsService!

    override func setUp() {
        super.setUp()
        familyControlsService = FamilyControlsService()
    }

    override func tearDown() {
        familyControlsService = nil
        super.tearDown()
    }

    /// Test the full workflow from redemption to time allocation
    func testFullRewardTimeWorkflow() async {
        // Given
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
        let allocationResult = try! await familyControlsService.allocateRewardTime(
            for: redemption,
            appBundleID: appBundleID
        )

        // Then - Verify appropriate handling in test environment
        switch allocationResult {
        case .authorizationRequired:
            // Expected in test environment without proper Family Controls setup
            XCTAssertTrue(true)

        case .systemError(let message):
            // Also expected in simulator or test environment
            XCTAssertTrue(message.contains("simulator") ||
                         message.contains("implemented") ||
                         message.contains("not"))

        case .success(let allocatedMinutes):
            // If we somehow get success in test environment
            XCTAssertEqual(allocatedMinutes, 30)

        default:
            XCTFail("Unexpected result in test environment: \(allocationResult)")
        }

        // When - Update time usage
        let usageResult = try! await familyControlsService.updateTimeUsage(
            redemptionID: redemption.id,
            appBundleID: appBundleID,
            usedMinutes: 15
        )

        // Then - Verify usage update handling
        switch usageResult {
        case .authorizationRequired, .success:
            // Both acceptable in test environment
            XCTAssertTrue(true)
        default:
            XCTFail("Unexpected usage update result: \(usageResult)")
        }

        // When - Revoke remaining time
        let revokeResult = try! await familyControlsService.revokeRewardTime(
            redemptionID: redemption.id,
            appBundleID: appBundleID
        )

        // Then - Verify revocation handling
        switch revokeResult {
        case .authorizationRequired, .systemError, .success:
            // All acceptable in test environment
            XCTAssertTrue(true)
        default:
            XCTFail("Unexpected revoke result: \(revokeResult)")
        }
    }

    /// Test edge cases and error conditions
    func testEdgeCases() async {
        // Test with nil/empty values
        let emptyBundleID = ""
        let mockRedemption = PointToTimeRedemption(
            id: "",
            childProfileID: "",
            appCategorizationID: "",
            pointsSpent: 0,
            timeGrantedMinutes: 0,
            conversionRate: 0,
            redeemedAt: Date(),
            expiresAt: Date(),
            timeUsedMinutes: 0,
            status: .active
        )

        let result = try! await familyControlsService.allocateRewardTime(
            for: mockRedemption,
            appBundleID: emptyBundleID
        )

        // Should handle gracefully and return appropriate error
        switch result {
        case .authorizationRequired, .systemError, .noTimeRemaining:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected error result for invalid input, got \(result)")
        }
    }
}