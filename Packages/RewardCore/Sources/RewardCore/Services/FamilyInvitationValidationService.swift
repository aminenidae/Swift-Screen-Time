import Foundation
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public class FamilyInvitationValidationService {
    
    public init() {}

    // MARK: - Constants

    private static let maxParentsPerFamily = 2 // Owner + 1 co-parent
    private static let invitationExpirationHours: TimeInterval = 72 // 72 hours
    private static let maxRetryAttempts = 3
    private static let retryDelay: TimeInterval = 1.0 // Start with 1 second

    // MARK: - Validation Methods

    public func validateInvitationCreation(
        family: Family,
        invitingUserID: String
    ) throws {
        // Check if user is family owner
        guard family.ownerUserID == invitingUserID else {
            throw InvitationValidationError.notFamilyOwner
        }

        // Check family member limit
        guard family.sharedWithUserIDs.count < (Self.maxParentsPerFamily - 1) else {
            throw InvitationValidationError.familyMemberLimitReached(
                current: family.sharedWithUserIDs.count + 1, // +1 for owner
                maximum: Self.maxParentsPerFamily
            )
        }
    }

    public func validateInvitationToken(_ invitation: FamilyInvitation) throws {
        // Check if invitation is used
        if invitation.isUsed {
            throw InvitationValidationError.invitationAlreadyUsed
        }

        // Check if invitation has expired
        if invitation.expiresAt < Date() {
            let hoursExpired = Int(-invitation.expiresAt.timeIntervalSinceNow / 3600)
            throw InvitationValidationError.invitationExpired(hoursAgo: hoursExpired)
        }
    }

    public func validateInvitationAcceptance(
        invitation: FamilyInvitation,
        family: Family,
        acceptingUserID: String
    ) throws {
        // Validate token first
        try validateInvitationToken(invitation)

        // Check if user is trying to accept their own invitation
        if invitation.invitingUserID == acceptingUserID {
            throw InvitationValidationError.cannotAcceptOwnInvitation
        }

        // Check if user is already part of the family
        if family.ownerUserID == acceptingUserID || family.sharedWithUserIDs.contains(acceptingUserID) {
            throw InvitationValidationError.userAlreadyInFamily
        }

        // Check family size limits again (in case multiple people are trying to join)
        guard family.sharedWithUserIDs.count < (Self.maxParentsPerFamily - 1) else {
            throw InvitationValidationError.familyMemberLimitReached(
                current: family.sharedWithUserIDs.count + 1,
                maximum: Self.maxParentsPerFamily
            )
        }
    }

    // MARK: - Retry Logic

    public func performWithRetry<T>(
        operation: @escaping () async throws -> T,
        maxAttempts: Int = 3, // Using literal value instead of private static property
        baseDelay: TimeInterval = 1.0 // Using literal value instead of private static property
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry on certain types of errors
                if let validationError = error as? InvitationValidationError,
                   !validationError.isRetryable {
                    throw error
                }

                if let networkError = error as? NetworkError,
                   !networkError.isRetryable {
                    throw error
                }

                // If this is the last attempt, throw the error
                if attempt == maxAttempts {
                    throw error
                }

                // Calculate exponential backoff delay
                let delay = baseDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // This should never be reached, but just in case
        throw lastError ?? InvitationValidationError.unknownError
    }

    // MARK: - Error Recovery

    public func recoverFromError(_ error: Error) -> ErrorRecoveryAction {
        switch error {
        case let validationError as InvitationValidationError:
            return recoverFromValidationError(validationError)
        case let networkError as NetworkError:
            return recoverFromNetworkError(networkError)
        // Remove CloudKitError handling since it's not defined
        default:
            return .showError(
                title: "Unexpected Error",
                message: error.localizedDescription,
                action: .none
            )
        }
    }

    private func recoverFromValidationError(_ error: InvitationValidationError) -> ErrorRecoveryAction {
        switch error {
        case .invitationExpired(let hoursAgo):
            return .showError(
                title: "Invitation Expired",
                message: "This invitation expired \(hoursAgo) hours ago. Please ask the family owner to send a new invitation.",
                action: .dismissAndReturnToSettings
            )

        case .invitationAlreadyUsed:
            return .showError(
                title: "Invitation Already Used",
                message: "This invitation has already been accepted. Each invitation can only be used once.",
                action: .dismissAndReturnToSettings
            )

        case .familyMemberLimitReached(let current, let maximum):
            return .showError(
                title: "Family Full",
                message: "This family already has \(current) of \(maximum) allowed parents. No additional co-parents can be added.",
                action: .dismissAndReturnToSettings
            )

        case .notFamilyOwner:
            return .showError(
                title: "Permission Denied",
                message: "Only family owners can create invitations. Contact your family owner if you need to invite someone.",
                action: .none
            )

        case .userAlreadyInFamily:
            return .showError(
                title: "Already a Member",
                message: "You are already a member of this family.",
                action: .dismissAndOpenFamilySettings
            )

        case .cannotAcceptOwnInvitation:
            return .showError(
                title: "Invalid Action",
                message: "You cannot accept an invitation that you created.",
                action: .none
            )

        case .unknownError:
            return .showError(
                title: "Validation Error",
                message: "An unexpected validation error occurred. Please try again.",
                action: .retry
            )
        }
    }

    private func recoverFromNetworkError(_ error: NetworkError) -> ErrorRecoveryAction {
        switch error {
        case .noConnection:
            return .showError(
                title: "No Internet Connection",
                message: "Please check your internet connection and try again.",
                action: .retry
            )

        case .timeout:
            return .showError(
                title: "Request Timeout",
                message: "The request took too long. Please try again.",
                action: .retry
            )

        case .serverError(let code):
            return .showError(
                title: "Server Error",
                message: "Server error (\(code)). Please try again later.",
                action: .retryLater
            )

        case .rateLimited:
            return .showError(
                title: "Too Many Requests",
                message: "You're sending requests too quickly. Please wait a moment and try again.",
                action: .retryAfterDelay(seconds: 30)
            )
        }
    }
}

// MARK: - Error Types

public enum InvitationValidationError: Error, LocalizedError, Equatable {
    case notFamilyOwner
    case familyMemberLimitReached(current: Int, maximum: Int)
    case invitationExpired(hoursAgo: Int)
    case invitationAlreadyUsed
    case userAlreadyInFamily
    case cannotAcceptOwnInvitation
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .notFamilyOwner:
            return "Only family owners can create invitations"
        case .familyMemberLimitReached(let current, let maximum):
            return "Family has reached the maximum of \(maximum) parents (currently \(current))"
        case .invitationExpired(let hoursAgo):
            return "Invitation expired \(hoursAgo) hours ago"
        case .invitationAlreadyUsed:
            return "This invitation has already been used"
        case .userAlreadyInFamily:
            return "User is already a member of this family"
        case .cannotAcceptOwnInvitation:
            return "Cannot accept your own invitation"
        case .unknownError:
            return "An unknown validation error occurred"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .unknownError:
            return true
        default:
            return false
        }
    }
    
    public static func == (lhs: InvitationValidationError, rhs: InvitationValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.notFamilyOwner, .notFamilyOwner):
            return true
        case (.familyMemberLimitReached(let lhsCurrent, let lhsMaximum), .familyMemberLimitReached(let rhsCurrent, let rhsMaximum)):
            return lhsCurrent == rhsCurrent && lhsMaximum == rhsMaximum
        case (.invitationExpired(let lhsHoursAgo), .invitationExpired(let rhsHoursAgo)):
            return lhsHoursAgo == rhsHoursAgo
        case (.invitationAlreadyUsed, .invitationAlreadyUsed):
            return true
        case (.userAlreadyInFamily, .userAlreadyInFamily):
            return true
        case (.cannotAcceptOwnInvitation, .cannotAcceptOwnInvitation):
            return true
        case (.unknownError, .unknownError):
            return true
        default:
            return false
        }
    }
}

public enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(code: Int)
    case rateLimited

    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timeout"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .rateLimited:
            return "Rate limited - too many requests"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .rateLimited:
            return true
        case .serverError(let code):
            return code >= 500 // Retry on server errors, not client errors
        }
    }
}

// MARK: - Error Recovery

public enum ErrorRecoveryAction {
    case showError(title: String, message: String, action: RecoveryActionType)
}

public enum RecoveryActionType {
    case none
    case retry
    case retryLater
    case retryAfterDelay(seconds: Int)
    case dismissAndReturnToSettings
    case dismissAndOpenFamilySettings
    case openSettings
}