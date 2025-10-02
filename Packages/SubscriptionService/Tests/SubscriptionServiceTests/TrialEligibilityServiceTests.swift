import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class TrialEligibilityServiceTests: XCTestCase {
    var trialService: TrialEligibilityService!
    fileprivate var mockFamilyRepository: MockFamilyRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockFamilyRepository = MockFamilyRepository()
        trialService = TrialEligibilityService(familyRepository: mockFamilyRepository)
    }

    override func tearDown() async throws {
        trialService = nil
        mockFamilyRepository = nil
        try await super.tearDown()
    }

    func testCheckTrialEligibilityForNewFamily() async {
        // Given: New family with no subscription metadata
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Checking trial eligibility
        let result = await trialService.checkTrialEligibility(for: "test-family")

        // Then: Should be eligible
        switch result {
        case .eligible:
            XCTAssertTrue(true, "Family should be eligible for trial")
        case .ineligible(let reason):
            XCTFail("Family should be eligible, but got ineligible with reason: \(reason)")
        }
    }

    func testCheckTrialEligibilityForFamilyWithUsedTrial() async {
        // Given: Family that has already used trial
        let metadata = SubscriptionMetadata(hasUsedTrial: true)
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

        // When: Checking trial eligibility
        let result = await trialService.checkTrialEligibility(for: "test-family")

        // Then: Should be ineligible
        switch result {
        case .eligible:
            XCTFail("Family should not be eligible for trial")
        case .ineligible(let reason):
            XCTAssertEqual(reason, .trialPreviouslyUsed)
        }
    }

    func testCheckTrialEligibilityForFamilyWithActiveSubscription() async {
        // Given: Family with active subscription
        let metadata = SubscriptionMetadata(isActive: true)
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

        // When: Checking trial eligibility
        let result = await trialService.checkTrialEligibility(for: "test-family")

        // Then: Should be ineligible
        switch result {
        case .eligible:
            XCTFail("Family should not be eligible for trial")
        case .ineligible(let reason):
            XCTAssertEqual(reason, .activeSubscription)
        }
    }

    func testActivateTrialForEligibleFamily() async {
        // Given: Eligible family
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Activating trial
        let result = await trialService.activateTrial(for: "test-family")

        // Then: Should succeed
        switch result {
        case .success(let trialStartDate, let trialEndDate, let updatedFamily):
            XCTAssertNotNil(trialStartDate)
            XCTAssertNotNil(trialEndDate)
            XCTAssertTrue(updatedFamily.subscriptionMetadata?.hasUsedTrial ?? false)
            XCTAssertTrue(updatedFamily.subscriptionMetadata?.isActive ?? false)

            // Verify trial period is 14 days
            let daysDifference = Calendar.current.dateComponents([.day], from: trialStartDate, to: trialEndDate).day
            XCTAssertEqual(daysDifference, 14)

        case .failed(let reason):
            XCTFail("Trial activation should succeed, but failed with reason: \(reason)")
        }
    }

    func testActivateTrialForIneligibleFamily() async {
        // Given: Family that has already used trial
        let metadata = SubscriptionMetadata(hasUsedTrial: true)
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

        // When: Activating trial
        let result = await trialService.activateTrial(for: "test-family")

        // Then: Should fail
        switch result {
        case .success:
            XCTFail("Trial activation should fail for ineligible family")
        case .failed(let reason):
            XCTAssertEqual(reason, .notEligible)
        }
    }

    func testGetTrialStatusNotStarted() async {
        // Given: Family with no trial
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Getting trial status
        let status = await trialService.getTrialStatus(for: "test-family")

        // Then: Should be not started
        switch status {
        case .notStarted:
            XCTAssertTrue(true, "Trial status should be not started")
        default:
            XCTFail("Expected .notStarted, got \(status)")
        }
    }

    func testGetTrialStatusActive() async {
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

        // When: Getting trial status
        let status = await trialService.getTrialStatus(for: "test-family")

        // Then: Should be active
        switch status {
        case .active(let daysRemaining):
            XCTAssertGreaterThan(daysRemaining, 0)
            XCTAssertLessThanOrEqual(daysRemaining, 14)
        default:
            XCTFail("Expected .active, got \(status)")
        }
    }

    func testGetTrialStatusExpired() async {
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

        // When: Getting trial status
        let status = await trialService.getTrialStatus(for: "test-family")

        // Then: Should be expired
        switch status {
        case .expired:
            XCTAssertTrue(true, "Trial status should be expired")
        default:
            XCTFail("Expected .expired, got \(status)")
        }
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
}