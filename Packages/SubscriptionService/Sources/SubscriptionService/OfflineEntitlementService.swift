import Foundation
import Combine
import SharedModels
import Network

@available(iOS 15.0, macOS 12.0, *)
public final class OfflineEntitlementService: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var isOnline: Bool = true
    @Published public private(set) var isInOfflineMode: Bool = false
    @Published public private(set) var offlineGracePeriodDaysRemaining: Int = 0
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var syncStatus: SyncStatus = .idle

    // MARK: - Private Properties

    private let entitlementRepository: SubscriptionEntitlementRepository
    private let localCacheService: LocalEntitlementCacheService
    private let networkMonitor: NetworkMonitor
    private let offlineGracePeriodDays: Int = 7

    private var backgroundSyncTimer: Timer?
    private var offlineGracePeriodTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        entitlementRepository: SubscriptionEntitlementRepository,
        localCacheService: LocalEntitlementCacheService,
        networkMonitor: NetworkMonitor = DefaultNetworkMonitor()
    ) {
        self.entitlementRepository = entitlementRepository
        self.localCacheService = localCacheService
        self.networkMonitor = networkMonitor

        setupNetworkMonitoring()
        setupBackgroundSync()
        loadOfflineState()
    }

    deinit {
        backgroundSyncTimer?.invalidate()
        offlineGracePeriodTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Gets entitlement with offline support
    public func getEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        if isOnline {
            // Online: Try to fetch from server first
            do {
                let entitlement = try await entitlementRepository.fetchEntitlement(for: familyID)

                if let entitlement = entitlement {
                    // Cache the fresh entitlement
                    try await localCacheService.cacheEntitlement(entitlement)
                    await updateLastSyncDate()
                }

                return entitlement
            } catch {
                // Network error - fall back to cache
                print("Failed to fetch from server, falling back to cache: \(error)")
                return try await getCachedEntitlement(for: familyID)
            }
        } else {
            // Offline: Use cached entitlement with grace period check
            return try await getCachedEntitlement(for: familyID)
        }
    }

    /// Validates cached entitlement during offline period
    public func validateOfflineEntitlement(for familyID: String) async throws -> OfflineValidationResult {
        guard let cachedEntitlement = try await localCacheService.getCachedEntitlement(for: familyID) else {
            return .noValidEntitlement
        }

        // Check if entitlement itself is still valid (not expired)
        guard cachedEntitlement.expirationDate > Date() else {
            return .entitlementExpired
        }

        // Check offline grace period
        let offlineStatus = await checkOfflineGracePeriod(for: familyID)

        switch offlineStatus {
        case .withinGracePeriod(let daysRemaining):
            return .valid(entitlement: cachedEntitlement, daysRemaining: daysRemaining)
        case .gracePeriodExpired:
            return .offlineGracePeriodExpired
        case .notStarted:
            // Start offline grace period
            try await startOfflineGracePeriod(for: familyID)
            return .valid(entitlement: cachedEntitlement, daysRemaining: offlineGracePeriodDays)
        }
    }

    /// Handles when connectivity is restored
    public func handleConnectivityRestored() async {
        await MainActor.run {
            self.syncStatus = .syncing
        }

        do {
            // Get all cached entitlements that need syncing
            let cachedEntitlements = try await localCacheService.getAllCachedEntitlements()

            for cachedEntitlement in cachedEntitlements {
                do {
                    // Fetch fresh entitlement from server
                    if let freshEntitlement = try await entitlementRepository.fetchEntitlement(for: cachedEntitlement.familyID) {

                        // Check for conflicts and resolve
                        let resolvedEntitlement = resolveConflicts(
                            cached: cachedEntitlement,
                            server: freshEntitlement
                        )

                        // Update cache with resolved entitlement
                        try await localCacheService.cacheEntitlement(resolvedEntitlement)

                        // Clear offline grace period for this family
                        try await clearOfflineGracePeriod(for: cachedEntitlement.familyID)
                    }
                } catch {
                    print("Failed to sync entitlement for family \(cachedEntitlement.familyID): \(error)")
                }
            }

            await updateLastSyncDate()
            await MainActor.run {
                self.syncStatus = .completed
                self.isInOfflineMode = false
            }

        } catch {
            await MainActor.run {
                self.syncStatus = .failed(error)
            }
            print("Failed to sync after connectivity restored: \(error)")
        }
    }

    /// Forces a background sync when online
    public func forceSync() async throws {
        guard isOnline else {
            throw OfflineError.noNetworkConnection
        }

        await handleConnectivityRestored()
    }

    /// Preloads entitlement for offline use
    public func preloadEntitlement(for familyID: String) async throws {
        guard isOnline else {
            throw OfflineError.noNetworkConnection
        }

        if let entitlement = try await entitlementRepository.fetchEntitlement(for: familyID) {
            try await localCacheService.cacheEntitlement(entitlement)
        }
    }

    /// Clears all offline data
    public func clearOfflineData() async throws {
        try await localCacheService.clearAllCache()
        try await clearAllOfflineGracePeriods()

        await MainActor.run {
            self.isInOfflineMode = false
            self.offlineGracePeriodDaysRemaining = 0
            self.lastSyncDate = nil
        }
    }

    // MARK: - Private Methods

    private func setupNetworkMonitoring() {
        networkMonitor.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOnline = isConnected

                if isConnected {
                    // Connectivity restored
                    Task {
                        await self?.handleConnectivityRestored()
                    }
                } else {
                    // Went offline
                    self?.isInOfflineMode = true
                }
            }
            .store(in: &cancellables)
    }

    private func setupBackgroundSync() {
        // Sync every 6 hours when online
        backgroundSyncTimer = Timer.scheduledTimer(withTimeInterval: 21600, repeats: true) { [weak self] _ in
            guard let self = self, self.isOnline else { return }

            Task {
                try? await self.forceSync()
            }
        }

        // Check offline grace periods every hour
        offlineGracePeriodTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.checkAllOfflineGracePeriods()
            }
        }
    }

    private func loadOfflineState() {
        Task {
            // Check if any families are in offline grace period
            let hasOfflineData = try? await localCacheService.hasOfflineGracePeriods()

            await MainActor.run {
                self.isInOfflineMode = hasOfflineData ?? false
                self.lastSyncDate = self.localCacheService.getLastSyncDate()
            }
        }
    }

    private func getCachedEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        let cachedEntitlement = try await localCacheService.getCachedEntitlement(for: familyID)

        if cachedEntitlement != nil {
            // Validate against offline grace period
            let validation = try await validateOfflineEntitlement(for: familyID)

            switch validation {
            case .valid(let entitlement, _):
                return entitlement
            case .offlineGracePeriodExpired, .entitlementExpired, .noValidEntitlement:
                return nil
            }
        }

        return nil
    }

    private func checkOfflineGracePeriod(for familyID: String) async -> OfflineGracePeriodStatus {
        guard let startDate = try? await localCacheService.getOfflineGracePeriodStart(for: familyID) else {
            return .notStarted
        }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let daysRemaining = max(0, offlineGracePeriodDays - daysSinceStart)

        if daysRemaining > 0 {
            await MainActor.run {
                self.offlineGracePeriodDaysRemaining = daysRemaining
            }
            return .withinGracePeriod(daysRemaining: daysRemaining)
        } else {
            await MainActor.run {
                self.offlineGracePeriodDaysRemaining = 0
            }
            return .gracePeriodExpired
        }
    }

    private func startOfflineGracePeriod(for familyID: String) async throws {
        try await localCacheService.setOfflineGracePeriodStart(for: familyID, date: Date())

        await MainActor.run {
            self.isInOfflineMode = true
            self.offlineGracePeriodDaysRemaining = self.offlineGracePeriodDays
        }
    }

    private func clearOfflineGracePeriod(for familyID: String) async throws {
        try await localCacheService.clearOfflineGracePeriodStart(for: familyID)
    }

    private func clearAllOfflineGracePeriods() async throws {
        try await localCacheService.clearAllOfflineGracePeriods()
    }

    private func checkAllOfflineGracePeriods() async {
        // This would check all cached families for expired grace periods
        // Implementation would depend on the specific cache structure
    }

    private func resolveConflicts(
        cached: SubscriptionEntitlement,
        server: SubscriptionEntitlement
    ) -> SubscriptionEntitlement {
        // Simple conflict resolution: server wins for most fields
        // but preserve any local changes that make sense

        var resolved = server

        // If cached has a more recent lastValidatedAt, it might have been validated offline
        if cached.lastValidatedAt > server.lastValidatedAt {
            resolved.lastValidatedAt = cached.lastValidatedAt
        }

        return resolved
    }

    private func updateLastSyncDate() async {
        let now = Date()
        try? await localCacheService.setLastSyncDate(now)

        await MainActor.run {
            self.lastSyncDate = now
        }
    }
}

// MARK: - Supporting Types

public enum OfflineValidationResult {
    case valid(entitlement: SubscriptionEntitlement, daysRemaining: Int)
    case noValidEntitlement
    case entitlementExpired
    case offlineGracePeriodExpired
}

public enum OfflineGracePeriodStatus {
    case notStarted
    case withinGracePeriod(daysRemaining: Int)
    case gracePeriodExpired
}

public enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

public enum OfflineError: LocalizedError {
    case noNetworkConnection
    case cacheCorrupted
    case offlineGracePeriodExpired

    public var errorDescription: String? {
        switch self {
        case .noNetworkConnection:
            return "No network connection available"
        case .cacheCorrupted:
            return "Local cache is corrupted"
        case .offlineGracePeriodExpired:
            return "Offline grace period has expired. Please connect to the internet."
        }
    }
}

// MARK: - Local Cache Service Protocol

public protocol LocalEntitlementCacheService {
    func cacheEntitlement(_ entitlement: SubscriptionEntitlement) async throws
    func getCachedEntitlement(for familyID: String) async throws -> SubscriptionEntitlement?
    func getAllCachedEntitlements() async throws -> [SubscriptionEntitlement]
    func clearCache(for familyID: String) async throws
    func clearAllCache() async throws

    func setOfflineGracePeriodStart(for familyID: String, date: Date) async throws
    func getOfflineGracePeriodStart(for familyID: String) async throws -> Date?
    func clearOfflineGracePeriodStart(for familyID: String) async throws
    func clearAllOfflineGracePeriods() async throws
    func hasOfflineGracePeriods() async throws -> Bool

    func setLastSyncDate(_ date: Date) async throws
    func getLastSyncDate() -> Date?
}

// MARK: - Network Monitor Protocol

public protocol NetworkMonitor {
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
    var isConnected: Bool { get }
}

@available(iOS 15.0, macOS 12.0, *)
public final class DefaultNetworkMonitor: NetworkMonitor {

    @Published private var connectionStatus: Bool = true

    public var isConnectedPublisher: AnyPublisher<Bool, Never> {
        $connectionStatus.eraseToAnyPublisher()
    }

    public var isConnected: Bool {
        connectionStatus
    }

    private let pathMonitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    public init() {
        pathMonitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        pathMonitor.cancel()
    }

    private func startMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.connectionStatus = path.status == .satisfied
            }
        }
        pathMonitor.start(queue: queue)
    }
}

// MARK: - Default Local Cache Implementation

@available(iOS 15.0, macOS 12.0, *)
public final class UserDefaultsLocalCacheService: LocalEntitlementCacheService {

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Cache Keys

    private enum CacheKeys {
        static func entitlement(familyID: String) -> String { "cached_entitlement_\(familyID)" }
        static func offlineGracePeriodStart(familyID: String) -> String { "offline_grace_start_\(familyID)" }
        static let lastSyncDate = "last_sync_date"
        static let allFamilies = "cached_families"
    }

    // MARK: - LocalEntitlementCacheService Implementation

    public func cacheEntitlement(_ entitlement: SubscriptionEntitlement) async throws {
        let data = try encoder.encode(entitlement)
        userDefaults.set(data, forKey: CacheKeys.entitlement(familyID: entitlement.familyID))

        // Keep track of all cached families
        var families = userDefaults.stringArray(forKey: CacheKeys.allFamilies) ?? []
        if !families.contains(entitlement.familyID) {
            families.append(entitlement.familyID)
            userDefaults.set(families, forKey: CacheKeys.allFamilies)
        }
    }

    public func getCachedEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        guard let data = userDefaults.data(forKey: CacheKeys.entitlement(familyID: familyID)) else {
            return nil
        }
        return try decoder.decode(SubscriptionEntitlement.self, from: data)
    }

    public func getAllCachedEntitlements() async throws -> [SubscriptionEntitlement] {
        let families = userDefaults.stringArray(forKey: CacheKeys.allFamilies) ?? []
        var entitlements: [SubscriptionEntitlement] = []

        for familyID in families {
            if let entitlement = try await getCachedEntitlement(for: familyID) {
                entitlements.append(entitlement)
            }
        }

        return entitlements
    }

    public func clearCache(for familyID: String) async throws {
        userDefaults.removeObject(forKey: CacheKeys.entitlement(familyID: familyID))

        var families = userDefaults.stringArray(forKey: CacheKeys.allFamilies) ?? []
        families.removeAll { $0 == familyID }
        userDefaults.set(families, forKey: CacheKeys.allFamilies)
    }

    public func clearAllCache() async throws {
        let families = userDefaults.stringArray(forKey: CacheKeys.allFamilies) ?? []
        for familyID in families {
            userDefaults.removeObject(forKey: CacheKeys.entitlement(familyID: familyID))
        }
        userDefaults.removeObject(forKey: CacheKeys.allFamilies)
    }

    public func setOfflineGracePeriodStart(for familyID: String, date: Date) async throws {
        userDefaults.set(date, forKey: CacheKeys.offlineGracePeriodStart(familyID: familyID))
    }

    public func getOfflineGracePeriodStart(for familyID: String) async throws -> Date? {
        return userDefaults.object(forKey: CacheKeys.offlineGracePeriodStart(familyID: familyID)) as? Date
    }

    public func clearOfflineGracePeriodStart(for familyID: String) async throws {
        userDefaults.removeObject(forKey: CacheKeys.offlineGracePeriodStart(familyID: familyID))
    }

    public func clearAllOfflineGracePeriods() async throws {
        let families = userDefaults.stringArray(forKey: CacheKeys.allFamilies) ?? []
        for familyID in families {
            userDefaults.removeObject(forKey: CacheKeys.offlineGracePeriodStart(familyID: familyID))
        }
    }

    public func hasOfflineGracePeriods() async throws -> Bool {
        let families = userDefaults.stringArray(forKey: CacheKeys.allFamilies) ?? []
        for familyID in families {
            if userDefaults.object(forKey: CacheKeys.offlineGracePeriodStart(familyID: familyID)) != nil {
                return true
            }
        }
        return false
    }

    public func setLastSyncDate(_ date: Date) async throws {
        userDefaults.set(date, forKey: CacheKeys.lastSyncDate)
    }

    public func getLastSyncDate() -> Date? {
        return userDefaults.object(forKey: CacheKeys.lastSyncDate) as? Date
    }
}