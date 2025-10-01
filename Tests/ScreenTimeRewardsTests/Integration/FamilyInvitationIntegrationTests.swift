import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels
@testable import RewardCore
@testable import CloudKitService

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class FamilyInvitationIntegrationTests: XCTestCase {
    var familyRepository: MockFamilyRepository!
    var invitationRepository: MockFamilyInvitationRepository!
    var cloudKitSharingService: MockCloudKitSharingService!
    var validationService: FamilyInvitationValidationService!
    var invitationService: FamilyInvitationService!
    var familySharingViewModel: FamilySharingViewModel!
    var deepLinkHandler: DeepLinkHandler!

    override func setUp() {
        super.setUp()

        // Set up the full dependency chain
        familyRepository = MockFamilyRepository()
        invitationRepository = MockFamilyInvitationRepository()
        cloudKitSharingService = MockCloudKitSharingService()
        validationService = FamilyInvitationValidationService()

        invitationService = FamilyInvitationService(
            familyInvitationRepository: invitationRepository,
            familyRepository: familyRepository,
            cloudKitSharingService: cloudKitSharingService,
            validationService: validationService
        )

        familySharingViewModel = FamilySharingViewModel(
            familyRepository: familyRepository,
            familyInvitationService: invitationService
        )

        deepLinkHandler = DeepLinkHandler(familyInvitationService: invitationService)
    }

    override func tearDown() {
        familyRepository = nil
        invitationRepository = nil
        cloudKitSharingService = nil
        validationService = nil
        invitationService = nil
        familySharingViewModel = nil
        deepLinkHandler = nil
        super.tearDown()
    }

    // MARK: - Full Flow Integration Tests

    func testCompleteInvitationFlow_Success() async throws {
        // Given: A family owner wants to invite a co-parent
        let familyID = "test-family"
        let ownerUserID = "owner-123"
        let inviteeUserID = "invitee-456"

        let family = Family(
            id: familyID,
            name: "Smith Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [],
            childProfileIDs: ["child-1", "child-2"]
        )

        familyRepository.families[familyID] = family

        // Step 1: Load family data in the settings view
        await familySharingViewModel.loadFamilyData(familyID: familyID, currentUserID: ownerUserID)

        XCTAssertTrue(familySharingViewModel.isCurrentUserOwner)
        XCTAssertFalse(familySharingViewModel.isInviteDisabled)
        XCTAssertEqual(familySharingViewModel.coParents.count, 0)

        // Step 2: Create invitation link
        await familySharingViewModel.createInviteLink()

        XCTAssertNotNil(familySharingViewModel.inviteLink)
        XCTAssertFalse(familySharingViewModel.showError)

        guard let inviteLink = familySharingViewModel.inviteLink,
              let url = URL(string: inviteLink) else {
            XCTFail("Failed to create invite link")
            return
        }

        // Step 3: Simulate invitee receiving and tapping the deep link
        deepLinkHandler.handleURL(url)

        // Wait for async loading
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        XCTAssertTrue(deepLinkHandler.showInvitationSheet)
        XCTAssertNotNil(deepLinkHandler.pendingInvitation)

        // Step 4: Accept the invitation
        let acceptanceSuccess = await deepLinkHandler.acceptInvitation(currentUserID: inviteeUserID)

        XCTAssertTrue(acceptanceSuccess)
        XCTAssertFalse(deepLinkHandler.showInvitationSheet)
        XCTAssertNil(deepLinkHandler.pendingInvitation)

        // Step 5: Verify the family was updated
        let updatedFamily = try await familyRepository.fetchFamily(id: familyID)
        XCTAssertNotNil(updatedFamily)
        XCTAssertTrue(updatedFamily!.sharedWithUserIDs.contains(inviteeUserID))

        // Step 6: Verify the invitation was marked as used
        let usedInvitations = try await invitationRepository.fetchInvitations(for: familyID)
        XCTAssertEqual(usedInvitations.count, 1)
        XCTAssertTrue(usedInvitations[0].isUsed)

        // Step 7: Reload family data and verify UI state
        await familySharingViewModel.loadFamilyData(familyID: familyID, currentUserID: ownerUserID)

        XCTAssertEqual(familySharingViewModel.coParents.count, 1)
        XCTAssertTrue(familySharingViewModel.isInviteDisabled) // Max co-parents reached
    }

    func testInvitationFlow_ExpiredInvitation_ShowsError() async throws {
        // Given: An expired invitation
        let familyID = "test-family"
        let ownerUserID = "owner-123"
        let inviteeUserID = "invitee-456"
        let token = UUID()

        let family = Family(
            id: familyID,
            name: "Smith Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [],
            childProfileIDs: ["child-1"]
        )

        let expiredInvitation = FamilyInvitation(
            id: UUID(),
            familyID: familyID,
            invitingUserID: ownerUserID,
            token: token,
            createdAt: Date().addingTimeInterval(-3 * 24 * 60 * 60), // 3 days ago
            expiresAt: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago (expired)
            isUsed: false,
            deepLinkURL: "screentimerewards://invite/\(token.uuidString)"
        )

        familyRepository.families[familyID] = family
        invitationRepository.invitations[token] = expiredInvitation

        // When: User tries to accept expired invitation
        let url = URL(string: expiredInvitation.deepLinkURL)!
        deepLinkHandler.handleURL(url)

        // Wait for async loading
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        XCTAssertTrue(deepLinkHandler.showInvitationSheet)
        XCTAssertNotNil(deepLinkHandler.pendingInvitation)
        XCTAssertFalse(deepLinkHandler.pendingInvitation!.isValid)

        // When: User tries to accept the invitation
        let acceptanceSuccess = await deepLinkHandler.acceptInvitation(currentUserID: inviteeUserID)

        // Then: Acceptance should fail
        XCTAssertFalse(acceptanceSuccess)

        // Verify family was not updated
        let unchangedFamily = try await familyRepository.fetchFamily(id: familyID)
        XCTAssertFalse(unchangedFamily!.sharedWithUserIDs.contains(inviteeUserID))
    }

    func testInvitationFlow_FamilyAtCapacity_PreventsInvitation() async throws {
        // Given: A family already at capacity
        let familyID = "test-family"
        let ownerUserID = "owner-123"

        let fullFamily = Family(
            id: familyID,
            name: "Smith Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: ["existing-coparent"], // Already has 1 co-parent
            childProfileIDs: ["child-1"]
        )

        familyRepository.families[familyID] = fullFamily

        // When: Owner tries to create another invitation
        await familySharingViewModel.loadFamilyData(familyID: familyID, currentUserID: ownerUserID)
        await familySharingViewModel.createInviteLink()

        // Then: Invitation creation should fail
        XCTAssertTrue(familySharingViewModel.showError)
        XCTAssertNil(familySharingViewModel.inviteLink)
        XCTAssertTrue(familySharingViewModel.isInviteDisabled)
    }

    func testRemoveCoParent_ReEnablesInvitations() async throws {
        // Given: A family with a co-parent
        let familyID = "test-family"
        let ownerUserID = "owner-123"
        let coParentUserID = "coparent-456"

        let family = Family(
            id: familyID,
            name: "Smith Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [coParentUserID],
            childProfileIDs: ["child-1"]
        )

        familyRepository.families[familyID] = family

        // When: Load family data
        await familySharingViewModel.loadFamilyData(familyID: familyID, currentUserID: ownerUserID)

        // Then: Invitations should be disabled (at capacity)
        XCTAssertTrue(familySharingViewModel.isInviteDisabled)
        XCTAssertEqual(familySharingViewModel.coParents.count, 1)

        // When: Remove the co-parent
        await familySharingViewModel.removeCoParent(userID: coParentUserID)

        // Then: Invitations should be re-enabled
        XCTAssertFalse(familySharingViewModel.isInviteDisabled)
        XCTAssertEqual(familySharingViewModel.coParents.count, 0)

        // Verify family was updated in repository
        let updatedFamily = try await familyRepository.fetchFamily(id: familyID)
        XCTAssertFalse(updatedFamily!.sharedWithUserIDs.contains(coParentUserID))
    }

    func testNetworkErrorRetry_EventuallySucceeds() async throws {
        // Given: A service that fails twice then succeeds
        let failingRepository = FailingMockFamilyRepository(failureCount: 2)
        let retryService = FamilyInvitationService(
            familyInvitationRepository: invitationRepository,
            familyRepository: failingRepository,
            cloudKitSharingService: cloudKitSharingService,
            validationService: validationService
        )

        let familyID = "test-family"
        let ownerUserID = "owner-123"

        let family = Family(
            id: familyID,
            name: "Smith Family",
            createdAt: Date(),
            ownerUserID: ownerUserID,
            sharedWithUserIDs: [],
            childProfileIDs: ["child-1"]
        )

        failingRepository.families[familyID] = family

        // When: Create invitation (should retry and eventually succeed)
        let invitation = try await retryService.createInvitation(
            familyID: familyID,
            invitingUserID: ownerUserID
        )

        // Then: Invitation should be created successfully
        XCTAssertEqual(invitation.familyID, familyID)
        XCTAssertEqual(invitation.invitingUserID, ownerUserID)
        XCTAssertEqual(failingRepository.attemptCount, 3) // Failed twice, succeeded on third try
    }
}

// MARK: - Test Helper Classes

class FailingMockFamilyRepository: MockFamilyRepository {
    private let maxFailures: Int
    private(set) var attemptCount = 0

    init(failureCount: Int) {
        self.maxFailures = failureCount
        super.init()
    }

    override func fetchFamily(id: String) async throws -> Family? {
        attemptCount += 1

        if attemptCount <= maxFailures {
            throw NetworkError.timeout
        }

        return await super.fetchFamily(id: id)
    }
}