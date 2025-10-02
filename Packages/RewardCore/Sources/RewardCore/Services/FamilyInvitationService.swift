import Foundation
import SharedModels
import CloudKitService

@available(iOS 15.0, macOS 12.0, *)
public class FamilyInvitationService {
    private let familyInvitationRepository: FamilyInvitationRepository
    private let familyRepository: FamilyRepository
    private let cloudKitSharingService: CloudKitSharingService
    private let validationService: FamilyInvitationValidationService

    public init(
        familyInvitationRepository: FamilyInvitationRepository,
        familyRepository: FamilyRepository,
        cloudKitSharingService: CloudKitSharingService,
        validationService: FamilyInvitationValidationService
    ) {
        self.familyInvitationRepository = familyInvitationRepository
        self.familyRepository = familyRepository
        self.cloudKitSharingService = cloudKitSharingService
        self.validationService = validationService
    }

    // MARK: - Public Methods

    public func createInvitation(
        familyID: String,
        invitingUserID: String,
        inviteeEmail: String? = nil
    ) async throws -> FamilyInvitation {
        return try await validationService.performWithRetry {
            // Validate that the inviting user is the family owner
            let family = try await self.familyRepository.fetchFamily(id: familyID)
            guard let family = family else {
                throw InvitationError.familyNotFound
            }

            // Validate invitation creation
            try self.validationService.validateInvitationCreation(
                family: family,
                invitingUserID: invitingUserID
            )

            // Generate secure token and deep link
            let token = UUID()
            let deepLinkURL = self.generateDeepLinkURL(token: token)

            // Create invitation
            let invitation = FamilyInvitation(
                familyID: familyID,
                invitingUserID: invitingUserID,
                inviteeEmail: inviteeEmail,
                token: token,
                deepLinkURL: deepLinkURL
            )

            return try await self.familyInvitationRepository.createInvitation(invitation)
        }
    }

    public func validateAndAcceptInvitation(
        token: UUID,
        acceptingUserID: String
    ) async throws -> InvitationAcceptanceResult {
        return try await validationService.performWithRetry {
            // Fetch invitation
            guard let invitation = try await self.familyInvitationRepository.fetchInvitation(by: token) else {
                throw InvitationError.invalidToken
            }

            // Fetch family
            guard let family = try await self.familyRepository.fetchFamily(id: invitation.familyID) else {
                throw InvitationError.familyNotFound
            }

            // Validate invitation acceptance
            try self.validationService.validateInvitationAcceptance(
                invitation: invitation,
                family: family,
                acceptingUserID: acceptingUserID
            )

            // Add user to family
            var updatedFamily = family
            updatedFamily.sharedWithUserIDs.append(acceptingUserID)
            let savedFamily = try await self.familyRepository.updateFamily(updatedFamily)

            // Set up CloudKit sharing for the new family member
            do {
                // Create or update CloudKit share for the family
                let existingShare = try await self.cloudKitSharingService.fetchShareForFamily(familyID: family.id)

                if let share = existingShare {
                    // Add new participant to existing share
                    // Note: In a real implementation, you would need to look up the user identity
                    // This is a simplified version
                    print("Adding participant to existing family share")
                } else {
                    // Create new share for the family
                    _ = try await self.cloudKitSharingService.shareFamily(
                        familyID: family.id,
                        with: acceptingUserID
                    )
                }

                // Set up child profile zone access for the new co-parent
                for childID in family.childProfileIDs {
                    try await self.cloudKitSharingService.shareChildProfileZone(
                        childProfileID: childID,
                        with: acceptingUserID
                    )
                }

                // Create CloudKit subscriptions for real-time sync
                _ = try await self.cloudKitSharingService.createFamilySharingSubscription(for: family.id)

            } catch {
                // Log CloudKit sharing error but don't fail the invitation acceptance
                print("CloudKit sharing setup failed: \(error.localizedDescription)")
            }

            // Mark invitation as used
            var usedInvitation = invitation
            usedInvitation.isUsed = true
            _ = try await self.familyInvitationRepository.updateInvitation(usedInvitation)

            return InvitationAcceptanceResult(
                family: savedFamily,
                invitingUserID: invitation.invitingUserID,
                acceptingUserID: acceptingUserID
            )
        }
    }

    public func getInvitationDetails(token: UUID) async throws -> FamilyInvitation? {
        return try await familyInvitationRepository.fetchInvitation(by: token)
    }

    public func getFamilyInvitations(familyID: String) async throws -> [FamilyInvitation] {
        return try await familyInvitationRepository.fetchInvitations(for: familyID)
    }

    public func revokeInvitation(invitationID: UUID, requestingUserID: String) async throws {
        guard let invitation = try await familyInvitationRepository.fetchInvitation(by: invitationID) else {
            throw InvitationError.invitationNotFound
        }

        // Only the inviting user can revoke their invitation
        guard invitation.invitingUserID == requestingUserID else {
            throw InvitationError.notAuthorized
        }

        try await familyInvitationRepository.deleteInvitation(id: invitationID)
    }

    public func cleanupExpiredInvitations() async throws {
        try await familyInvitationRepository.deleteExpiredInvitations()
    }

    // MARK: - Private Methods

    private func generateDeepLinkURL(token: UUID) -> String {
        return "screentimerewards://invite/\(token.uuidString)"
    }

}

// MARK: - Result Types

public struct InvitationAcceptanceResult {
    public let family: Family
    public let invitingUserID: String
    public let acceptingUserID: String

    public init(family: Family, invitingUserID: String, acceptingUserID: String) {
        self.family = family
        self.invitingUserID = invitingUserID
        self.acceptingUserID = acceptingUserID
    }
}

// MARK: - Error Types

public enum InvitationError: Error, LocalizedError, Equatable {
    case familyNotFound
    case notFamilyOwner
    case familyMemberLimitReached
    case invalidToken
    case invitationNotFound
    case invitationAlreadyUsed
    case invitationExpired
    case cannotAcceptOwnInvitation
    case userAlreadyInFamily
    case notAuthorized

    public var errorDescription: String? {
        switch self {
        case .familyNotFound:
            return "Family not found"
        case .notFamilyOwner:
            return "Only family owners can create invitations"
        case .familyMemberLimitReached:
            return "Family already has the maximum number of parents"
        case .invalidToken:
            return "Invalid invitation link"
        case .invitationNotFound:
            return "Invitation not found"
        case .invitationAlreadyUsed:
            return "This invitation has already been used"
        case .invitationExpired:
            return "This invitation has expired"
        case .cannotAcceptOwnInvitation:
            return "You cannot accept your own invitation"
        case .userAlreadyInFamily:
            return "You are already a member of this family"
        case .notAuthorized:
            return "You are not authorized to perform this action"
        }
    }
    
    public static func == (lhs: InvitationError, rhs: InvitationError) -> Bool {
        switch (lhs, rhs) {
        case (.familyNotFound, .familyNotFound):
            return true
        case (.notFamilyOwner, .notFamilyOwner):
            return true
        case (.familyMemberLimitReached, .familyMemberLimitReached):
            return true
        case (.invalidToken, .invalidToken):
            return true
        case (.invitationNotFound, .invitationNotFound):
            return true
        case (.invitationAlreadyUsed, .invitationAlreadyUsed):
            return true
        case (.invitationExpired, .invitationExpired):
            return true
        case (.cannotAcceptOwnInvitation, .cannotAcceptOwnInvitation):
            return true
        case (.userAlreadyInFamily, .userAlreadyInFamily):
            return true
        case (.notAuthorized, .notAuthorized):
            return true
        default:
            return false
        }
    }
}