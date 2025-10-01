import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels
@testable import RewardCore

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class FamilySharingViewModelTests: XCTestCase {
    var viewModel: FamilySharingViewModel!
    var mockFamilyRepository: MockFamilyRepository!
    var mockInvitationService: MockFamilyInvitationService!

    override func setUp() {
        super.setUp()
        mockFamilyRepository = MockFamilyRepository()
        mockInvitationService = MockFamilyInvitationService()

        viewModel = FamilySharingViewModel(
            familyRepository: mockFamilyRepository,
            familyInvitationService: mockInvitationService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockFamilyRepository = nil
        mockInvitationService = nil
        super.tearDown()
    }

    // MARK: - Load Family Data Tests

    func testLoadFamilyData_Success() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: currentUserID,
            sharedWithUserIDs: ["coparent-1"],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family

        // When
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.isCurrentUserOwner)
        XCTAssertEqual(viewModel.coParents.count, 1)
        XCTAssertEqual(viewModel.familyOwner?.userID, currentUserID)
    }

    func testLoadFamilyData_NotOwner() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let ownerUserID = "owner-789"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [currentUserID],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family

        // When
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // Then
        XCTAssertFalse(viewModel.isCurrentUserOwner)
        XCTAssertTrue(viewModel.isInviteDisabled) // Non-owners cannot invite
    }

    // MARK: - Create Invite Link Tests

    func testCreateInviteLink_Success() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: currentUserID,
            sharedWithUserIDs: [],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        let expectedInvitation = FamilyInvitation(
            familyID: familyID,
            invitingUserID: currentUserID,
            deepLinkURL: "screentimerewards://invite/test-token"
        )
        mockInvitationService.mockInvitation = expectedInvitation

        // When
        await viewModel.createInviteLink()

        // Then
        XCTAssertFalse(viewModel.isCreatingInvite)
        XCTAssertEqual(viewModel.inviteLink, expectedInvitation.deepLinkURL)
        XCTAssertFalse(viewModel.showError)
    }

    func testCreateInviteLink_NotOwner_ShowsError() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let ownerUserID = "owner-789"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [currentUserID],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // When
        await viewModel.createInviteLink()

        // Then
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "Only family owners can create invitations")
        XCTAssertNil(viewModel.inviteLink)
    }

    func testCreateInviteLink_ServiceError_ShowsError() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: currentUserID,
            sharedWithUserIDs: [],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        mockInvitationService.shouldThrowError = true

        // When
        await viewModel.createInviteLink()

        // Then
        XCTAssertTrue(viewModel.showError)
        XCTAssertTrue(viewModel.errorMessage.contains("Failed to create invitation"))
        XCTAssertNil(viewModel.inviteLink)
    }

    // MARK: - Remove Co-Parent Tests

    func testRemoveCoParent_Success() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let coParentUserID = "coparent-789"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: currentUserID,
            sharedWithUserIDs: [coParentUserID],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // When
        await viewModel.removeCoParent(userID: coParentUserID)

        // Then
        XCTAssertEqual(viewModel.coParents.count, 0)
        XCTAssertFalse(viewModel.showError)

        // Verify family was updated in repository
        let updatedFamily = mockFamilyRepository.families[familyID]
        XCTAssertFalse(updatedFamily?.sharedWithUserIDs.contains(coParentUserID) ?? true)
    }

    func testRemoveCoParent_NotOwner_ShowsError() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let ownerUserID = "owner-789"
        let coParentUserID = "coparent-abc"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [currentUserID, coParentUserID],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // When
        await viewModel.removeCoParent(userID: coParentUserID)

        // Then
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "Only family owners can remove co-parents")
    }

    // MARK: - Computed Properties Tests

    func testIsInviteDisabled_OwnerWithNoCoParents_False() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: currentUserID,
            sharedWithUserIDs: [],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // Then
        XCTAssertFalse(viewModel.isInviteDisabled)
    }

    func testIsInviteDisabled_OwnerWithMaxCoParents_True() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: currentUserID,
            sharedWithUserIDs: ["coparent-1"], // Max 1 co-parent
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // Then
        XCTAssertTrue(viewModel.isInviteDisabled)
    }

    func testIsInviteDisabled_NotOwner_True() async {
        // Given
        let familyID = "family-123"
        let currentUserID = "user-456"
        let ownerUserID = "owner-789"
        let family = Family(
            id: familyID,
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [currentUserID],
            childProfileIDs: ["child-1"]
        )

        mockFamilyRepository.families[familyID] = family
        await viewModel.loadFamilyData(familyID: familyID, currentUserID: currentUserID)

        // Then
        XCTAssertTrue(viewModel.isInviteDisabled)
    }

    // MARK: - Accept Invitation Tests

    func testAcceptInvitation_Success() async {
        // Given
        let token = UUID()
        let acceptingUserID = "accepter-123"

        mockInvitationService.mockAcceptanceResult = InvitationAcceptanceResult(
            family: Family(
                id: "family-123",
                name: "Test Family",
                createdAt: Date(),
                ownerUserID: "owner-456",
                sharedWithUserIDs: [acceptingUserID],
                childProfileIDs: ["child-1"]
            ),
            invitingUserID: "owner-456",
            acceptingUserID: acceptingUserID
        )

        // When
        let success = await viewModel.acceptInvitation(token: token, acceptingUserID: acceptingUserID)

        // Then
        XCTAssertTrue(success)
        XCTAssertFalse(viewModel.showError)
    }

    func testAcceptInvitation_ServiceError_ReturnsFalse() async {
        // Given
        let token = UUID()
        let acceptingUserID = "accepter-123"

        mockInvitationService.shouldThrowErrorOnAccept = true

        // When
        let success = await viewModel.acceptInvitation(token: token, acceptingUserID: acceptingUserID)

        // Then
        XCTAssertFalse(success)
        XCTAssertTrue(viewModel.showError)
        XCTAssertTrue(viewModel.errorMessage.contains("Failed to accept invitation"))
    }
}

// MARK: - Mock Services

class MockFamilyInvitationService: FamilyInvitationService {
    var mockInvitation: FamilyInvitation?
    var mockAcceptanceResult: InvitationAcceptanceResult?
    var shouldThrowError = false
    var shouldThrowErrorOnAccept = false

    override func createInvitation(familyID: String, invitingUserID: String, inviteeEmail: String? = nil) async throws -> FamilyInvitation {
        if shouldThrowError {
            throw TestError.mockError
        }

        guard let invitation = mockInvitation else {
            throw TestError.noMockData
        }

        return invitation
    }

    override func validateAndAcceptInvitation(token: UUID, acceptingUserID: String) async throws -> InvitationAcceptanceResult {
        if shouldThrowErrorOnAccept {
            throw TestError.mockError
        }

        guard let result = mockAcceptanceResult else {
            throw TestError.noMockData
        }

        return result
    }
}

enum TestError: Error {
    case mockError
    case noMockData
}