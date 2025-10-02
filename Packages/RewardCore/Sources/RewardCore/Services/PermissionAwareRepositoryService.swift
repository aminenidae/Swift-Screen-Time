import Foundation
import SharedModels

/// Service that wraps repository operations with permission checking
@available(iOS 15.0, macOS 12.0, *)
public class PermissionAwareRepositoryService {
    private let permissionService: PermissionService
    private let childProfileRepository: ChildProfileRepository
    private let appCategorizationRepository: AppCategorizationRepository
    private let familyRepository: FamilyRepository
    private let usageSessionRepository: UsageSessionRepository
    private let pointTransactionRepository: PointTransactionRepository

    public init(
        permissionService: PermissionService,
        childProfileRepository: ChildProfileRepository,
        appCategorizationRepository: AppCategorizationRepository,
        familyRepository: FamilyRepository,
        usageSessionRepository: UsageSessionRepository,
        pointTransactionRepository: PointTransactionRepository
    ) {
        self.permissionService = permissionService
        self.childProfileRepository = childProfileRepository
        self.appCategorizationRepository = appCategorizationRepository
        self.familyRepository = familyRepository
        self.usageSessionRepository = usageSessionRepository
        self.pointTransactionRepository = pointTransactionRepository
    }

    // MARK: - Child Profile Operations

    public func createChild(_ child: ChildProfile, by userID: String) async throws -> ChildProfile {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .edit
        )
        return try await childProfileRepository.createChild(child)
    }

    public func updateChild(_ child: ChildProfile, by userID: String) async throws -> ChildProfile {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .edit
        )
        return try await childProfileRepository.updateChild(child)
    }

    public func deleteChild(id: String, from familyID: String, by userID: String) async throws {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: familyID,
            action: .delete
        )
        try await childProfileRepository.deleteChild(id: id)
    }

    public func fetchChild(id: String, from familyID: String, by userID: String) async throws -> ChildProfile? {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: familyID,
            action: .view
        )
        return try await childProfileRepository.fetchChild(id: id)
    }

    public func fetchChildren(for familyID: String, by userID: String) async throws -> [ChildProfile] {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: familyID,
            action: .view
        )
        return try await childProfileRepository.fetchChildren(for: familyID)
    }

    // MARK: - App Categorization Operations

    public func createAppCategorization(_ categorization: AppCategorization, by userID: String) async throws -> AppCategorization {
        // Get child to find family
        guard let child = try await childProfileRepository.fetchChild(id: categorization.childProfileID) else {
            throw PermissionError.userNotFound
        }

        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .edit
        )
        return try await appCategorizationRepository.createAppCategorization(categorization)
    }

    public func updateAppCategorization(_ categorization: AppCategorization, by userID: String) async throws -> AppCategorization {
        // Get child to find family
        guard let child = try await childProfileRepository.fetchChild(id: categorization.childProfileID) else {
            throw PermissionError.userNotFound
        }

        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .edit
        )
        return try await appCategorizationRepository.updateAppCategorization(categorization)
    }

    public func deleteAppCategorization(id: String, from familyID: String, by userID: String) async throws {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: familyID,
            action: .delete
        )
        try await appCategorizationRepository.deleteAppCategorization(id: id)
    }

    public func fetchAppCategorizations(for childID: String, by userID: String) async throws -> [AppCategorization] {
        // Get child to find family
        guard let child = try await childProfileRepository.fetchChild(id: childID) else {
            throw PermissionError.userNotFound
        }

        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .view
        )
        return try await appCategorizationRepository.fetchAppCategorizations(for: childID)
    }

    // MARK: - Family Operations

    public func updateFamily(_ family: Family, by userID: String) async throws -> Family {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: family.id,
            action: .edit
        )
        return try await familyRepository.updateFamily(family)
    }

    public func deleteFamily(id: String, by userID: String) async throws {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: id,
            action: .delete
        )
        try await familyRepository.deleteFamily(id: id)
    }

    public func fetchFamily(id: String, by userID: String) async throws -> Family? {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: id,
            action: .view
        )
        return try await familyRepository.fetchFamily(id: id)
    }

    // MARK: - Usage Session Operations

    public func createUsageSession(_ session: UsageSession, by userID: String) async throws -> UsageSession {
        // Get child to find family
        guard let child = try await childProfileRepository.fetchChild(id: session.childProfileID) else {
            throw PermissionError.userNotFound
        }

        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .edit
        )
        return try await usageSessionRepository.createSession(session)
    }

    public func fetchUsageSessions(for childID: String, dateRange: DateRange?, by userID: String) async throws -> [UsageSession] {
        // Get child to find family
        guard let child = try await childProfileRepository.fetchChild(id: childID) else {
            throw PermissionError.userNotFound
        }

        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .view
        )
        return try await usageSessionRepository.fetchSessions(for: childID, dateRange: dateRange)
    }

    // MARK: - Point Transaction Operations

    public func createPointTransaction(_ transaction: PointTransaction, by userID: String) async throws -> PointTransaction {
        // Get child to find family
        guard let child = try await childProfileRepository.fetchChild(id: transaction.childProfileID) else {
            throw PermissionError.userNotFound
        }

        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .edit
        )
        return try await pointTransactionRepository.createTransaction(transaction)
    }

    public func fetchPointTransactions(for childID: String, limit: Int?, by userID: String) async throws -> [PointTransaction] {
        // Get child to find family
        guard let child = try await childProfileRepository.fetchChild(id: childID) else {
            throw PermissionError.userNotFound
        }

        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: child.familyID,
            action: .view
        )
        return try await pointTransactionRepository.fetchTransactions(for: childID, limit: limit)
    }

    // MARK: - Permission Management

    public func assignUserRole(_ role: PermissionRole, to userID: String, in familyID: String, by assigningUserID: String) async throws -> Family {
        return try await permissionService.assignRole(role, to: userID, in: familyID, by: assigningUserID)
    }

    public func removeUser(_ userID: String, from familyID: String, by removingUserID: String) async throws -> Family {
        return try await permissionService.removeUser(userID, from: familyID, by: removingUserID)
    }

    public func getFamilyMembers(familyID: String, by userID: String) async throws -> [(userID: String, role: PermissionRole)] {
        try await permissionService.validateRepositoryAccess(
            userID: userID,
            familyID: familyID,
            action: .view
        )
        return try await permissionService.getFamilyMembers(familyID: familyID)
    }
}