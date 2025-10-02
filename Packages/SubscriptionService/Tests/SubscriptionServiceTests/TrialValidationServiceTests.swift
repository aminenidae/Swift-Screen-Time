import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class TrialValidationServiceTests: XCTestCase {
    var validationService: TrialValidationService!
    fileprivate var mockFamilyRepository: MockFamilyRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockFamilyRepository = MockFamilyRepository()
        validationService = TrialValidationService(familyRepository: mockFamilyRepository)
    }

    override func tearDown() async throws {
        validationService = nil
        mockFamilyRepository = nil
        try await super.tearDown()
    }

    func testValidateTrialStatusForValidFamily() async {
        // Given: Family with valid trial metadata
        let trialStartDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: trialStartDate)! // 14 days from start
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

        // When: Validating trial status
        let result = await validationService.validateTrialStatus(for: "test-family")

        // Then: Should be valid
        switch result {
        case .valid(let issues):
            XCTAssertTrue(issues.isEmpty, "Expected no validation issues")
        case .invalid(let reason):
            XCTFail("Expected valid result, got invalid with reason: \(reason)")
        }
    }

    func testValidateTrialStatusForFamilyNotFound() async {
        // Given: No family in repository
        // When: Validating trial status for non-existent family
        let result = await validationService.validateTrialStatus(for: "non-existent-family")

        // Then: Should be invalid due to family not found
        switch result {
        case .valid:
            XCTFail("Expected invalid result for non-existent family")
        case .invalid(let reason):
            switch reason {
            case .familyNotFound:
                XCTAssertTrue(true, "Correctly identified family not found")
            default:
                XCTFail("Expected familyNotFound reason, got \(reason)")
            }
        }
    }

    func testValidateTrialStatusWithInvalidTrialDuration() async {
        // Given: Family with invalid trial duration (10 days instead of 14)
        let trialStartDate = Date().addingTimeInterval(-86400 * 5) // 5 days ago
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 10, to: trialStartDate)! // 10 days from start
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

        // When: Validating trial status
        let result = await validationService.validateTrialStatus(for: "test-family")

        // Then: Should be invalid due to incorrect trial duration
        switch result {
        case .valid:
            XCTFail("Expected invalid result for incorrect trial duration")
        case .invalid(let reason):
            switch reason {
            case .validationFailure(let issues):
                XCTAssertTrue(issues.contains { issue in
                    if case .invalidTrialDuration = issue {
                        return true
                    }
                    return false
                })
            default:
                XCTFail("Expected validation failure, got \(reason)")
            }
        }
    }

    func testValidateTrialActivationApproved() async {
        // Given: Valid family that hasn't used trial
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        mockFamilyRepository.families["test-family"] = family

        let clientInfo = ClientInfo(
            deviceID: "device-123",
            appVersion: "1.0.0",
            osVersion: "iOS 15.0",
            buildNumber: "1"
        )

        let request = TrialActivationRequest(
            familyID: "test-family",
            userID: "user1",
            clientInfo: clientInfo
        )

        // When: Validating trial activation
        let result = await validationService.validateTrialActivation(request)

        // Then: Should be approved
        switch result {
        case .approved:
            XCTAssertTrue(true, "Trial activation correctly approved")
        case .denied(let reasons):
            XCTFail("Expected approval, got denial with reasons: \(reasons)")
        }
    }

    func testValidateTrialActivationDeniedForUsedTrial() async {
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

        let clientInfo = ClientInfo(
            deviceID: "device-123",
            appVersion: "1.0.0",
            osVersion: "iOS 15.0",
            buildNumber: "1"
        )

        let request = TrialActivationRequest(
            familyID: "test-family",
            userID: "user1",
            clientInfo: clientInfo
        )

        // When: Validating trial activation
        let result = await validationService.validateTrialActivation(request)

        // Then: Should be denied
        switch result {
        case .approved:
            XCTFail("Expected denial for family that already used trial")
        case .denied(let reasons):
            XCTAssertTrue(reasons.contains("Trial already used"))
        }
    }

    func testDetectTrialBypassNoSuspiciousActivity() async {
        // Given: Family with normal trial data
        let trialStartDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: trialStartDate)!
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

        // When: Detecting bypass attempts
        let result = await validationService.detectTrialBypass(for: "test-family")

        // Then: Should detect no bypass
        switch result {
        case .noBypassDetected:
            XCTAssertTrue(true, "Correctly detected no bypass")
        case .bypassDetected(let activities):
            XCTFail("Unexpected bypass detection: \(activities)")
        case .error(let message):
            XCTFail("Unexpected error: \(message)")
        }
    }

    func testDetectTrialBypassWithImpossibleDates() async {
        // Given: Family with impossible trial dates (end before start)
        let trialStartDate = Date()
        let trialEndDate = Date().addingTimeInterval(-86400) // 1 day before start
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

        // When: Detecting bypass attempts
        let result = await validationService.detectTrialBypass(for: "test-family")

        // Then: Should detect bypass due to impossible dates
        switch result {
        case .noBypassDetected:
            XCTFail("Expected bypass detection for impossible dates")
        case .bypassDetected(let activities):
            XCTAssertTrue(activities.contains { activity in
                if case .impossibleTrialDates = activity {
                    return true
                }
                return false
            })
        case .error(let message):
            XCTFail("Unexpected error: \(message)")
        }
    }

    func testDetectTrialBypassWithFutureStartDate() async {
        // Given: Family with future trial start date
        let trialStartDate = Date().addingTimeInterval(86400) // 1 day in future
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: trialStartDate)!
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

        // When: Detecting bypass attempts
        let result = await validationService.detectTrialBypass(for: "test-family")

        // Then: Should detect bypass due to future start date
        switch result {
        case .noBypassDetected:
            XCTFail("Expected bypass detection for future start date")
        case .bypassDetected(let activities):
            XCTAssertTrue(activities.contains { activity in
                if case .futureTrialStartDate = activity {
                    return true
                }
                return false
            })
        case .error(let message):
            XCTFail("Unexpected error: \(message)")
        }
    }

    func testGetAuditLogReturnsEmptyArray() async {
        // Given: Any family ID
        let familyID = "test-family"

        // When: Getting audit log
        let auditLog = await validationService.getAuditLog(for: familyID)

        // Then: Should return empty array (placeholder implementation)
        XCTAssertTrue(auditLog.isEmpty, "Audit log should be empty in placeholder implementation")
    }

    func testTrialValidationServiceInitialization() {
        // Given: TrialValidationService
        // When: Service is initialized
        // Then: Should not be nil and loading should be false initially
        XCTAssertNotNil(validationService)
        XCTAssertFalse(validationService.isLoading)
        XCTAssertNil(validationService.error)
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