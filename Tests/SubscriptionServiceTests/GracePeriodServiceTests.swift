import XCTest
import Combine
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, macOS 10.15, *)
final class GracePeriodServiceTests: XCTestCase {

    var sut: GracePeriodService!
    var mockEntitlementRepository: MockSubscriptionEntitlementRepository!
    var mockAuditRepository: MockValidationAuditRepository!
    var mockNotificationService: MockBillingNotificationService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockEntitlementRepository = MockSubscriptionEntitlementRepository()
        mockAuditRepository = MockValidationAuditRepository()
        mockNotificationService = MockBillingNotificationService()

        sut = GracePeriodService(
            entitlementRepository: mockEntitlementRepository,
            auditRepository: mockAuditRepository,
            notificationService: mockNotificationService
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockNotificationService = nil
        mockAuditRepository = nil
        mockEntitlementRepository = nil
        super.tearDown()
    }

    // MARK: - Start Grace Period Tests

    func testStartGracePeriod_ValidEntitlement_UpdatesEntitlementAndSchedulesNotifications() async throws {
        // Given
        let entitlement = createValidEntitlement()
        var updatedEntitlement = entitlement
        updatedEntitlement.gracePeriodExpiresAt = Calendar.current.date(byAdding: .day, value: 16, to: Date())
        mockEntitlementRepository.mockUpdatedEntitlement = updatedEntitlement

        // When
        let result = try await sut.startGracePeriod(for: entitlement)

        // Then
        XCTAssertNotNil(result.gracePeriodExpiresAt)
        XCTAssertTrue(result.isActive)
        XCTAssertTrue(mockEntitlementRepository.updateEntitlementCalled)
        XCTAssertTrue(mockAuditRepository.createAuditLogCalled)
        XCTAssertTrue(mockNotificationService.scheduleBillingRetryNotificationCalled)
        XCTAssertTrue(sut.isInGracePeriod)
        XCTAssertEqual(sut.gracePeriodDaysRemaining, 16)
        XCTAssertEqual(sut.billingRetryStatus, .retrying)
    }

    func testStartGracePeriod_EntitlementAlreadyInGracePeriod_ThrowsError() async {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(86400) // Already in grace period

        // When/Then
        do {
            _ = try await sut.startGracePeriod(for: entitlement)
            XCTFail("Expected GracePeriodError.gracePeriodAlreadyActive")
        } catch GracePeriodError.gracePeriodAlreadyActive {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - End Grace Period Tests

    func testEndGracePeriod_BillingResolved_ActivatesEntitlement() async throws {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(86400)

        var resolvedEntitlement = entitlement
        resolvedEntitlement.gracePeriodExpiresAt = nil
        resolvedEntitlement.isActive = true
        mockEntitlementRepository.mockUpdatedEntitlement = resolvedEntitlement

        // When
        let result = try await sut.endGracePeriod(for: entitlement, reason: .billingResolved)

        // Then
        XCTAssertNil(result.gracePeriodExpiresAt)
        XCTAssertTrue(result.isActive)
        XCTAssertTrue(mockEntitlementRepository.updateEntitlementCalled)
        XCTAssertTrue(mockAuditRepository.createAuditLogCalled)
        XCTAssertTrue(mockNotificationService.cancelGracePeriodNotificationsCalled)
        XCTAssertFalse(sut.isInGracePeriod)
        XCTAssertEqual(sut.gracePeriodDaysRemaining, 0)
        XCTAssertEqual(sut.billingRetryStatus, .resolved)
    }

    func testEndGracePeriod_GracePeriodExpired_DeactivatesEntitlement() async throws {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(86400)

        var expiredEntitlement = entitlement
        expiredEntitlement.gracePeriodExpiresAt = nil
        expiredEntitlement.isActive = false
        mockEntitlementRepository.mockUpdatedEntitlement = expiredEntitlement

        // When
        let result = try await sut.endGracePeriod(for: entitlement, reason: .gracePeriodExpired)

        // Then
        XCTAssertNil(result.gracePeriodExpiresAt)
        XCTAssertFalse(result.isActive)
        XCTAssertTrue(mockEntitlementRepository.updateEntitlementCalled)
        XCTAssertTrue(mockAuditRepository.createAuditLogCalled)
        XCTAssertFalse(sut.isInGracePeriod)
        XCTAssertEqual(sut.billingRetryStatus, .failed)
    }

    func testEndGracePeriod_ManualRevocation_DeactivatesEntitlement() async throws {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(86400)

        var revokedEntitlement = entitlement
        revokedEntitlement.gracePeriodExpiresAt = nil
        revokedEntitlement.isActive = false
        mockEntitlementRepository.mockUpdatedEntitlement = revokedEntitlement

        // When
        let result = try await sut.endGracePeriod(for: entitlement, reason: .manualRevocation)

        // Then
        XCTAssertNil(result.gracePeriodExpiresAt)
        XCTAssertFalse(result.isActive)
        XCTAssertTrue(mockEntitlementRepository.updateEntitlementCalled)
        XCTAssertTrue(mockAuditRepository.createAuditLogCalled)
        XCTAssertEqual(sut.billingRetryStatus, .failed)
    }

    func testEndGracePeriod_NoActiveGracePeriod_ThrowsError() async {
        // Given
        let entitlement = createValidEntitlement() // No grace period

        // When/Then
        do {
            _ = try await sut.endGracePeriod(for: entitlement, reason: .billingResolved)
            XCTFail("Expected GracePeriodError.noActiveGracePeriod")
        } catch GracePeriodError.noActiveGracePeriod {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Check Grace Period Status Tests

    func testCheckGracePeriodStatus_NoGracePeriod_ReturnsNotInGracePeriod() async {
        // Given
        let entitlement = createValidEntitlement()

        // When
        let status = await sut.checkGracePeriodStatus(for: entitlement)

        // Then
        switch status {
        case .notInGracePeriod:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .notInGracePeriod, got \(status)")
        }

        XCTAssertFalse(sut.isInGracePeriod)
        XCTAssertEqual(sut.gracePeriodDaysRemaining, 0)
    }

    func testCheckGracePeriodStatus_ActiveGracePeriod_ReturnsActive() async {
        // Given
        var entitlement = createValidEntitlement()
        let gracePeriodExpiry = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        entitlement.gracePeriodExpiresAt = gracePeriodExpiry

        // When
        let status = await sut.checkGracePeriodStatus(for: entitlement)

        // Then
        switch status {
        case .active(let daysRemaining):
            XCTAssertGreaterThanOrEqual(daysRemaining, 9) // Allow for timing variations
            XCTAssertLessThanOrEqual(daysRemaining, 10)
        default:
            XCTFail("Expected .active, got \(status)")
        }

        XCTAssertTrue(sut.isInGracePeriod)
        XCTAssertGreaterThan(sut.gracePeriodDaysRemaining, 0)
    }

    func testCheckGracePeriodStatus_ExpiredGracePeriod_ReturnsExpiredAndEndsGracePeriod() async {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(-3600) // Expired 1 hour ago

        var expiredEntitlement = entitlement
        expiredEntitlement.gracePeriodExpiresAt = nil
        expiredEntitlement.isActive = false
        mockEntitlementRepository.mockUpdatedEntitlement = expiredEntitlement

        // When
        let status = await sut.checkGracePeriodStatus(for: entitlement)

        // Then
        switch status {
        case .expired:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .expired, got \(status)")
        }

        XCTAssertTrue(mockEntitlementRepository.updateEntitlementCalled)
        XCTAssertFalse(sut.isInGracePeriod)
        XCTAssertEqual(sut.gracePeriodDaysRemaining, 0)
    }

    // MARK: - Billing Resolution Tests

    func testHandleBillingResolved_CallsEndGracePeriodWithCorrectReason() async throws {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(86400)

        var resolvedEntitlement = entitlement
        resolvedEntitlement.gracePeriodExpiresAt = nil
        resolvedEntitlement.isActive = true
        mockEntitlementRepository.mockUpdatedEntitlement = resolvedEntitlement

        // When
        let result = try await sut.handleBillingResolved(for: entitlement)

        // Then
        XCTAssertNil(result.gracePeriodExpiresAt)
        XCTAssertTrue(result.isActive)
        XCTAssertTrue(mockNotificationService.cancelGracePeriodNotificationsCalled)
        XCTAssertEqual(sut.billingRetryStatus, .resolved)
    }

    func testRevokeAccess_CallsEndGracePeriodWithManualRevocation() async throws {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(86400)

        var revokedEntitlement = entitlement
        revokedEntitlement.gracePeriodExpiresAt = nil
        revokedEntitlement.isActive = false
        mockEntitlementRepository.mockUpdatedEntitlement = revokedEntitlement

        // When
        let result = try await sut.revokeAccess(for: entitlement)

        // Then
        XCTAssertNil(result.gracePeriodExpiresAt)
        XCTAssertFalse(result.isActive)
        XCTAssertEqual(sut.billingRetryStatus, .failed)
    }

    // MARK: - Published Properties Tests

    func testPublishedProperties_InitialState() {
        XCTAssertFalse(sut.isInGracePeriod)
        XCTAssertEqual(sut.gracePeriodDaysRemaining, 0)
        XCTAssertNil(sut.gracePeriodExpiry)
        XCTAssertEqual(sut.billingRetryStatus, .none)
    }

    func testPublishedProperties_UpdateOnGracePeriodStart() async throws {
        // Given
        let entitlement = createValidEntitlement()
        var updatedEntitlement = entitlement
        updatedEntitlement.gracePeriodExpiresAt = Calendar.current.date(byAdding: .day, value: 16, to: Date())
        mockEntitlementRepository.mockUpdatedEntitlement = updatedEntitlement

        let expectation = XCTestExpectation(description: "Grace period state updated")

        sut.$isInGracePeriod
            .dropFirst() // Skip initial false state
            .sink { isInGracePeriod in
                if isInGracePeriod {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        _ = try await sut.startGracePeriod(for: entitlement)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(sut.isInGracePeriod)
        XCTAssertGreaterThan(sut.gracePeriodDaysRemaining, 0)
        XCTAssertNotNil(sut.gracePeriodExpiry)
    }

    // MARK: - Helper Methods

    private func createValidEntitlement() -> SubscriptionEntitlement {
        return SubscriptionEntitlement(
            id: UUID().uuidString,
            familyID: "test-family",
            subscriptionTier: .oneChild,
            receiptData: "valid-receipt-data",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400),
            expirationDate: Date().addingTimeInterval(86400),
            isActive: true
        )
    }
}

// MARK: - Mock Classes

class MockBillingNotificationService: BillingNotificationService {
    var scheduleBillingRetryNotificationCalled = false
    var cancelGracePeriodNotificationsCalled = false
    var sendImmediateBillingAlertCalled = false

    func scheduleBillingRetryNotification(
        familyID: String,
        daysRemaining: Int,
        scheduledDate: Date,
        isUrgent: Bool
    ) async throws {
        scheduleBillingRetryNotificationCalled = true
    }

    func cancelGracePeriodNotifications(familyID: String) async {
        cancelGracePeriodNotificationsCalled = true
    }

    func sendImmediateBillingAlert(familyID: String, message: String) async throws {
        sendImmediateBillingAlertCalled = true
    }
}