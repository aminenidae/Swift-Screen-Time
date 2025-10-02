import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class FeatureGateServiceTests: XCTestCase {
    var featureGateService: FeatureGateService!
    fileprivate var mockFamilyRepository: MockFamilyRepository!
    fileprivate var mockChildProfileRepository: MockChildProfileRepository!
    fileprivate var mockEntitlementRepository: MockEntitlementRepository!
    fileprivate var mockFraudDetectionService: MockFraudDetectionService!

    override func setUp() async throws {
        try await super.setUp()
        mockFamilyRepository = MockFamilyRepository()
        mockChildProfileRepository = MockChildProfileRepository()
        mockEntitlementRepository = MockEntitlementRepository()
        mockFraudDetectionService = MockFraudDetectionService()
        
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
        mockFamilyRepository = nil
        mockChildProfileRepository = nil
        mockEntitlementRepository = nil
        mockFraudDetectionService = nil
        try await super.tearDown()
    }

    func testCheckAccessWithActiveTrial() async {
        // Given: Family with active trial
        let trialStartDate = Date().addingTimeInterval(-86400) // 1 day ago
        let trialEndDate = Date().addingTimeInterval(86400 * 13) // 13 days from now
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true,
            isActive: true
        )
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            subscriptionMetadata: metadata
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking access
        let hasAccess = await featureGateService.checkAccess(for: "test-family")

        // Then: Should have access
        XCTAssertTrue(hasAccess)
        XCTAssertTrue(featureGateService.hasAccess)
    }

    func testCheckAccessWithActiveSubscription() async {
        // Given: Family with active subscription
        let subscriptionStartDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        let subscriptionEndDate = Date().addingTimeInterval(86400 * 335) // ~11 months from now
        let metadata = SubscriptionMetadata(
            hasUsedTrial: true,
            subscriptionStartDate: subscriptionStartDate,
            subscriptionEndDate: subscriptionEndDate,
            isActive: true
        )
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            subscriptionMetadata: metadata
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking access
        let hasAccess = await featureGateService.checkAccess(for: "test-family")

        // Then: Should have access
        XCTAssertTrue(hasAccess)
        XCTAssertTrue(featureGateService.hasAccess)
    }

    func testCheckAccessWithExpiredTrial() async {
        // Given: Family with expired trial
        let trialStartDate = Date().addingTimeInterval(-86400 * 20) // 20 days ago
        let trialEndDate = Date().addingTimeInterval(-86400 * 6) // 6 days ago
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true
        )
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            subscriptionMetadata: metadata
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking access
        let hasAccess = await featureGateService.checkAccess(for: "test-family")

        // Then: Should not have access
        XCTAssertFalse(hasAccess)
        XCTAssertFalse(featureGateService.hasAccess)
    }

    func testCheckAccessWithNoTrialOrSubscription() async {
        // Given: Family with no trial or subscription
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking access
        let hasAccess = await featureGateService.checkAccess(for: "test-family")

        // Then: Should not have access
        XCTAssertFalse(hasAccess)
        XCTAssertFalse(featureGateService.hasAccess)
    }

    func testHasFeatureAccessWithAccess() async {
        // Given: Family with active trial
        let trialStartDate = Date().addingTimeInterval(-86400) // 1 day ago
        let trialEndDate = Date().addingTimeInterval(86400 * 13) // 13 days from now
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true,
            isActive: true
        )
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            subscriptionMetadata: metadata
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking feature access
        let hasUnlimitedMembers = await featureGateService.hasFeatureAccess(.unlimitedFamilyMembers, for: "test-family")
        let hasAdvancedAnalytics = await featureGateService.hasFeatureAccess(.advancedAnalytics, for: "test-family")

        // Then: Should have access to all features
        XCTAssertTrue(hasUnlimitedMembers)
        XCTAssertTrue(hasAdvancedAnalytics)
    }

    func testCanAddFamilyMemberWithFreeLimit() async {
        // Given: Family with no trial or subscription
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking if can add family member with 1 current member
        let canAdd = await featureGateService.canAddFamilyMember(for: "test-family", currentMemberCount: 1)

        // Then: Should be able to add (within free limit)
        XCTAssertTrue(canAdd)
    }

    func testCanAddFamilyMemberExceedingFreeLimit() async {
        // Given: Family with no trial or subscription
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking if can add family member with 2 current members (exceeding free limit)
        let canAdd = await featureGateService.canAddFamilyMember(for: "test-family", currentMemberCount: 2)

        // Then: Should not be able to add (exceeds free limit)
        XCTAssertFalse(canAdd)
    }

    func testGetFeatureAccessStatus() async {
        // Given: Family with active trial
        let trialStartDate = Date().addingTimeInterval(-86400) // 1 day ago
        let trialEndDate = Date().addingTimeInterval(86400 * 13) // 13 days from now
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true,
            isActive: true
        )
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            subscriptionMetadata: metadata
        )
        mockFamilyRepository.families["test-family"] = family

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

    func testGetAccessStatusMessage() async {
        // Given: Family with active trial
        let trialStartDate = Date().addingTimeInterval(-86400) // 1 day ago
        let trialEndDate = Date().addingTimeInterval(86400 * 13) // 13 days from now
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true,
            isActive: true
        )
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            subscriptionMetadata: metadata
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Getting access status message
        let message = await featureGateService.getAccessStatusMessage(for: "test-family")

        // Then: Should contain trial information
        XCTAssertTrue(message.contains("Free trial active"))
        XCTAssertTrue(message.contains("days remaining"))
    }
}

// MARK: - Mock Family Repository

@available(iOS 15.0, macOS 12.0, *)
fileprivate class MockFamilyRepository: FamilyRepository {
    var families: [String: Family] = [:]

    func createFamily(_ family: Family) async throws -> Family {
        families[family.id] = family
        return family
    }

    func fetchFamily(id: String) async throws -> Family? {
        return families[id]
    }

    func fetchFamilies(for userID: String) async throws -> [Family] {
        return Array(families.values.filter { $0.ownerUserID == userID })
    }

    func updateFamily(_ family: Family) async throws -> Family {
        families[family.id] = family
        return family
    }

    func deleteFamily(id: String) async throws {
        families.removeValue(forKey: id)
    }
    
    // MARK: - ChildProfileRepository conformance
    
    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        // Not used in these tests
        return child
    }
    
    func fetchChild(id: String) async throws -> ChildProfile? {
        // Not used in these tests
        return nil
    }
    
    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        // Not used in these tests
        return []
    }
    
    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        // Not used in these tests
        return child
    }
    
    func deleteChild(id: String) async throws {
        // Not used in these tests
    }
}

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