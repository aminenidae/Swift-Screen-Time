import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class FeatureGateServiceComprehensiveTests: XCTestCase {
    var featureGateService: FeatureGateService!
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
        
        // Create a mock child profile repository
        let mockChildProfileRepository = MockChildProfileRepository()
        
        featureGateService = FeatureGateService(
            entitlementValidationService: entitlementValidationService,
            childProfileRepository: mockChildProfileRepository
        )
    }

    override func tearDown() async throws {
        featureGateService = nil
        mockEntitlementRepository = nil
        mockFraudDetectionService = nil
        try await super.tearDown()
    }

    // MARK: - Comprehensive Feature Access Tests

    func testCheckFeatureAccessWithAllSubscriptionTiers() async {
        let tiers: [SubscriptionTier] = [.oneChild, .twoChildren, .threeOrMore]
        
        for tier in tiers {
            // Given: Active subscription entitlement with specific tier
            let entitlement = SubscriptionEntitlement(
                id: "test-entitlement-\(tier.rawValue)",
                familyID: "test-family",
                subscriptionTier: tier,
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

            // When: Checking access to all features
            for feature in Feature.allCases {
                let result = await featureGateService.checkFeatureAccess(feature, for: "test-family")
                
                // Then: Should have allowed access for all features with active subscription
                XCTAssertEqual(result, .allowed, "Feature \(feature) should be allowed for tier \(tier)")
            }
        }
    }

    func testCheckFeatureAccessWithGracePeriod() async {
        // Given: Expired subscription but in grace period
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
            gracePeriodExpiresAt: Date().addingTimeInterval(86400 * 5), // 5 days from now
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking feature access
        let result = await featureGateService.checkFeatureAccess(.childProfileCreation, for: "test-family")

        // Then: Should have allowed access during grace period
        XCTAssertEqual(result, .allowed)
    }

    func testCheckFeatureAccessWithExpiredGracePeriod() async {
        // Given: Expired subscription with expired grace period
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
            gracePeriodExpiresAt: Date().addingTimeInterval(-86400), // Expired yesterday
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Checking feature access
        let result = await featureGateService.checkFeatureAccess(.exportReports, for: "test-family")

        // Then: Should be denied due to expired subscription
        XCTAssertEqual(result, .denied(.subscriptionExpired))
    }

    // MARK: - Legacy Method Tests

    func testHasFeatureAccessWithAllPremiumFeatures() async {
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

        // When: Checking access to all premium features
        let unlimitedMembers = await featureGateService.hasFeatureAccess(.unlimitedFamilyMembers, for: "test-family")
        let advancedAnalytics = await featureGateService.hasFeatureAccess(.advancedAnalytics, for: "test-family")

        // Then: Should have access to all premium features
        XCTAssertTrue(unlimitedMembers)
        XCTAssertTrue(advancedAnalytics)
    }

    // MARK: - Feature Access Status Tests

    func testGetFeatureAccessStatusWithActiveSubscription() async {
        // Given: Active subscription entitlement
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

        // When: Getting feature access status
        let status = await featureGateService.getFeatureAccessStatus(for: "test-family")

        // Then: All features should be accessible
        XCTAssertTrue(status.unlimitedFamilyMembers)
        XCTAssertTrue(status.advancedAnalytics)
        XCTAssertTrue(status.smartNotifications)
        XCTAssertTrue(status.enhancedParentalControls)
        XCTAssertTrue(status.cloudSync)
        XCTAssertTrue(status.prioritySupport)
    }

    func testGetFeatureAccessStatusWithNoSubscription() async {
        // Given: No entitlement for family

        // When: Getting feature access status
        let status = await featureGateService.getFeatureAccessStatus(for: "test-family")

        // Then: No features should be accessible
        XCTAssertFalse(status.unlimitedFamilyMembers)
        XCTAssertFalse(status.advancedAnalytics)
        XCTAssertFalse(status.smartNotifications)
        XCTAssertFalse(status.enhancedParentalControls)
        XCTAssertFalse(status.cloudSync)
        XCTAssertFalse(status.prioritySupport)
    }

    // MARK: - Access Status Message Tests

    func testGetAccessStatusMessageWithActiveSubscription() async {
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

        // When: Getting access status message
        let message = await featureGateService.getAccessStatusMessage(for: "test-family")

        // Then: Should contain subscription active message
        XCTAssertTrue(message.contains("Premium subscription"))
        XCTAssertTrue(message.contains("active until"))
    }

    func testGetAccessStatusMessageWithGracePeriod() async {
        // Given: Expired subscription but in grace period
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
            gracePeriodExpiresAt: Date().addingTimeInterval(86400 * 3), // 3 days from now
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Getting access status message
        let message = await featureGateService.getAccessStatusMessage(for: "test-family")

        // Then: Should contain grace period message
        XCTAssertTrue(message.contains("Subscription in grace period"))
        XCTAssertTrue(message.contains("days remaining"))
    }

    // MARK: - Trial Days Remaining Tests

    func testGetTrialDaysRemainingWithActiveTrial() async {
        // Given: Subscription entitlement with active trial
        let trialEndDate = Date().addingTimeInterval(86400 * 7) // 7 days from now
        let entitlement = SubscriptionEntitlement(
            id: "test-entitlement",
            familyID: "test-family",
            subscriptionTier: .oneChild,
            receiptData: "test-receipt",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400), // 1 day ago
            expirationDate: trialEndDate,
            isActive: true,
            isInTrial: true,
            autoRenewStatus: true,
            lastValidatedAt: Date(),
            gracePeriodExpiresAt: nil,
            metadata: [:]
        )
        mockEntitlementRepository.entitlements["test-family"] = entitlement

        // When: Getting trial days remaining
        let daysRemaining = await featureGateService.getTrialDaysRemaining(for: "test-family")

        // Then: Should return correct number of days
        XCTAssertEqual(daysRemaining, 7)
    }

    func testGetTrialDaysRemainingWithNoTrial() async {
        // Given: Subscription entitlement without trial
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

        // When: Getting trial days remaining
        let daysRemaining = await featureGateService.getTrialDaysRemaining(for: "test-family")

        // Then: Should return nil
        XCTAssertNil(daysRemaining)
    }

    // MARK: - Refresh Access Tests

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
        _ = await featureGateService.checkFeatureAccess(.advancedAnalytics, for: "test-family")
        await featureGateService.refreshAccess(for: "test-family")
        _ = await featureGateService.checkFeatureAccess(.exportReports, for: "test-family")

        // Then: Repository should be called twice (cache cleared by refresh)
        XCTAssertEqual(mockEntitlementRepository.callCount, 2)
    }

    // MARK: - Extension Method Tests

    func testCanAddFamilyMemberWithActiveSubscription() async {
        // Given: Active subscription entitlement with 2 children tier
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

        // When: Checking if can add family member with 1 current member
        let canAdd = await featureGateService.canAddFamilyMember(for: "test-family", currentMemberCount: 1)

        // Then: Should be able to add (within limit)
        XCTAssertTrue(canAdd)
    }

    func testCanAccessAnalyticsWithActiveSubscription() async {
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

        // When: Checking if can access analytics
        let canAccess = await featureGateService.canAccessAnalytics(for: "test-family")

        // Then: Should be able to access analytics
        XCTAssertTrue(canAccess)
    }

    func testCanUseEnhancedControlsWithActiveSubscription() async {
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

        // When: Checking if can use enhanced controls
        let canUse = await featureGateService.canUseEnhancedControls(for: "test-family")

        // Then: Should be able to use enhanced controls
        XCTAssertTrue(canUse)
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
    func detectFraud(for entitlement: SubscriptionEntitlement, deviceInfo: [String: String]) async throws -> [FraudDetectionEvent] {
        return []
    }

    func isJailbroken() -> Bool {
        return false
    }

    func validateReceiptIntegrity(_ receiptData: String) -> Bool {
        return true
    }
}

// MARK: - Mock Child Profile Repository

@available(iOS 15.0, macOS 12.0, *)
fileprivate class MockChildProfileRepository: ChildProfileRepository {
    var childProfiles: [String: ChildProfile] = [:]
    
    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        childProfiles[child.id] = child
        return child
    }
    
    func fetchChild(id: String) async throws -> ChildProfile? {
        return childProfiles[id]
    }
    
    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        return childProfiles.values.filter { $0.familyID == familyID }
    }
    
    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        childProfiles[child.id] = child
        return child
    }
    
    func deleteChild(id: String) async throws {
        childProfiles.removeValue(forKey: id)
    }
}