import XCTest
import CloudKit
@testable import RewardCore
@testable import SharedModels
@testable import CloudKitService
@testable import TestUtilities

@available(iOS 15.0, macOS 12.0, *)
final class FamilyInvitationServiceTests: XCTestCase {
    var service: FamilyInvitationService!
    var mockInvitationRepository: MockFamilyInvitationRepository!
    var mockFamilyRepository: MockFamilyRepository!
    var mockCloudKitSharingService: MockCloudKitSharingService!
    var validationService: FamilyInvitationValidationService!

    override func setUp() {
        super.setUp()
        mockInvitationRepository = MockFamilyInvitationRepository()
        mockFamilyRepository = MockFamilyRepository()
        mockCloudKitSharingService = MockCloudKitSharingService()
        validationService = FamilyInvitationValidationService()

        service = FamilyInvitationService(
            familyInvitationRepository: mockInvitationRepository,
            familyRepository: mockFamilyRepository,
            cloudKitSharingService: mockCloudKitSharingService,
            validationService: validationService
        )
    }

    override func tearDown() {
        service = nil
        mockInvitationRepository = nil
        mockFamilyRepository = nil
        mockCloudKitSharingService = nil
        validationService = nil
        super.tearDown()
    }

    // MARK: - Create Invitation Tests

    func testCreateInvitation_Success() async throws {
        // Given
        let familyID = "family-123"
        let ownerUserID = "owner-456"
        let family = createMockFamily(id: familyID, ownerUserID: ownerUserID, sharedWithUserIDs: [])

        mockFamilyRepository.families[familyID] = family

        // When
        let invitation = try await service.createInvitation(
            familyID: familyID,
            invitingUserID: ownerUserID
        )

        // Then
        XCTAssertEqual(invitation.familyID, familyID)
        XCTAssertEqual(invitation.invitingUserID, ownerUserID)
        XCTAssertFalse(invitation.isUsed)
        XCTAssertTrue(invitation.deepLinkURL.hasPrefix("screentimerewards://invite/"))
        XCTAssertGreaterThan(invitation.expiresAt, Date())
    }

    func testCreateInvitation_NotFamilyOwner_ThrowsError() async {
        // Given
        let familyID = "family-123"
        let ownerUserID = "owner-456"
        let notOwnerUserID = "not-owner-789"
        let family = createMockFamily(id: familyID, ownerUserID: ownerUserID, sharedWithUserIDs: [])

        mockFamilyRepository.families[familyID] = family

        // When & Then
        do {
            _ = try await service.createInvitation(
                familyID: familyID,
                invitingUserID: notOwnerUserID
            )
            XCTFail("Expected error to be thrown")
        } catch let error as InvitationValidationError {
            // Check that the error is the expected type
            if case .notFamilyOwner = error {
                // Success - expected error
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testCreateInvitation_FamilyFull_ThrowsError() async {
        // Given
        let familyID = "family-123"
        let ownerUserID = "owner-456"
        let family = createMockFamily(
            id: familyID,
            ownerUserID: ownerUserID,
            sharedWithUserIDs: ["coparent-1"] // Already has 1 co-parent (max is 2 total)
        )

        mockFamilyRepository.families[familyID] = family

        // When & Then
        do {
            _ = try await service.createInvitation(
                familyID: familyID,
                invitingUserID: ownerUserID
            )
            XCTFail("Expected error to be thrown")
        } catch let error as InvitationValidationError {
            // Check that the error is the expected type
            if case .familyMemberLimitReached(let current, let maximum) = error {
                XCTAssertEqual(current, 2)
                XCTAssertEqual(maximum, 2)
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testCreateInvitation_FamilyNotFound_ThrowsError() async {
        // Given
        let familyID = "nonexistent-family"
        let ownerUserID = "owner-456"

        // When & Then
        do {
            _ = try await service.createInvitation(
                familyID: familyID,
                invitingUserID: ownerUserID
            )
            XCTFail("Expected error to be thrown")
        } catch let error as InvitationError {
            XCTAssertEqual(error, .familyNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Accept Invitation Tests

    func testAcceptInvitation_Success() async throws {
        // Given
        let familyID = "family-123"
        let ownerUserID = "owner-456"
        let acceptingUserID = "accepter-789"
        let token = UUID()

        let family = createMockFamily(id: familyID, ownerUserID: ownerUserID, sharedWithUserIDs: [])
        let invitation = createMockInvitation(
            familyID: familyID,
            invitingUserID: ownerUserID,
            token: token,
            isUsed: false,
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )

        mockFamilyRepository.families[familyID] = family
        mockInvitationRepository.invitations[token] = invitation

        // When
        let result = try await service.validateAndAcceptInvitation(
            token: token,
            acceptingUserID: acceptingUserID
        )

        // Then
        XCTAssertEqual(result.family.id, familyID)
        XCTAssertEqual(result.invitingUserID, ownerUserID)
        XCTAssertEqual(result.acceptingUserID, acceptingUserID)
        XCTAssertTrue(result.family.sharedWithUserIDs.contains(acceptingUserID))

        // Check that invitation was marked as used
        let updatedInvitation = mockInvitationRepository.invitations[token]
        XCTAssertTrue(updatedInvitation?.isUsed ?? false)
    }

    func testAcceptInvitation_ExpiredInvitation_ThrowsError() async {
        // Given
        let familyID = "family-123"
        let ownerUserID = "owner-456"
        let acceptingUserID = "accepter-789"
        let token = UUID()

        let family = createMockFamily(id: familyID, ownerUserID: ownerUserID, sharedWithUserIDs: [])
        let invitation = createMockInvitation(
            familyID: familyID,
            invitingUserID: ownerUserID,
            token: token,
            isUsed: false,
            expiresAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )

        mockFamilyRepository.families[familyID] = family
        mockInvitationRepository.invitations[token] = invitation

        // When & Then
        do {
            _ = try await service.validateAndAcceptInvitation(
                token: token,
                acceptingUserID: acceptingUserID
            )
            XCTFail("Expected error to be thrown")
        } catch let error as InvitationValidationError {
            if case .invitationExpired = error {
                // Success - expected error
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testAcceptInvitation_AlreadyUsed_ThrowsError() async {
        // Given
        let familyID = "family-123"
        let ownerUserID = "owner-456"
        let acceptingUserID = "accepter-789"
        let token = UUID()

        let family = createMockFamily(id: familyID, ownerUserID: ownerUserID, sharedWithUserIDs: [])
        let invitation = createMockInvitation(
            familyID: familyID,
            invitingUserID: ownerUserID,
            token: token,
            isUsed: true, // Already used
            expiresAt: Date().addingTimeInterval(3600)
        )

        mockFamilyRepository.families[familyID] = family
        mockInvitationRepository.invitations[token] = invitation

        // When & Then
        do {
            _ = try await service.validateAndAcceptInvitation(
                token: token,
                acceptingUserID: acceptingUserID
            )
            XCTFail("Expected error to be thrown")
        } catch let error as InvitationValidationError {
            if case .invitationAlreadyUsed = error {
                // Success - expected error
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testAcceptInvitation_InvalidToken_ThrowsError() async {
        // Given
        let acceptingUserID = "accepter-789"
        let token = UUID() // Non-existent token

        // Make sure the invitation doesn't exist
        mockInvitationRepository.invitations.removeAll()

        // When & Then
        do {
            _ = try await service.validateAndAcceptInvitation(
                token: token,
                acceptingUserID: acceptingUserID
            )
            XCTFail("Expected error to be thrown")
        } catch let error as InvitationError {
            XCTAssertEqual(error, .invitationNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Helper Functions

    private func createMockFamily(
        id: String,
        ownerUserID: String,
        sharedWithUserIDs: [String]
    ) -> Family {
        return Family(
            id: id,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: sharedWithUserIDs,
            childProfileIDs: ["child-1", "child-2"]
        )
    }

    private func createMockInvitation(
        familyID: String,
        invitingUserID: String,
        token: UUID,
        isUsed: Bool,
        expiresAt: Date
    ) -> FamilyInvitation {
        return FamilyInvitation(
            id: UUID(),
            familyID: familyID,
            invitingUserID: invitingUserID,
            inviteeEmail: nil,
            token: token,
            createdAt: Date(),
            expiresAt: expiresAt,
            isUsed: isUsed,
            deepLinkURL: "screentimerewards://invite/\(token.uuidString)"
        )
    }
}

// MARK: - Mock Repositories

// All mock repositories have been moved to TestUtilities.swift to avoid duplication

class MockCloudKitSharingService: CloudKitSharingService {
    var shares: [String: CKShare] = [:]

    override func shareFamily(familyID: String, with userID: String, permission: CKShare.ParticipantPermission = .readWrite) async throws -> CKShare {
        let share = CKShare(rootRecord: CKRecord(recordType: "Family", recordID: CKRecord.ID(recordName: familyID)))
        shares[familyID] = share
        return share
    }

    override func fetchShareForFamily(familyID: String) async throws -> CKShare? {
        return shares[familyID]
    }

    override func shareChildProfileZone(childProfileID: String, with participantUserID: String) async throws {
        // Mock implementation - no-op
    }

    override func createFamilySharingSubscription(for familyID: String) async throws -> CKSubscription {
        return CKQuerySubscription(
            recordType: "Family",
            predicate: NSPredicate(value: true),
            subscriptionID: "family-sharing-\(familyID)",
            options: [.firesOnRecordCreation]
        )
    }
}