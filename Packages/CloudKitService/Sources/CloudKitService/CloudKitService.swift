import Foundation
import SharedModels

// MARK: - Supporting Types

public struct RedemptionStats {
    public let totalRedemptions: Int
    public let totalPointsSpent: Int
    public let totalTimeGranted: Int // in minutes
    public let totalTimeUsed: Int // in minutes
    public let activeRedemptions: Int

    public init(totalRedemptions: Int, totalPointsSpent: Int, totalTimeGranted: Int, totalTimeUsed: Int, activeRedemptions: Int) {
        self.totalRedemptions = totalRedemptions
        self.totalPointsSpent = totalPointsSpent
        self.totalTimeGranted = totalTimeGranted
        self.totalTimeUsed = totalTimeUsed
        self.activeRedemptions = activeRedemptions
    }

    public var efficiencyRatio: Double {
        guard totalTimeGranted > 0 else { return 0.0 }
        return Double(totalTimeUsed) / Double(totalTimeGranted)
    }

    public var averagePointsPerMinute: Double {
        guard totalTimeGranted > 0 else { return 0.0 }
        return Double(totalPointsSpent) / Double(totalTimeGranted)
    }
}

/// Main CloudKit service that provides access to all repository implementations
@available(iOS 15.0, macOS 12.0, *)
public class CloudKitService {
    public static let shared = CloudKitService()

    // Repository instances
    private let _childProfileRepository: ChildProfileRepository
    private let _appCategorizationRepository: SharedModels.AppCategorizationRepository
    private let _usageSessionRepository: SharedModels.UsageSessionRepository
    private let _pointTransactionRepository: SharedModels.PointTransactionRepository
    private let _pointToTimeRedemptionRepository: SharedModels.PointToTimeRedemptionRepository
    private let _familyRepository: SharedModels.FamilyRepository
    private let _parentCoordinationRepository: ParentCoordinationRepository
    private let _rewardRepository: RewardRepository
    private let _screenTimeRepository: ScreenTimeRepository
    
    // Public repository properties
    public let rewardRepository: SharedModels.RewardRepository
    public let screenTimeRepository: SharedModels.ScreenTimeSessionRepository

    private init() {
        // Initialize all repository implementations
        self._childProfileRepository = MockChildProfileRepository()
        self._appCategorizationRepository = CloudKitService.CloudKitAppCategorizationRepository()
        self._usageSessionRepository = CloudKitService.UsageSessionRepository()
        self._pointTransactionRepository = CloudKitService.PointTransactionRepository()
        self._pointToTimeRedemptionRepository = CloudKitService.PointToTimeRedemptionRepository()
        self._familyRepository = CloudKitService.FamilyRepository()
        self._parentCoordinationRepository = CloudKitParentCoordinationRepository()
        // Initialize new repositories
        self._rewardRepository = RewardRepository()
        self._screenTimeRepository = ScreenTimeRepository()
        
        // Initialize public repository properties
        self.rewardRepository = self._rewardRepository
        self.screenTimeRepository = self._screenTimeRepository
    }

    // MARK: - Nested Repository Types

    /// Nested AppCategorizationRepository class for easy instantiation in tests
    @available(iOS 15.0, macOS 12.0, *)
    public class CloudKitAppCategorizationRepository: SharedModels.AppCategorizationRepository {
        public init() {}

        public func createAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
            try await saveCategorization(categorization)
            return categorization
        }

        public func fetchAppCategorization(id: String) async throws -> AppCategorization? {
            return nil
        }

        public func fetchAppCategorizations(for childID: String) async throws -> [AppCategorization] {
            return try await fetchCategorizations(for: childID)
        }

        public func updateAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
            try await saveCategorization(categorization)
            return categorization
        }

        public func deleteAppCategorization(id: String) async throws {
            try await deleteCategorization(with: id)
        }

        // Original methods for backward compatibility
        public func saveCategorization(_ categorization: AppCategorization) async throws {
            print("Saving categorization for app: \(categorization.appBundleID)")
        }

        public func fetchCategorizations(for childProfileID: String) async throws -> [AppCategorization] {
            return []
        }

        public func deleteCategorization(with id: String) async throws {
            print("Deleting categorization with id: \(id)")
        }
    }

    /// Nested UsageSessionRepository class for easy instantiation in tests
    @available(iOS 15.0, macOS 12.0, *)
    public class UsageSessionRepository: SharedModels.UsageSessionRepository {
        public init() {}

        public func createSession(_ session: UsageSession) async throws -> UsageSession {
            print("Creating usage session for child: \(session.childProfileID)")
            return session
        }

        public func fetchSession(id: String) async throws -> UsageSession? {
            return nil
        }

        public func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
            return []
        }

        public func updateSession(_ session: UsageSession) async throws -> UsageSession {
            print("Updating usage session: \(session.id)")
            return session
        }

        public func deleteSession(id: String) async throws {
            print("Deleting usage session: \(id)")
        }

        // Additional methods for compatibility with existing tests
        public func save(session: UsageSession) {
            print("Saving usage session for app: \(session.appBundleID)")
        }
    }

    /// Nested PointTransactionRepository class for easy instantiation in tests
    @available(iOS 15.0, macOS 12.0, *)
    public class PointTransactionRepository: SharedModels.PointTransactionRepository {
        public init() {}

        public func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
            print("Creating point transaction for child: \(transaction.childProfileID)")
            return transaction
        }

        public func fetchTransaction(id: String) async throws -> PointTransaction? {
            return nil
        }

        public func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
            return []
        }

        public func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
            return []
        }

        public func deleteTransaction(id: String) async throws {
            print("Deleting point transaction: \(id)")
        }

        // Additional methods for compatibility with existing tests
        public func save(transaction: PointTransaction) {
            print("Saving point transaction for child: \(transaction.childProfileID)")
        }
    }

    /// Nested PointToTimeRedemptionRepository class for easy instantiation in tests
    @available(iOS 15.0, macOS 12.0, *)
    public class PointToTimeRedemptionRepository: SharedModels.PointToTimeRedemptionRepository {
        public init() {}

        public func createPointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
            print("Creating point-to-time redemption for child: \(redemption.childProfileID)")
            return redemption
        }

        public func fetchPointToTimeRedemption(id: String) async throws -> PointToTimeRedemption? {
            return nil
        }

        public func fetchPointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
            return []
        }

        public func fetchActivePointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
            return []
        }

        public func updatePointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
            print("Updating point-to-time redemption: \(redemption.id)")
            return redemption
        }

        public func deletePointToTimeRedemption(id: String) async throws {
            print("Deleting point-to-time redemption: \(id)")
        }

        // Additional methods for compatibility with existing tests
        public func fetchRedemptions(for childID: String, dateRange: DateRange?) async throws -> [PointToTimeRedemption] {
            print("Fetching redemptions for child: \(childID) in date range")
            return []
        }

        public func fetchRedemptions(for childID: String, status: RedemptionStatus) async throws -> [PointToTimeRedemption] {
            print("Fetching redemptions for child: \(childID) with status: \(status.rawValue)")
            return []
        }

        public func markExpiredRedemptions() async throws -> Int {
            print("Marking expired redemptions")
            return 0
        }

        public func getRedemptionStats(for childID: String) async throws -> RedemptionStats {
            print("Calculating redemption stats for child: \(childID)")
            return RedemptionStats(
                totalRedemptions: 0,
                totalPointsSpent: 0,
                totalTimeGranted: 0,
                totalTimeUsed: 0,
                activeRedemptions: 0
            )
        }
    }

    /// Nested FamilyRepository class for easy instantiation in tests
    @available(iOS 15.0, macOS 12.0, *)
    public class FamilyRepository: SharedModels.FamilyRepository {
        public init() {}

        public func createFamily(_ family: Family) async throws -> Family {
            print("Creating family: \(family.name)")
            return family
        }

        public func fetchFamily(id: String) async throws -> Family? {
            // Mock implementation for now
            return nil
        }

        public func fetchFamilies(for userID: String) async throws -> [Family] {
            return []
        }

        public func updateFamily(_ family: Family) async throws -> Family {
            print("Updating family: \(family.name) with trial metadata")
            return family
        }

        public func deleteFamily(id: String) async throws {
            print("Deleting family: \(id)")
        }
    }
    
    /// Nested RewardRepository class for easy instantiation in tests
    @available(iOS 15.0, macOS 12.0, *)
    public class RewardRepository: SharedModels.RewardRepository {
        public init() {}

        public func createReward(_ reward: Reward) async throws -> Reward {
            print("Creating reward: \(reward.name)")
            return reward
        }

        public func fetchReward(id: String) async throws -> Reward? {
            return nil
        }

        public func fetchRewards() async throws -> [Reward] {
            return []
        }

        public func updateReward(_ reward: Reward) async throws -> Reward {
            print("Updating reward: \(reward.name)")
            return reward
        }

        public func deleteReward(id: String) async throws {
            print("Deleting reward: \(id)")
        }
    }
    
    /// Nested ScreenTimeRepository class for easy instantiation in tests
    @available(iOS 15.0, macOS 12.0, *)
    public class ScreenTimeRepository: SharedModels.ScreenTimeSessionRepository {
        public init() {}

        public func createSession(_ session: ScreenTimeSession) async throws -> ScreenTimeSession {
            print("Creating screen time session for child: \(session.childProfileID)")
            return session
        }

        public func fetchSession(id: String) async throws -> ScreenTimeSession? {
            return nil
        }

        public func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [ScreenTimeSession] {
            return []
        }

        public func updateSession(_ session: ScreenTimeSession) async throws -> ScreenTimeSession {
            print("Updating screen time session: \(session.id)")
            return session
        }

        public func deleteSession(id: String) async throws {
            print("Deleting screen time session: \(id)")
        }
    }
}

// MARK: - Repository Protocol Conformance

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: ChildProfileRepository {
    public func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        return try await _childProfileRepository.createChild(child)
    }

    public func fetchChild(id: String) async throws -> ChildProfile? {
        return try await _childProfileRepository.fetchChild(id: id)
    }

    public func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        return try await _childProfileRepository.fetchChildren(for: familyID)
    }

    public func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        return try await _childProfileRepository.updateChild(child)
    }

    public func deleteChild(id: String) async throws {
        try await _childProfileRepository.deleteChild(id: id)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: SharedModels.AppCategorizationRepository {
    public func createAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        return try await _appCategorizationRepository.createAppCategorization(categorization)
    }

    public func fetchAppCategorization(id: String) async throws -> AppCategorization? {
        return try await _appCategorizationRepository.fetchAppCategorization(id: id)
    }

    public func fetchAppCategorizations(for childID: String) async throws -> [AppCategorization] {
        return try await _appCategorizationRepository.fetchAppCategorizations(for: childID)
    }

    public func updateAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        return try await _appCategorizationRepository.updateAppCategorization(categorization)
    }

    public func deleteAppCategorization(id: String) async throws {
        try await _appCategorizationRepository.deleteAppCategorization(id: id)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: SharedModels.UsageSessionRepository {
    public func createSession(_ session: UsageSession) async throws -> UsageSession {
        return try await _usageSessionRepository.createSession(session)
    }

    public func fetchSession(id: String) async throws -> UsageSession? {
        return try await _usageSessionRepository.fetchSession(id: id)
    }

    public func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
        return try await _usageSessionRepository.fetchSessions(for: childID, dateRange: dateRange)
    }

    public func updateSession(_ session: UsageSession) async throws -> UsageSession {
        return try await _usageSessionRepository.updateSession(session)
    }

    public func deleteSession(id: String) async throws {
        try await _usageSessionRepository.deleteSession(id: id)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: SharedModels.PointTransactionRepository {
    public func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        return try await _pointTransactionRepository.createTransaction(transaction)
    }

    public func fetchTransaction(id: String) async throws -> PointTransaction? {
        return try await _pointTransactionRepository.fetchTransaction(id: id)
    }

    public func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        return try await _pointTransactionRepository.fetchTransactions(for: childID, limit: limit)
    }

    public func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        return try await _pointTransactionRepository.fetchTransactions(for: childID, dateRange: dateRange)
    }

    public func deleteTransaction(id: String) async throws {
        try await _pointTransactionRepository.deleteTransaction(id: id)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: SharedModels.PointToTimeRedemptionRepository {
    public func createPointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
        return try await _pointToTimeRedemptionRepository.createPointToTimeRedemption(redemption)
    }

    public func fetchPointToTimeRedemption(id: String) async throws -> PointToTimeRedemption? {
        return try await _pointToTimeRedemptionRepository.fetchPointToTimeRedemption(id: id)
    }

    public func fetchPointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
        return try await _pointToTimeRedemptionRepository.fetchPointToTimeRedemptions(for: childID)
    }

    public func fetchActivePointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
        return try await _pointToTimeRedemptionRepository.fetchActivePointToTimeRedemptions(for: childID)
    }

    public func updatePointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption {
        return try await _pointToTimeRedemptionRepository.updatePointToTimeRedemption(redemption)
    }

    public func deletePointToTimeRedemption(id: String) async throws {
        try await _pointToTimeRedemptionRepository.deletePointToTimeRedemption(id: id)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: SharedModels.FamilyRepository {
    public func createFamily(_ family: Family) async throws -> Family {
        return try await _familyRepository.createFamily(family)
    }

    public func fetchFamily(id: String) async throws -> Family? {
        return try await _familyRepository.fetchFamily(id: id)
    }

    public func fetchFamilies(for userID: String) async throws -> [Family] {
        return try await _familyRepository.fetchFamilies(for: userID)
    }

    public func updateFamily(_ family: Family) async throws -> Family {
        return try await _familyRepository.updateFamily(family)
    }

    public func deleteFamily(id: String) async throws {
        try await _familyRepository.deleteFamily(id: id)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: ParentCoordinationRepository {
    public func createCoordinationEvent(_ event: ParentCoordinationEvent) async throws -> ParentCoordinationEvent {
        return try await _parentCoordinationRepository.createCoordinationEvent(event)
    }

    public func fetchCoordinationEvents(for familyID: UUID) async throws -> [ParentCoordinationEvent] {
        return try await _parentCoordinationRepository.fetchCoordinationEvents(for: familyID)
    }

    public func fetchCoordinationEvents(for familyID: UUID, dateRange: DateRange?) async throws -> [ParentCoordinationEvent] {
        return try await _parentCoordinationRepository.fetchCoordinationEvents(for: familyID, dateRange: dateRange)
    }

    public func deleteCoordinationEvent(id: UUID) async throws {
        try await _parentCoordinationRepository.deleteCoordinationEvent(id: id)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitService: SharedModels.RewardRepository {
    public func createReward(_ reward: Reward) async throws -> Reward {
        return try await _rewardRepository.createReward(reward)
    }

    public func fetchReward(id: String) async throws -> Reward? {
        return try await _rewardRepository.fetchReward(id: id)
    }

    public func fetchRewards() async throws -> [Reward] {
        return try await _rewardRepository.fetchRewards()
    }

    public func updateReward(_ reward: Reward) async throws -> Reward {
        return try await _rewardRepository.updateReward(reward)
    }

    public func deleteReward(id: String) async throws {
        try await _rewardRepository.deleteReward(id: id)
    }
}

// REMOVED: ScreenTimeSessionRepository extension to resolve method ambiguity
// The UsageSessionRepository extension already provides the deleteSession method
// with the same signature, causing compilation errors.

// MARK: - Mock Child Profile Repository

/// Temporary mock implementation for ChildProfileRepository
/// In a real app, this would be implemented with actual CloudKit operations
@available(iOS 15.0, macOS 12.0, *)
private class MockChildProfileRepository: ChildProfileRepository {
    private var mockChildren: [String: ChildProfile] = [:]

    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        mockChildren[child.id] = child
        print("Mock: Created child profile: \(child.name)")
        return child
    }

    func fetchChild(id: String) async throws -> ChildProfile? {
        if let existing = mockChildren[id] {
            return existing
        }

        // Return a mock child for demo purposes
        if id == "mock-child-id" {
            let mockChild = ChildProfile(
                id: id,
                familyID: "mock-family-id",
                name: "Demo Child",
                avatarAssetURL: nil,
                birthDate: Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date(),
                pointBalance: 450,
                totalPointsEarned: 1250
            )
            mockChildren[id] = mockChild
            return mockChild
        }

        return nil
    }

    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        return Array(mockChildren.values.filter { $0.familyID == familyID })
    }

    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        mockChildren[child.id] = child
        print("Mock: Updated child profile: \(child.name), Balance: \(child.pointBalance)")
        return child
    }

    func deleteChild(id: String) async throws {
        mockChildren.removeValue(forKey: id)
        print("Mock: Deleted child profile: \(id)")
    }
}