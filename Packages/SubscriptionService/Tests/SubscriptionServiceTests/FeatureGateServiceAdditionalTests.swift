import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class FeatureGateServiceAdditionalTests: XCTestCase {
    var featureGateService: FeatureGateService!
    fileprivate var mockEntitlementRepository: MockEntitlementRepository!
    fileprivate var mockFraudDetectionService: MockFraudDetectionService!
    fileprivate var mockChildProfileRepository: MockChildProfileRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockEntitlementRepository = MockEntitlementRepository()
        mockFraudDetectionService = MockFraudDetectionService()
        mockChildProfileRepository = MockChildProfileRepository()
        
        let entitlementValidationService = EntitlementValidationService(
            entitlementRepository: mockEntitlementRepository,
            fraudDetectionService: mockFraudDetectionService
        )
        
        featureGateService = FeatureGateService(
            entitlementValidationService: entitlementValidationService,
            childProfileRepository: mockChildProfileRepository
        )
    }

    override func tearDown() async throws {
        featureGateService = nil
        mockEntitlementRepository = nil
        mockFraudDetectionService = nil
        mockChildProfileRepository = nil
        try await super.tearDown()
    }

    // MARK: - Feature Access Tests

    func testCheckFeatureAccessWithTrialUser() async {
        // Given: Subscription entitlement with trial
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .oneChild,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 13), // 13 days from now
            isActive: true,
            isInTrial: true,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking feature access
        let result = await featureGateService.checkFeatureAccess(Feature.childProfileCreation, for: "test-family")

        // Then: Should have trial access
        XCTAssertEqual(result, FeatureAccessResult.trial)
    }

    func testCheckFeatureAccessWithActiveSubscription() async {
        // Given: Active subscription entitlement
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .twoChildren,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
            isActive: true,
            isInTrial: false,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking feature access
        let result = await featureGateService.checkFeatureAccess(Feature.advancedAnalytics, for: "test-family")

        // Then: Should have allowed access
        XCTAssertEqual(result, FeatureAccessResult.allowed)
    }

    func testCheckFeatureAccessWithExpiredSubscription() async {
        // Given: Expired subscription entitlement
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .oneChild,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400 * 400), // 400 days ago
            expirationDate: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            isActive: false,
            isInTrial: false,
            autoRenewStatus: false,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking feature access
        let result = await featureGateService.checkFeatureAccess(Feature.exportReports, for: "test-family")

        // Then: Should be denied due to expired subscription
        XCTAssertEqual(result, FeatureAccessResult.denied(DeniedReason.subscriptionExpired))
    }

    func testCheckFeatureAccessWithNoEntitlement() async {
        // Given: No entitlement for family

        // When: Checking feature access
        let result = await featureGateService.checkFeatureAccess(Feature.multiParentInvitations, for: "test-family")

        // Then: Should be denied due to no subscription
        XCTAssertEqual(result, FeatureAccessResult.denied(DeniedReason.noSubscription))
    }

    func testCheckFeatureAccessWithError() async {
        // Given: Repository that throws an error
        mockEntitlementRepository.shouldThrowError = true

        // When: Checking feature access
        let result = await featureGateService.checkFeatureAccess(Feature.fullAccess, for: "test-family")

        // Then: Should be denied due to validation error
        XCTAssertEqual(result, FeatureAccessResult.denied(DeniedReason.validationError))
    }

    // MARK: - Child Profile Creation Tests

    func testCanAddChildProfileWithTrialUser() async {
        // Given: Subscription entitlement with trial
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .oneChild,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 13), // 13 days from now
            isActive: true,
            isInTrial: true,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking if can add child profile
        let result = await featureGateService.canAddChildProfile(for: "test-family", currentChildCount: 5)

        // Then: Should have trial access (unlimited during trial)
        XCTAssertEqual(result, FeatureAccessResult.trial)
    }

    func testCanAddChildProfileWithinLimit() async {
        // Given: Active subscription with 2 children tier
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .twoChildren,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
            isActive: true,
            isInTrial: false,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking if can add child profile with 1 current child
        let result = await featureGateService.canAddChildProfile(for: "test-family", currentChildCount: 1)

        // Then: Should be allowed
        XCTAssertEqual(result, FeatureAccessResult.allowed)
    }

    func testCanAddChildProfileExceedingLimit() async {
        // Given: Active subscription with 1 child tier
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .oneChild,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
            isActive: true,
            isInTrial: false,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking if can add child profile with 1 current child (at limit)
        let result = await featureGateService.canAddChildProfile(for: "test-family", currentChildCount: 1)

        // Then: Should be denied due to tier limit exceeded
        XCTAssertEqual(result, FeatureAccessResult.denied(DeniedReason.tierLimitExceeded))
    }

    func testCanAddChildProfileWithThreeOrMoreTier() async {
        // Given: Active subscription with 3+ children tier
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .threeOrMore,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
            isActive: true,
            isInTrial: false,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking if can add child profile with 10 current children
        let result = await featureGateService.canAddChildProfile(for: "test-family", currentChildCount: 10)

        // Then: Should be allowed (unlimited with this tier)
        XCTAssertEqual(result, FeatureAccessResult.allowed)
    }

    // MARK: - Cache Tests

    func testCacheInvalidation() async {
        // Given: Active subscription entitlement
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .twoChildren,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
            isActive: true,
            isInTrial: false,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking feature access twice
        let result1 = await featureGateService.checkFeatureAccess(Feature.advancedAnalytics, for: "test-family")
        let result2 = await featureGateService.checkFeatureAccess(Feature.advancedAnalytics, for: "test-family")

        // Then: Both should be allowed and should use cache for second call
        XCTAssertEqual(result1, FeatureAccessResult.allowed)
        XCTAssertEqual(result2, FeatureAccessResult.allowed)
        XCTAssertEqual(mockEntitlementRepository.callCount, 1) // Should only be called once due to caching
    }

    // MARK: - Refresh Tests

    func testRefreshAccessClearsCache() async {
        // Given: Active subscription entitlement
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .twoChildren,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
            isActive: true,
            isInTrial: false,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking feature access, then refreshing, then checking again
        _ = await featureGateService.checkFeatureAccess(Feature.advancedAnalytics, for: "test-family")
        await featureGateService.refreshAccess(for: "test-family")
        _ = await featureGateService.checkFeatureAccess(Feature.exportReports, for: "test-family")

        // Then: Repository should be called twice (cache cleared by refresh)
        XCTAssertEqual(mockEntitlementRepository.callCount, 2)
    }
}

// MARK: - Mock Classes

@available(iOS 15.0, macOS 12.0, *)
fileprivate class MockEntitlementRepository: SubscriptionEntitlementRepository {
    var entitlements: [String: SubscriptionEntitlement] = [:]
    var callCount = 0
    var shouldThrowError = false

    func createEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        entitlements[entitlement.familyID] = entitlement
        return entitlement
    }

    func fetchEntitlement(id: String) async throws -> SubscriptionEntitlement? {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        return entitlements[id]
    }

    func fetchEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        return entitlements[familyID]
    }

    func fetchEntitlements(for familyID: String) async throws -> [SubscriptionEntitlement] {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        return [entitlements[familyID]].compactMap { $0 }
    }

    func fetchEntitlement(byTransactionID transactionID: String) async throws -> SubscriptionEntitlement? {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        return entitlements.first { $0.value.transactionID == transactionID }?.value
    }

    func fetchEntitlement(byOriginalTransactionID originalTransactionID: String) async throws -> SubscriptionEntitlement? {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        return entitlements.first { $0.value.originalTransactionID == originalTransactionID }?.value
    }

    func updateEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        entitlements[entitlement.familyID] = entitlement
        return entitlement
    }

    func deleteEntitlement(id: String) async throws {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        entitlements.removeValue(forKey: id)
    }

    func validateEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        callCount += 1
        if shouldThrowError {
            throw AppError.unknownError("Test error")
        }
        return entitlements[familyID]
    }
}

@available(iOS 15.0, macOS 12.0, *)
fileprivate class MockFraudDetectionService: FraudDetectionService {
    func detectFraud(for entitlement: SubscriptionEntitlement, deviceInfo: [String : String]) async throws -> [FraudDetectionEvent] {
        return []
    }
    
    func isJailbroken() -> Bool {
        return false
    }
    
    func validateReceiptIntegrity(_ receiptData: String) -> Bool {
        return true
    }
}

@available(iOS 15.0, macOS 12.0, *)
fileprivate class MockChildProfileRepository: ChildProfileRepository {
    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        return child
    }
    
    func fetchChild(id: String) async throws -> ChildProfile? {
        return nil
    }
    
    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        return []
    }
    
    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        return child
    }
    
    func deleteChild(id: String) async throws {
        // No-op
    }
}