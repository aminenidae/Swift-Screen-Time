import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class TrialExpirationServiceTests: XCTestCase {
    var expirationService: TrialExpirationService!
    fileprivate var mockFamilyRepository: MockFamilyRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockFamilyRepository = MockFamilyRepository()
        expirationService = TrialExpirationService(familyRepository: mockFamilyRepository)
    }

    override func tearDown() async throws {
        expirationService = nil
        mockFamilyRepository = nil
        try await super.tearDown()
    }

    func testHandleTrialExpirationForActiveTrialWithDaysRemaining() async {
        // Given: Family with active trial (5 days remaining)
        let trialStartDate = Date().addingTimeInterval(-86400 * 9) // 9 days ago
        let trialEndDate = Date().addingTimeInterval(86400 * 5) // 5 days from now
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

        // When: Handling trial expiration
        let result = await expirationService.handleTrialExpiration(for: "test-family")

        // Then: Should indicate trial is still active
        switch result {
        case .stillActive(let daysRemaining):
            XCTAssertGreaterThan(daysRemaining, 0)
        default:
            XCTFail("Expected .stillActive, got \(result)")
        }
    }

    func testHandleTrialExpirationForExpiredTrial() async {
        // Given: Family with expired trial
        let trialStartDate = Date().addingTimeInterval(-86400 * 20) // 20 days ago
        let trialEndDate = Date().addingTimeInterval(-86400 * 6) // 6 days ago
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true,
            isActive: false
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

        // When: Handling trial expiration
        let result = await expirationService.handleTrialExpiration(for: "test-family")

        // Then: Should indicate trial is already expired
        switch result {
        case .alreadyExpired(let familyID, let featuresLocked):
            XCTAssertEqual(familyID, "test-family")
            XCTAssertTrue(featuresLocked)
        default:
            XCTFail("Expected .alreadyExpired, got \(result)")
        }
    }

    func testHandleTrialExpirationForFamilyWithoutTrial() async {
        // Given: Family without trial
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Handling trial expiration
        let result = await expirationService.handleTrialExpiration(for: "test-family")

        // Then: Should indicate no trial found
        switch result {
        case .noTrialFound:
            XCTAssertTrue(true, "Correctly identified no trial")
        default:
            XCTFail("Expected .noTrialFound, got \(result)")
        }
    }

    func testGetExpirationInfoForActiveTrialFamily() async {
        // Given: Family with active trial
        let trialStartDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        let trialEndDate = Date().addingTimeInterval(86400 * 7) // 7 days from now
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

        // When: Getting expiration info
        let info = await expirationService.getExpirationInfo(for: "test-family")

        // Then: Should return correct expiration info
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.familyID, "test-family")
        XCTAssertFalse(info?.isExpired ?? true)
        XCTAssertTrue(info?.hasUsedTrial ?? false)
        XCTAssertFalse(info?.canStartNewTrial ?? true)
    }

    func testGetExpirationInfoForFamilyWithoutTrial() async {
        // Given: Family without trial
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        // When: Getting expiration info
        let info = await expirationService.getExpirationInfo(for: "test-family")

        // Then: Should return nil
        XCTAssertNil(info)
    }

    func testShouldPresentPaywallForExpiredTrial() async {
        // Given: Family with expired trial
        let trialStartDate = Date().addingTimeInterval(-86400 * 20) // 20 days ago
        let trialEndDate = Date().addingTimeInterval(-86400 * 6) // 6 days ago
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true,
            isActive: false
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

        // When: Checking if should present paywall
        let reason = await expirationService.shouldPresentPaywall(for: "test-family")

        // Then: Should recommend presenting paywall for expired trial
        switch reason {
        case .trialExpired:
            XCTAssertTrue(true, "Correctly identified expired trial")
        default:
            XCTFail("Expected .trialExpired, got \(String(describing: reason))")
        }
    }

    func testShouldPresentPaywallForTrialEndingSoon() async {
        // Given: Family with trial ending tomorrow
        let trialStartDate = Date().addingTimeInterval(-86400 * 13) // 13 days ago
        let trialEndDate = Date().addingTimeInterval(86400) // 1 day from now
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

        // When: Checking if should present paywall
        let reason = await expirationService.shouldPresentPaywall(for: "test-family")

        // Then: Should recommend presenting paywall for trial ending soon
        switch reason {
        case .trialEndingSoon(let daysRemaining):
            XCTAssertLessThanOrEqual(daysRemaining, 1)
        default:
            XCTFail("Expected .trialEndingSoon, got \(String(describing: reason))")
        }
    }

    func testShouldPreserveData() async {
        // Given: Any family ID
        let familyID = "test-family"

        // When: Checking if data should be preserved
        let shouldPreserve = await expirationService.shouldPreserveData(for: familyID)

        // Then: Should always preserve data
        XCTAssertTrue(shouldPreserve)
    }

    func testGetFeatureLockoutStatusForExpiredTrial() async {
        // Given: Family with expired trial
        let trialStartDate = Date().addingTimeInterval(-86400 * 20) // 20 days ago
        let trialEndDate = Date().addingTimeInterval(-86400 * 6) // 6 days ago
        let metadata = SubscriptionMetadata(
            trialStartDate: trialStartDate,
            trialEndDate: trialEndDate,
            hasUsedTrial: true,
            isActive: false
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

        // When: Getting feature lockout status
        let status = await expirationService.getFeatureLockoutStatus(for: "test-family")

        // Then: Should indicate no access and locked features
        XCTAssertEqual(status.familyID, "test-family")
        XCTAssertFalse(status.hasAccess)
        XCTAssertGreaterThan(status.lockedFeatures.count, 0)
        XCTAssertFalse(status.accessStatusMessage.isEmpty)
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