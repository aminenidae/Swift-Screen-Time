import XCTest
import Combine
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, macOS 10.15, *)
final class EntitlementValidationServiceTests: XCTestCase {

    var sut: EntitlementValidationService!
    var mockRepository: MockSubscriptionEntitlementRepository!
    var mockFraudService: MockFraudDetectionService!
    var mockUserDefaults: UserDefaults!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockSubscriptionEntitlementRepository()
        mockFraudService = MockFraudDetectionService()
        mockUserDefaults = UserDefaults(suiteName: "test")
        sut = EntitlementValidationService(
            entitlementRepository: mockRepository,
            fraudDetectionService: mockFraudService,
            userDefaults: mockUserDefaults
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockFraudService = nil
        mockRepository = nil
        mockUserDefaults?.removePersistentDomain(forName: "test")
        mockUserDefaults = nil
        super.tearDown()
    }

    // MARK: - Validation Tests

    func testValidateEntitlement_ValidEntitlement_ReturnsEntitlement() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)
        mockRepository.mockEntitlement = entitlement

        // When
        let result = try await sut.validateEntitlement(for: familyID)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.familyID, familyID)
        XCTAssertTrue(mockRepository.validateEntitlementCalled)
    }

    func testValidateEntitlement_NoEntitlement_ThrowsError() async {
        // Given
        let familyID = "test-family"
        mockRepository.mockEntitlement = nil

        // When/Then
        do {
            _ = try await sut.validateEntitlement(for: familyID)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is EntitlementValidationError)
        }
    }

    func testValidateEntitlement_CachedValidEntitlement_ReturnsCachedResult() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)

        // Cache the entitlement
        let encoder = JSONEncoder()
        let data = try encoder.encode(entitlement)
        mockUserDefaults.set(data, forKey: "lastKnownEntitlement")
        mockUserDefaults.set(Date().addingTimeInterval(1800), forKey: "lastValidationDate") // 30 minutes ago

        // When
        let result = try await sut.validateEntitlement(for: familyID)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.familyID, familyID)
        XCTAssertFalse(mockRepository.validateEntitlementCalled) // Should use cache
    }

    // MARK: - Active Entitlement Tests

    func testHasActiveEntitlement_ValidActiveEntitlement_ReturnsTrue() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)
        mockRepository.mockEntitlement = entitlement

        _ = try await sut.validateEntitlement(for: familyID)

        // When
        let hasActive = sut.hasActiveEntitlement(for: familyID)

        // Then
        XCTAssertTrue(hasActive)
    }

    func testHasActiveEntitlement_ExpiredEntitlement_ReturnsFalse() async throws {
        // Given
        let familyID = "test-family"
        var entitlement = createValidEntitlement(familyID: familyID)
        entitlement.expirationDate = Date().addingTimeInterval(-3600) // Expired 1 hour ago
        mockRepository.mockEntitlement = entitlement

        _ = try await sut.validateEntitlement(for: familyID)

        // When
        let hasActive = sut.hasActiveEntitlement(for: familyID)

        // Then
        XCTAssertFalse(hasActive)
    }

    func testHasActiveEntitlement_InactiveEntitlement_ReturnsFalse() async throws {
        // Given
        let familyID = "test-family"
        var entitlement = createValidEntitlement(familyID: familyID)
        entitlement.isActive = false
        mockRepository.mockEntitlement = entitlement

        _ = try await sut.validateEntitlement(for: familyID)

        // When
        let hasActive = sut.hasActiveEntitlement(for: familyID)

        // Then
        XCTAssertFalse(hasActive)
    }

    // MARK: - Grace Period Tests

    func testCheckGracePeriodStatus_NoGracePeriod_ReturnsNotApplicable() async throws {
        // Given
        let entitlement = createValidEntitlement(familyID: "test")

        // When
        let status = sut.checkGracePeriodStatus(for: entitlement)

        // Then
        switch status {
        case .notApplicable:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected notApplicable status")
        }
    }

    func testCheckGracePeriodStatus_ActiveGracePeriod_ReturnsActive() async throws {
        // Given
        var entitlement = createValidEntitlement(familyID: "test")
        entitlement.expirationDate = Date().addingTimeInterval(-3600) // Expired
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(86400) // Expires tomorrow

        // When
        let status = sut.checkGracePeriodStatus(for: entitlement)

        // Then
        switch status {
        case .active(let daysRemaining):
            XCTAssertGreaterThan(daysRemaining, 0)
        default:
            XCTFail("Expected active grace period")
        }
    }

    func testCheckGracePeriodStatus_ExpiredGracePeriod_ReturnsExpired() async throws {
        // Given
        var entitlement = createValidEntitlement(familyID: "test")
        entitlement.expirationDate = Date().addingTimeInterval(-7200) // Expired 2 hours ago
        entitlement.gracePeriodExpiresAt = Date().addingTimeInterval(-3600) // Grace period expired 1 hour ago

        // When
        let status = sut.checkGracePeriodStatus(for: entitlement)

        // Then
        switch status {
        case .expired:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected expired grace period")
        }
    }

    func testStartGracePeriod_ValidEntitlement_ReturnsUpdatedEntitlement() async throws {
        // Given
        let entitlement = createValidEntitlement(familyID: "test")
        mockRepository.mockUpdatedEntitlement = entitlement

        // When
        let result = try await sut.startGracePeriod(for: entitlement)

        // Then
        XCTAssertNotNil(result.gracePeriodExpiresAt)
        XCTAssertTrue(mockRepository.updateEntitlementCalled)
    }

    // MARK: - Refresh Tests

    func testRefreshEntitlement_ClearsCache_FetchesFreshData() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)
        mockRepository.mockEntitlement = entitlement

        // Set up cache
        let encoder = JSONEncoder()
        let data = try encoder.encode(entitlement)
        mockUserDefaults.set(data, forKey: "lastKnownEntitlement")

        // When
        let result = try await sut.refreshEntitlement(for: familyID)

        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockRepository.validateEntitlementCalled)
        XCTAssertNil(mockUserDefaults.data(forKey: "lastKnownEntitlement"))
    }

    // MARK: - Helper Methods

    private func createValidEntitlement(familyID: String) -> SubscriptionEntitlement {
        return SubscriptionEntitlement(
            id: UUID().uuidString,
            familyID: familyID,
            subscriptionTier: .oneChild,
            receiptData: "valid-receipt-data",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // Yesterday
            expirationDate: Date().addingTimeInterval(86400), // Tomorrow
            isActive: true,
            isInTrial: false,
            autoRenewStatus: true
        )
    }
}

// MARK: - Mock Classes

class MockSubscriptionEntitlementRepository: SubscriptionEntitlementRepository {
    var mockEntitlement: SubscriptionEntitlement?
    var mockUpdatedEntitlement: SubscriptionEntitlement?
    var validateEntitlementCalled = false
    var updateEntitlementCalled = false

    func createEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        return entitlement
    }

    func fetchEntitlement(id: String) async throws -> SubscriptionEntitlement? {
        return mockEntitlement
    }

    func fetchEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        return mockEntitlement
    }

    func fetchEntitlements(for familyID: String) async throws -> [SubscriptionEntitlement] {
        return mockEntitlement.map { [$0] } ?? []
    }

    func fetchEntitlement(byTransactionID transactionID: String) async throws -> SubscriptionEntitlement? {
        return mockEntitlement
    }

    func fetchEntitlement(byOriginalTransactionID originalTransactionID: String) async throws -> SubscriptionEntitlement? {
        return mockEntitlement
    }

    func updateEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        updateEntitlementCalled = true
        return mockUpdatedEntitlement ?? entitlement
    }

    func deleteEntitlement(id: String) async throws {
        // Mock implementation
    }

    func validateEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        validateEntitlementCalled = true
        return mockEntitlement
    }
}

class MockFraudDetectionService: FraudDetectionService {
    var mockFraudEvents: [FraudDetectionEvent] = []

    func detectFraud(for entitlement: SubscriptionEntitlement, deviceInfo: [String: String]) async throws -> [FraudDetectionEvent] {
        return mockFraudEvents
    }

    func isJailbroken() -> Bool {
        return false
    }

    func validateReceiptIntegrity(_ receiptData: String) -> Bool {
        return true
    }
}