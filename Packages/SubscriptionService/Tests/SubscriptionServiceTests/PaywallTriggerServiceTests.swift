import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class PaywallTriggerServiceTests: XCTestCase {
    var paywallTriggerService: PaywallTriggerService!
    fileprivate var mockEntitlementRepository: MockEntitlementRepository!
    fileprivate var mockFraudDetectionService: MockFraudDetectionService!

    override func setUp() async throws {
        try await super.setUp()
        mockEntitlementRepository = MockEntitlementRepository()
        mockFraudDetectionService = MockFraudDetectionService()
        
        let entitlementValidationService = EntitlementValidationService(
            entitlementRepository: mockEntitlementRepository,
            fraudDetectionService: mockFraudDetectionService
        )
        
        // Create a new FeatureGateService with our mock services
        let childProfileRepository = MockChildProfileRepository()
        let featureGateService = FeatureGateService(
            entitlementValidationService: entitlementValidationService,
            childProfileRepository: childProfileRepository
        )
        
        // Since PaywallTriggerService uses the shared instance, we need to use it directly
        // This is a limitation of the current design, but we'll test what we can
        paywallTriggerService = PaywallTriggerService.shared
    }

    override func tearDown() async throws {
        paywallTriggerService = nil
        mockEntitlementRepository = nil
        mockFraudDetectionService = nil
        try await super.tearDown()
    }

    // MARK: - Child Limit Paywall Tests

    func testTriggerChildLimitPaywallWithTierLimitExceeded() async {
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

        // When: Triggering child limit paywall with 1 current child (at limit)
        let shouldShowPaywall = await paywallTriggerService.triggerChildLimitPaywall(for: "test-family", currentChildCount: 1)

        // Then: Should show paywall
        XCTAssertTrue(shouldShowPaywall)
        XCTAssertEqual(paywallTriggerService.paywallContext, PaywallContext.childLimitExceeded(currentCount: 1))
        XCTAssertTrue(paywallTriggerService.shouldShowPaywall)
    }

    func testTriggerChildLimitPaywallWithinLimit() async {
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

        // When: Triggering child limit paywall with 1 current child (within limit)
        let shouldShowPaywall = await paywallTriggerService.triggerChildLimitPaywall(for: "test-family", currentChildCount: 1)

        // Then: Should not show paywall
        XCTAssertFalse(shouldShowPaywall)
        XCTAssertNil(paywallTriggerService.paywallContext)
        XCTAssertFalse(paywallTriggerService.shouldShowPaywall)
    }

    // MARK: - Analytics Paywall Tests

    func testTriggerAnalyticsPaywallWithNoSubscription() async {
        // Given: No entitlement for family

        // When: Triggering analytics paywall
        let shouldShowPaywall = await paywallTriggerService.triggerAnalyticsPaywall(for: "test-family")

        // Then: Should show paywall
        XCTAssertTrue(shouldShowPaywall)
        XCTAssertEqual(paywallTriggerService.paywallContext, PaywallContext.noSubscription)
        XCTAssertTrue(paywallTriggerService.shouldShowPaywall)
    }

    func testTriggerAnalyticsPaywallWithActiveSubscription() async {
        // Given: Active subscription entitlement
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

        // When: Triggering analytics paywall
        let shouldShowPaywall = await paywallTriggerService.triggerAnalyticsPaywall(for: "test-family")

        // Then: Should not show paywall (all subscription tiers get analytics)
        XCTAssertFalse(shouldShowPaywall)
        XCTAssertNil(paywallTriggerService.paywallContext)
        XCTAssertFalse(paywallTriggerService.shouldShowPaywall)
    }

    // MARK: - Export Reports Paywall Tests

    func testTriggerExportReportsPaywallWithActiveSubscription() async {
        // Given: Active subscription entitlement
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

        // When: Triggering export reports paywall
        let shouldShowPaywall = await paywallTriggerService.triggerExportReportsPaywall(for: "test-family")

        // Then: Should not show paywall (all subscription tiers get export)
        XCTAssertFalse(shouldShowPaywall)
        XCTAssertNil(paywallTriggerService.paywallContext)
        XCTAssertFalse(paywallTriggerService.shouldShowPaywall)
    }

    // MARK: - Trial Expiration Paywall Tests

    func testTriggerTrialExpirationPaywall() async {
        // When: Triggering trial expiration paywall
        let shouldShowPaywall = await paywallTriggerService.triggerTrialExpirationPaywall(for: "test-family")

        // Then: Should show paywall
        XCTAssertTrue(shouldShowPaywall)
        XCTAssertEqual(paywallTriggerService.paywallContext, PaywallContext.trialExpiration)
        XCTAssertTrue(paywallTriggerService.shouldShowPaywall)
    }

    // MARK: - Re-subscribe Paywall Tests

    func testTriggerReSubscribePaywall() async {
        // When: Triggering re-subscribe paywall
        let shouldShowPaywall = await paywallTriggerService.triggerReSubscribePaywall(for: "test-family")

        // Then: Should show paywall
        XCTAssertTrue(shouldShowPaywall)
        XCTAssertEqual(paywallTriggerService.paywallContext, PaywallContext.reSubscribe)
        XCTAssertTrue(paywallTriggerService.shouldShowPaywall)
    }

    // MARK: - Feature Access Paywall Tests

    func testCheckFeatureAccessAndTriggerPaywallWithAllowedAccess() async {
        // Given: Active subscription entitlement
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

        // When: Checking feature access for a feature that's allowed
        let accessAllowed = await paywallTriggerService.checkFeatureAccessAndTriggerPaywall(Feature.advancedAnalytics, for: "test-family")

        // Then: Should allow access
        XCTAssertTrue(accessAllowed)
        XCTAssertNil(paywallTriggerService.paywallContext)
        XCTAssertFalse(paywallTriggerService.shouldShowPaywall)
    }

    func testCheckFeatureAccessAndTriggerPaywallWithDeniedAccess() async {
        // Given: No entitlement for family

        // When: Checking feature access for any feature
        let accessAllowed = await paywallTriggerService.checkFeatureAccessAndTriggerPaywall(Feature.advancedAnalytics, for: "test-family")

        // Then: Should deny access and show paywall
        XCTAssertFalse(accessAllowed)
        XCTAssertEqual(paywallTriggerService.paywallContext, PaywallContext.noSubscription)
        XCTAssertTrue(paywallTriggerService.shouldShowPaywall)
    }

    // MARK: - Dismiss Paywall Tests

    func testDismissPaywall() async {
        // Given: A paywall is shown
        _ = await paywallTriggerService.triggerTrialExpirationPaywall(for: "test-family")
        XCTAssertTrue(paywallTriggerService.shouldShowPaywall)

        // When: Dismissing the paywall
        paywallTriggerService.dismissPaywall()

        // Then: Paywall should be dismissed
        XCTAssertFalse(paywallTriggerService.shouldShowPaywall)
        XCTAssertNil(paywallTriggerService.paywallContext)
    }
}

// MARK: - Mock Classes (same as in FeatureGateServiceAdditionalTests)

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