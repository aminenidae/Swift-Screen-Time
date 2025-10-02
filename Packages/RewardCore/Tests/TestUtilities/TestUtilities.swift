import Foundation
import SharedModels
@testable import RewardCore
import CloudKit
import CloudKitService

// MARK: - Mock Repositories

public class MockChildProfileRepository: ChildProfileRepository {
    public var mockChild: ChildProfile?
    public var mockChildren: [ChildProfile] = []
    public var createdChildren: [ChildProfile] = []
    public var updatedChildren: [ChildProfile] = []
    public var shouldThrowError = false
    public var createChildCalled = false
    public var updateChildCalled = false
    public var deleteChildCalled = false
    public var fetchChildCalled = false
    public var fetchChildrenCalled = false

    public init() {}

    public func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError { throw MockError.repositoryError }
        createChildCalled = true
        createdChildren.append(child)
        return child
    }

    public func fetchChild(id: String) async throws -> ChildProfile? {
        if shouldThrowError { throw MockError.repositoryError }
        fetchChildCalled = true
        return mockChild?.id == id ? mockChild : nil
    }

    public func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        if shouldThrowError { throw MockError.repositoryError }
        fetchChildrenCalled = true
        if let child = mockChild, child.familyID == familyID {
            return [child]
        }
        return mockChildren.filter { $0.familyID == familyID }
    }

    public func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError { throw MockError.repositoryError }
        updateChildCalled = true
        updatedChildren.append(child)
        return child
    }

    public func deleteChild(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
        deleteChildCalled = true
    }
}

public class MockAppCategorizationRepository: SharedModels.AppCategorizationRepository {
    public var mockCategorization: AppCategorization?
    public var mockCategorizations: [AppCategorization] = []
    public var createdCategorizations: [AppCategorization] = []
    public var updatedCategorizations: [AppCategorization] = []
    public var shouldThrowError = false
    public var createCalled = false
    public var updateCalled = false
    public var deleteCalled = false
    public var fetchCalled = false

    public init() {}

    public func createAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.repositoryError }
        createCalled = true
        createdCategorizations.append(categorization)
        return categorization
    }

    public func fetchAppCategorization(id: String) async throws -> AppCategorization? {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        return mockCategorization?.id == id ? mockCategorization : nil
    }

    public func fetchAppCategorizations(for childID: String) async throws -> [AppCategorization] {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        if let categorization = mockCategorization, categorization.childProfileID == childID {
            return [categorization]
        }
        return mockCategorizations.filter { $0.childProfileID == childID }
    }

    public func updateAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.repositoryError }
        updateCalled = true
        updatedCategorizations.append(categorization)
        return categorization
    }

    public func deleteAppCategorization(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
        deleteCalled = true
    }
}

public class MockFamilyRepository: FamilyRepository {
    public var mockFamily: Family?
    public var mockFamilies: [Family] = []
    public var families: [String: Family] = [:] // Add this property for tests that need it
    public var createdFamilies: [Family] = []
    public var updatedFamilies: [Family] = []
    public var shouldThrowError = false
    public var createFamilyCalled = false
    public var updateFamilyCalled = false
    public var deleteFamilyCalled = false
    public var fetchFamilyCalled = false

    public init() {}

    public func createFamily(_ family: Family) async throws -> Family {
        if shouldThrowError { throw MockError.repositoryError }
        createFamilyCalled = true
        createdFamilies.append(family)
        mockFamily = family
        families[family.id] = family // Also update the families dictionary
        return family
    }

    public func fetchFamily(id: String) async throws -> Family? {
        if shouldThrowError { throw MockError.repositoryError }
        fetchFamilyCalled = true
        return mockFamily?.id == id ? mockFamily : families[id]
    }

    public func fetchFamilies(for userID: String) async throws -> [Family] {
        if shouldThrowError { throw MockError.repositoryError }
        if let family = mockFamily,
           family.ownerUserID == userID || family.sharedWithUserIDs.contains(userID) {
            return [family]
        }
        return mockFamilies.filter { family in
            family.ownerUserID == userID || family.sharedWithUserIDs.contains(userID)
        }
    }

    public func updateFamily(_ family: Family) async throws -> Family {
        if shouldThrowError { throw MockError.repositoryError }
        updateFamilyCalled = true
        updatedFamilies.append(family)
        mockFamily = family
        families[family.id] = family // Also update the families dictionary
        return family
    }

    public func deleteFamily(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
        deleteFamilyCalled = true
        if mockFamily?.id == id {
            mockFamily = nil
        }
        families.removeValue(forKey: id) // Also remove from families dictionary
    }
}

public class MockUsageSessionRepository: SharedModels.UsageSessionRepository {
    public var mockSession: UsageSession?
    public var mockSessions: [UsageSession] = []
    public var createdSessions: [UsageSession] = []
    public var updatedSessions: [UsageSession] = []
    public var shouldThrowError = false
    public var createCalled = false
    public var updateCalled = false
    public var deleteCalled = false
    public var fetchCalled = false

    public init() {}

    public func createSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError { throw MockError.repositoryError }
        createCalled = true
        createdSessions.append(session)
        return session
    }

    public func fetchSession(id: String) async throws -> UsageSession? {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        return mockSession?.id == id ? mockSession : nil
    }

    public func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        if let session = mockSession, session.childProfileID == childID {
            return [session]
        }
        return mockSessions.filter { $0.childProfileID == childID }
    }

    public func updateSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError { throw MockError.repositoryError }
        updateCalled = true
        updatedSessions.append(session)
        return session
    }

    public func deleteSession(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
        deleteCalled = true
    }
}

public class MockPointTransactionRepository: SharedModels.PointTransactionRepository {
    public var mockTransaction: PointTransaction?
    public var mockTransactions: [PointTransaction] = []
    public var createdTransactions: [PointTransaction] = []
    public var updatedTransactions: [PointTransaction] = []
    public var shouldThrowError = false
    public var createCalled = false
    public var updateCalled = false
    public var deleteCalled = false
    public var fetchCalled = false

    public init() {}

    public func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        if shouldThrowError { throw MockError.repositoryError }
        createCalled = true
        createdTransactions.append(transaction)
        return transaction
    }

    public func fetchTransaction(id: String) async throws -> PointTransaction? {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        return mockTransaction?.id == id ? mockTransaction : nil
    }

    public func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        if let transaction = mockTransaction, transaction.childProfileID == childID {
            return [transaction]
        }
        return mockTransactions.filter { $0.childProfileID == childID }
    }

    public func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        if let transaction = mockTransaction, transaction.childProfileID == childID {
            return [transaction]
        }
        return mockTransactions.filter { $0.childProfileID == childID }
    }

    public func deleteTransaction(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
        deleteCalled = true
    }
}

public class MockPointToTimeRedemptionRepository: SharedModels.PointToTimeRedemptionRepository {
    public var mockRedemption: PointToTimeRedemption?
    public var mockRedemptions: [PointToTimeRedemption] = []
    public var createdRedemptions: [PointToTimeRedemption] = []
    public var updatedRedemptions: [PointToTimeRedemption] = []
    public var shouldThrowError = false
    public var createCalled = false
    public var updateCalled = false
    public var deleteCalled = false
    public var fetchCalled = false

    public init() {}

    public func createPointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
        if shouldThrowError { throw MockError.repositoryError }
        createCalled = true
        createdRedemptions.append(redemption)
        return redemption
    }

    public func fetchPointToTimeRedemption(id: String) async throws -> PointToTimeRedemption? {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        return mockRedemption?.id == id ? mockRedemption : nil
    }

    public func fetchPointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        if let redemption = mockRedemption, redemption.childProfileID == childID {
            return [redemption]
        }
        return mockRedemptions.filter { $0.childProfileID == childID }
    }

    public func fetchActivePointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        return mockRedemptions.filter { $0.childProfileID == childID && $0.status == .active }
    }

    public func updatePointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
        if shouldThrowError { throw MockError.repositoryError }
        updateCalled = true
        updatedRedemptions.append(redemption)
        return redemption
    }

    public func deletePointToTimeRedemption(id: String) async throws {
        if shouldThrowError { throw MockError.repositoryError }
        deleteCalled = true
    }
}

// MARK: - Mock CloudKit Service

public class MockCloudKitService {
    public var mockFamily: Family?
    public var mockFamilies: [Family] = []
    public var shouldThrowError = false
    
    public init() {}
    
    public func fetchFamily(id: String) async throws -> Family? {
        if shouldThrowError { throw MockError.cloudKitError }
        return mockFamily?.id == id ? mockFamily : nil
    }
    
    public func fetchFamilies(for userID: String) async throws -> [Family] {
        if shouldThrowError { throw MockError.cloudKitError }
        if let family = mockFamily,
           family.ownerUserID == userID || family.sharedWithUserIDs.contains(userID) {
            return [family]
        }
        return mockFamilies.filter { family in
            family.ownerUserID == userID || family.sharedWithUserIDs.contains(userID)
        }
    }
    
    public func saveFamily(_ family: Family) async throws {
        if shouldThrowError { throw MockError.cloudKitError }
        mockFamily = family
    }
}

// MARK: - Mock Family Invitation Repository

public class MockFamilyInvitationRepository: FamilyInvitationRepository {
    public var invitations: [UUID: FamilyInvitation] = [:]
    public var shouldThrowError = false
    public var createCalled = false
    public var fetchCalled = false
    public var updateCalled = false

    public init() {}

    public func createInvitation(_ invitation: FamilyInvitation) async throws -> FamilyInvitation {
        if shouldThrowError { throw MockError.repositoryError }
        createCalled = true
        invitations[invitation.token] = invitation
        return invitation
    }

    public func fetchInvitation(by token: UUID) async throws -> FamilyInvitation? {
        if shouldThrowError { throw MockError.repositoryError }
        fetchCalled = true
        return invitations[token]
    }

    public func fetchInvitations(for familyID: String) async throws -> [FamilyInvitation] {
        if shouldThrowError { throw MockError.repositoryError }
        return Array(invitations.values).filter { $0.familyID == familyID }
    }

    public func fetchInvitations(by invitingUserID: String) async throws -> [FamilyInvitation] {
        if shouldThrowError { throw MockError.repositoryError }
        return Array(invitations.values).filter { $0.invitingUserID == invitingUserID }
    }

    public func updateInvitation(_ invitation: FamilyInvitation) async throws -> FamilyInvitation {
        if shouldThrowError { throw MockError.repositoryError }
        updateCalled = true
        invitations[invitation.token] = invitation
        return invitation
    }

    public func deleteInvitation(id: UUID) async throws {
        if shouldThrowError { throw MockError.repositoryError }
        invitations.removeValue(forKey: id)
    }

    public func deleteExpiredInvitations() async throws {
        if shouldThrowError { throw MockError.repositoryError }
        let now = Date()
        invitations = invitations.filter { $0.value.expiresAt > now }
    }
}

// MARK: - Mock Error

public enum MockError: Error {
    case repositoryError
    case cloudKitError
}

extension MockError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .repositoryError:
            return "Mock repository error"
        case .cloudKitError:
            return "Mock CloudKit error"
        }
    }
}

// MARK: - Test Data Helpers

public func createMockFamily(id: String = UUID().uuidString, name: String = "Test Family", ownerUserID: String, sharedWithUserIDs: [String] = [], childProfileIDs: [String] = []) -> Family {
    return Family(
        id: id,
        name: name,
        createdAt: Date(),
        ownerUserID: ownerUserID,
        sharedWithUserIDs: sharedWithUserIDs,
        childProfileIDs: childProfileIDs,
        userRoles: [ownerUserID: .owner]
    )
}