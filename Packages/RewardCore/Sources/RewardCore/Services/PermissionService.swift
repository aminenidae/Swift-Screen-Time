import Foundation
import SharedModels
import CloudKitService

@available(iOS 15.0, macOS 12.0, *)
public class PermissionService {
    private let cloudKitService: CloudKitService
    private let currentUserID: String?

    public init(cloudKitService: CloudKitService = .shared, currentUserID: String? = nil) {
        self.cloudKitService = cloudKitService
        self.currentUserID = currentUserID
    }

    // MARK: - Permission Checking

    /// Check if a user has permission to perform an action on a family
    public func checkPermission(_ check: PermissionCheck) async throws -> Bool {
        guard let family = try await cloudKitService.fetchFamily(id: check.familyID) else {
            throw PermissionError.familyNotFound
        }

        let userRole = getUserRole(userID: check.userID, in: family)
        return hasPermission(role: userRole, for: check.action)
    }

    /// Check if current user has permission for an action
    public func checkCurrentUserPermission(familyID: String, action: PermissionAction, targetEntity: String? = nil) async throws -> Bool {
        guard let userID = currentUserID else {
            throw PermissionError.userNotFound
        }

        let check = PermissionCheck(userID: userID, familyID: familyID, action: action, targetEntity: targetEntity)
        return try await checkPermission(check)
    }

    /// Validate permission or throw error
    public func validatePermission(_ check: PermissionCheck) async throws {
        let hasPermission = try await checkPermission(check)
        if !hasPermission {
            throw PermissionError.unauthorized(action: check.action)
        }
    }

    /// Validate current user permission or throw error
    public func validateCurrentUserPermission(familyID: String, action: PermissionAction, targetEntity: String? = nil) async throws {
        guard let userID = currentUserID else {
            throw PermissionError.userNotFound
        }

        let check = PermissionCheck(userID: userID, familyID: familyID, action: action, targetEntity: targetEntity)
        try await validatePermission(check)
    }

    // MARK: - Role Management

    /// Get user's role in a family
    public func getUserRole(userID: String, in family: Family) -> PermissionRole? {
        // Owner always has owner role
        if family.ownerUserID == userID {
            return .owner
        }

        // Check explicit role assignment
        if let role = family.userRoles[userID] {
            return role
        }

        // Default to co-parent for shared users (backward compatibility)
        if family.sharedWithUserIDs.contains(userID) {
            return .coParent
        }

        return nil
    }

    /// Assign role to user in family (owner only)
    public func assignRole(_ role: PermissionRole, to userID: String, in familyID: String, by assigningUserID: String) async throws -> Family {
        guard let family = try await cloudKitService.fetchFamily(id: familyID) else {
            throw PermissionError.familyNotFound
        }

        // Only owner can assign roles
        guard family.ownerUserID == assigningUserID else {
            throw PermissionError.unauthorized(action: .edit)
        }

        // Cannot change owner role
        guard family.ownerUserID != userID else {
            throw PermissionError.invalidRole
        }

        var updatedFamily = family
        updatedFamily.userRoles[userID] = role

        // Ensure user is in shared list if not owner
        if !updatedFamily.sharedWithUserIDs.contains(userID) {
            updatedFamily.sharedWithUserIDs.append(userID)
        }

        return try await cloudKitService.updateFamily(updatedFamily)
    }

    /// Remove user from family (owner only)
    public func removeUser(_ userID: String, from familyID: String, by removingUserID: String) async throws -> Family {
        guard let family = try await cloudKitService.fetchFamily(id: familyID) else {
            throw PermissionError.familyNotFound
        }

        // Only owner can remove users
        guard family.ownerUserID == removingUserID else {
            throw PermissionError.unauthorized(action: .remove)
        }

        // Cannot remove owner
        guard family.ownerUserID != userID else {
            throw PermissionError.invalidRole
        }

        var updatedFamily = family
        updatedFamily.userRoles.removeValue(forKey: userID)
        updatedFamily.sharedWithUserIDs.removeAll { $0 == userID }

        return try await cloudKitService.updateFamily(updatedFamily)
    }

    // MARK: - Permission Logic

    private func hasPermission(role: PermissionRole?, for action: PermissionAction) -> Bool {
        guard let role = role else { return false }

        switch action {
        case .view:
            // All roles can view
            return true

        case .edit, .delete:
            // Only owner and co-parent can edit/delete (v1.1)
            return role.hasFullAccess

        case .invite, .remove:
            // Only owner can invite/remove users
            return role == .owner
        }
    }

    // MARK: - Family Member Information

    /// Get all family members with their roles
    public func getFamilyMembers(familyID: String) async throws -> [(userID: String, role: PermissionRole)] {
        guard let family = try await cloudKitService.fetchFamily(id: familyID) else {
            throw PermissionError.familyNotFound
        }

        var members: [(userID: String, role: PermissionRole)] = []

        // Add owner
        members.append((userID: family.ownerUserID, role: .owner))

        // Add shared users with their roles
        for userID in family.sharedWithUserIDs {
            let role = getUserRole(userID: userID, in: family) ?? .coParent
            members.append((userID: userID, role: role))
        }

        return members
    }

    /// Check if user is family member
    public func isFamilyMember(userID: String, familyID: String) async throws -> Bool {
        guard let family = try await cloudKitService.fetchFamily(id: familyID) else {
            return false
        }

        return family.ownerUserID == userID || family.sharedWithUserIDs.contains(userID)
    }
}

// MARK: - Repository Permission Extensions

@available(iOS 15.0, macOS 12.0, *)
public extension PermissionService {

    /// Validate permission before repository operations
    func validateRepositoryAccess(userID: String, familyID: String, action: PermissionAction) async throws {
        let check = PermissionCheck(userID: userID, familyID: familyID, action: action)
        try await validatePermission(check)
    }
}