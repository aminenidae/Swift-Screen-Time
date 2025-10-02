import Foundation
import SharedModels

#if canImport(FamilyControls) && !os(macOS)
import FamilyControls
import ManagedSettings

// MARK: - Type Aliases from FamilyControls (when available on iOS)

/// Public type alias for ApplicationToken from FamilyControls
public typealias ApplicationToken = String

/// Public type alias for AuthorizationStatus from FamilyControls
public typealias AuthorizationStatus = FamilyControls.AuthorizationStatus

/// Public type alias for FamilyActivitySelection from FamilyControls
public typealias FamilyActivitySelection = FamilyControls.FamilyActivitySelection

#else

// MARK: - Fallback Types (when FamilyControls not available)

/// Fallback ApplicationToken for development/testing
public struct ApplicationToken: Hashable {
    public let bundleIdentifier: String

    public init(_ bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
    }
}

/// Fallback AuthorizationStatus for development/testing
public enum AuthorizationStatus: CaseIterable {
    case notDetermined
    case denied
    case approved
}

/// Fallback FamilyActivitySelection for development/testing
public struct FamilyActivitySelection {
    public var applicationTokens: Set<ApplicationToken> = []
    public init() {}
}

#endif

// MARK: - Supporting Types

/// Application information structure
public struct ApplicationInfo {
    public let bundleID: String
    public let displayName: String
    public let category: ApplicationCategory

    public init(bundleID: String, displayName: String, category: ApplicationCategory) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.category = category
    }
}

/// Application category enumeration
public enum ApplicationCategory {
    case education
    case game
    case social
    case productivity
    case entertainment
    case other
}

/// Service responsible for managing Family Controls and ManagedSettings for reward time allocation
@available(iOS 15.0, macOS 10.15, *)
public class FamilyControlsService: ObservableObject {
    public static let shared = FamilyControlsService()

    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published public var isAuthorized: Bool = false

    #if canImport(FamilyControls) && !os(macOS)
    private let store = ManagedSettingsStore()
    private let authorizationCenter = AuthorizationCenter.shared
    #endif

    public init() {
        checkAuthorizationStatus()
        setupAuthorizationObserver()
    }

    // MARK: - Authorization

    /// Requests Family Controls authorization from the parent
    @available(iOS 16.0, *)
    public func requestAuthorization() async throws {
        #if canImport(FamilyControls) && !os(macOS)
        try await authorizationCenter.requestAuthorization(for: .child)
        await MainActor.run {
            checkAuthorizationStatus()
        }
        #else
        // Fallback for testing - simulate authorization
        await MainActor.run {
            self.authorizationStatus = .approved
            self.isAuthorized = true
        }
        #endif
    }

    /// Checks current authorization status
    private func checkAuthorizationStatus() {
        #if canImport(FamilyControls) && !os(macOS)
        authorizationStatus = authorizationCenter.authorizationStatus
        isAuthorized = authorizationStatus == .approved
        #else
        // Fallback for testing
        authorizationStatus = .notDetermined
        isAuthorized = false
        #endif
    }

    private func setupAuthorizationObserver() {
        #if canImport(FamilyControls) && !os(macOS)
        // Note: AuthorizationStatus.values is available in iOS 16.0+
        // For iOS 15.0 compatibility, we'll use a simpler approach
        if #available(iOS 16.0, *) {
            Task {
                for await authStatus in authorizationCenter.$authorizationStatus.values {
                    await MainActor.run {
                        self.authorizationStatus = authStatus
                        self.isAuthorized = authStatus == .approved
                    }
                }
            }
        } else {
            // For iOS 15.0, we'll check status periodically or on app foreground
            // This is a simplified implementation for compatibility
            checkAuthorizationStatus()
        }
        #else
        // Fallback for testing - no authorization observer needed
        checkAuthorizationStatus()
        #endif
    }

    // MARK: - Reward Time Allocation

    /// Allocates reward screen time for a specific app based on a redemption
    public func allocateRewardTime(
        for redemption: PointToTimeRedemption,
        appBundleID: String
    ) async throws -> RewardTimeAllocationResult {
        guard isAuthorized else {
            return .authorizationRequired
        }

        // Validate redemption is active and not expired
        guard redemption.status == .active,
              redemption.expiresAt > Date() else {
            return .redemptionExpired
        }

        // Calculate remaining time
        let remainingMinutes = redemption.timeGrantedMinutes - redemption.timeUsedMinutes
        guard remainingMinutes > 0 else {
            return .noTimeRemaining
        }

        do {
            // Create application token for the specific app
            let appToken = try await createApplicationToken(bundleID: appBundleID)

            // Apply managed settings for reward time
            try await applyRewardTimeSettings(
                appToken: appToken,
                timeMinutes: remainingMinutes,
                redemptionID: redemption.id
            )

            return .success(allocatedMinutes: remainingMinutes)

        } catch {
            return .systemError(error.localizedDescription)
        }
    }

    /// Revokes reward time allocation for a specific redemption
    public func revokeRewardTime(redemptionID: String, appBundleID: String) async throws -> RewardTimeAllocationResult {
        guard isAuthorized else {
            return .authorizationRequired
        }

        do {
            // Remove managed settings for this specific redemption
            try await removeRewardTimeSettings(redemptionID: redemptionID, appBundleID: appBundleID)
            return .success(allocatedMinutes: 0)

        } catch {
            return .systemError(error.localizedDescription)
        }
    }

    /// Updates time usage for a redemption (called when time is actually used)
    public func updateTimeUsage(
        redemptionID: String,
        appBundleID: String,
        usedMinutes: Int
    ) async throws -> RewardTimeAllocationResult {
        guard isAuthorized else {
            return .authorizationRequired
        }

        // In a real implementation, this would track actual usage and update ManagedSettings accordingly
        // For now, we'll simulate the update
        return .success(allocatedMinutes: usedMinutes)
    }

    /// Gets all active reward time allocations for a child
    public func getActiveRewardAllocations(for childID: String) async throws -> [RewardTimeAllocation] {
        guard isAuthorized else {
            throw FamilyControlsError.authorizationRequired
        }

        // In a real implementation, this would query the actual ManagedSettings store
        // For now, return empty array as this is primarily handled by the PointRedemptionService
        return []
    }

    // MARK: - App Discovery and Management

    /// Discovers applications available on the device
    public func discoverApplications() -> FamilyActivitySelection {
        #if targetEnvironment(simulator)
        // Return empty selection for simulator
        return FamilyActivitySelection()
        #else
        // In a real implementation, this would present the FamilyActivityPicker
        // For now, return empty selection
        return FamilyActivitySelection()
        #endif
    }

    /// Gets application information for a given token
    public func getApplicationInfo(for token: ApplicationToken) -> ApplicationInfo? {
        // Placeholder implementation
        return nil
    }

    /// Categorizes an application token
    public func categorizeApplication(_ token: ApplicationToken) -> ApplicationCategory {
        // Placeholder implementation
        return .other
    }

    /// Gets current usage for applications since a specific time
    public func getCurrentUsage(for applications: Set<ApplicationToken>, since startTime: Date) async -> [String: TimeInterval] {
        // Placeholder implementation
        return [:]
    }

    /// Gets current usage for applications during a specific time interval
    public func getCurrentUsage(for applications: Set<ApplicationToken>, during interval: DateInterval) async -> [String: TimeInterval] {
        // Placeholder implementation
        return [:]
    }

    /// Stops monitoring for a specific child
    public func stopMonitoring(for childID: String) {
        // Placeholder implementation
    }

    /// Removes all restrictions
    public func removeAllRestrictions() {
        // Placeholder implementation
    }

    // MARK: - Private Methods

    private func createApplicationToken(bundleID: String) async throws -> ApplicationToken {
        // In a real implementation, this would use the Family Controls framework
        // to create an application token for the specific bundle ID
        // For now, we'll simulate this functionality

        #if canImport(FamilyControls) && !os(macOS) && !targetEnvironment(simulator)
        // On device, this would use the actual Family Controls API
        // This is a placeholder implementation
        throw FamilyControlsError.notImplemented("ApplicationToken creation not implemented in demo")
        #else
        // Simulator/macOS doesn't support Family Controls, return a mock token
        throw FamilyControlsError.simulatorNotSupported
        #endif
    }

    private func applyRewardTimeSettings(
        appToken: ApplicationToken,
        timeMinutes: Int,
        redemptionID: String
    ) async throws {
        // In a real implementation, this would:
        // 1. Configure ManagedSettingsStore with specific time allowances
        // 2. Set up application restrictions that expire after the allocated time
        // 3. Store metadata linking the settings to the redemption ID

        #if canImport(FamilyControls) && !os(macOS) && !targetEnvironment(simulator)
        // Device implementation would use actual ManagedSettings APIs
        _ = store

        // Example of how this might work with real Family Controls:
        // let timeLimit = TimeInterval(timeMinutes * 60)
        // settings.application.blockedApplications = Set([appToken])
        // settings.dateAndTime.bedtime = DateComponents(hour: 22, minute: 0) // Example

        throw FamilyControlsError.notImplemented("ManagedSettings configuration not implemented in demo")
        #else
        // Simulator/macOS implementation - log the operation
        print("DEVELOPMENT: Would allocate \(timeMinutes) minutes for redemption \(redemptionID)")
        #endif
    }

    private func removeRewardTimeSettings(redemptionID: String, appBundleID: String) async throws {
        // In a real implementation, this would:
        // 1. Remove or modify ManagedSettingsStore entries for this redemption
        // 2. Clear application restrictions
        // 3. Clean up metadata

        #if canImport(FamilyControls) && !os(macOS) && !targetEnvironment(simulator)
        // Device implementation would use actual ManagedSettings APIs
        throw FamilyControlsError.notImplemented("ManagedSettings removal not implemented in demo")
        #else
        print("DEVELOPMENT: Would remove reward time settings for redemption \(redemptionID)")
        #endif
    }

}

// MARK: - Result Types

public enum RewardTimeAllocationResult: Equatable {
    case success(allocatedMinutes: Int)
    case authorizationRequired
    case redemptionExpired
    case noTimeRemaining
    case systemError(String)
}

public struct RewardTimeAllocation {
    public let redemptionID: String
    public let appBundleID: String
    public let allocatedMinutes: Int
    public let usedMinutes: Int
    public let expiresAt: Date
    public let isActive: Bool

    public init(redemptionID: String, appBundleID: String, allocatedMinutes: Int, usedMinutes: Int, expiresAt: Date, isActive: Bool) {
        self.redemptionID = redemptionID
        self.appBundleID = appBundleID
        self.allocatedMinutes = allocatedMinutes
        self.usedMinutes = usedMinutes
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
}

// MARK: - Error Types

public enum FamilyControlsError: Error, LocalizedError {
    case authorizationRequired
    case simulatorNotSupported
    case notImplemented(String)
    case invalidRedemption
    case managedSettingsError(String)
    case authorizationDenied
    case authorizationRestricted
    case unavailable
    case monitoringFailed(Error)
    case timeLimitFailed(Error)
    case restrictionFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .authorizationRequired:
            return "Family Controls authorization is required"
        case .simulatorNotSupported:
            return "Family Controls is not supported in the simulator"
        case .notImplemented(let message):
            return "Feature not implemented: \(message)"
        case .invalidRedemption:
            return "Invalid or expired redemption"
        case .managedSettingsError(let message):
            return "Managed Settings error: \(message)"
        case .authorizationDenied:
            return "Family Controls authorization was denied"
        case .authorizationRestricted:
            return "Family Controls authorization is restricted"
        case .unavailable:
            return "Family Controls service is unavailable"
        case .monitoringFailed(let error):
            return "Monitoring failed: \(error.localizedDescription)"
        case .timeLimitFailed(let error):
            return "Time limit configuration failed: \(error.localizedDescription)"
        case .restrictionFailed(let error):
            return "Restriction configuration failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Equatable Conformance

extension FamilyControlsError: Equatable {
    public static func == (lhs: FamilyControlsError, rhs: FamilyControlsError) -> Bool {
        switch (lhs, rhs) {
        case (.authorizationRequired, .authorizationRequired):
            return true
        case (.simulatorNotSupported, .simulatorNotSupported):
            return true
        case (.notImplemented(let lhsMessage), .notImplemented(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidRedemption, .invalidRedemption):
            return true
        case (.managedSettingsError(let lhsMessage), .managedSettingsError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.authorizationDenied, .authorizationDenied):
            return true
        case (.authorizationRestricted, .authorizationRestricted):
            return true
        case (.unavailable, .unavailable):
            return true
        case (.monitoringFailed, .monitoringFailed),
             (.timeLimitFailed, .timeLimitFailed),
             (.restrictionFailed, .restrictionFailed):
            // For errors with associated Error values, we can't easily compare them
            // so we'll return false to be safe
            return false
        default:
            return false
        }
    }
}

// MARK: - Extension for PointToTimeRedemption Integration

@available(iOS 15.0, macOS 10.15, *)
extension FamilyControlsService {
    /// Convenience method to allocate reward time from a PointToTimeRedemption
    public func allocateRewardTime(
        for redemption: PointToTimeRedemption,
        using appCategorization: AppCategorization
    ) async throws -> RewardTimeAllocationResult {
        return try await allocateRewardTime(
            for: redemption,
            appBundleID: appCategorization.appBundleID
        )
    }

    /// Validates that Family Controls can handle the requested time allocation
    public func validateTimeAllocation(timeMinutes: Int) -> Bool {
        // Basic validation - in a real app this might check:
        // - Parent-set daily limits
        // - Current active restrictions
        // - System limitations
        return timeMinutes > 0 && timeMinutes <= 240 // Max 4 hours per redemption
    }
}

// MARK: - Result Extension

extension RewardTimeAllocationResult {
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    public var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .authorizationRequired:
            return "Parent authorization is required to manage screen time"
        case .redemptionExpired:
            return "This redemption has expired"
        case .noTimeRemaining:
            return "No time remaining in this redemption"
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
}

// MARK: - Device Activity Schedule

// REMOVED: DeviceActivitySchedule struct to resolve ambiguity
// The DeviceActivitySchedule is now implemented in SharedModels to avoid
// conflicts between FamilyControlsKit and SharedModels modules.
