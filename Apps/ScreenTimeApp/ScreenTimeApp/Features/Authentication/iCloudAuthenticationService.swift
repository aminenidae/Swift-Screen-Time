import Foundation
import CloudKit
import SwiftUI
import Combine
import OSLog
import SharedModels
import RewardCore

/// Enhanced iCloud authentication service with comprehensive status management
@available(iOS 15.0, *)
@MainActor
public class iCloudAuthenticationService: ObservableObject {
    public static let shared = iCloudAuthenticationService()

    @Published public var authenticationState: AuthState = AuthState(
        isAuthenticated: false,
        accountStatus: .couldNotDetermine,
        userID: nil,
        familyID: nil
    )
    @Published public var syncStatus: iCloudSyncStatus = .unknown
    @Published public var lastSyncTime: Date?
    @Published public var isOnline: Bool = true
    @Published public var showAuthenticationAlert: Bool = false
    @Published public var authenticationError: AuthenticationError?

    private let container = CKContainer.default()
    private let logger = Logger(subsystem: "com.screentime.rewards", category: "icloud-auth")
    private let errorHandler = ErrorHandlingService.shared

    // Status checking timer
    private var statusCheckTimer: Timer?
    private let statusCheckInterval: TimeInterval = 30.0 // 30 seconds

    private init() {
        startPeriodicStatusChecks()
    }

    deinit {
        // Stop periodic status checks
        // Since this is called from deinit, we can't use async/await
        // We'll just invalidate the timer directly
        statusCheckTimer?.invalidate()
        statusCheckTimer = nil
    }

    // MARK: - Public Authentication Methods

    /// Check and update current authentication status
    public func checkAuthenticationStatus() async {
        logger.info("Checking iCloud authentication status")

        do {
            let accountStatus = try await container.accountStatus()
            let userRecordID = try? await container.userRecordID()

            let newAuthState = AuthState(
                isAuthenticated: accountStatus == .available && userRecordID != nil,
                accountStatus: mapCKAccountStatus(accountStatus),
                userID: userRecordID?.recordName,
                familyID: await fetchFamilyID()
            )

            updateAuthenticationState(newAuthState)
            await updateSyncStatus()

        } catch {
            logger.error("Failed to check authentication status: \(error.localizedDescription)")
            handleAuthenticationError(error)
        }
    }

    /// Request iCloud authentication permissions
    public func requestAuthentication() async -> Bool {
        logger.info("Requesting iCloud authentication")

        do {
            let accountStatus = try await container.accountStatus()

            switch accountStatus {
            case .available:
                await checkAuthenticationStatus()
                return authenticationState.isAuthenticated

            case .noAccount:
                showAuthenticationError(.noiCloudAccount)
                return false

            case .restricted:
                showAuthenticationError(.accountRestricted)
                return false

            case .couldNotDetermine:
                showAuthenticationError(.undeterminedStatus)
                return false

            default:
                showAuthenticationError(.unknownError("Unknown account status"))
                return false
            }

        } catch {
            logger.error("Authentication request failed: \(error.localizedDescription)")
            handleAuthenticationError(error)
            return false
        }
    }

    /// Sign out and clear authentication state
    public func signOut() async {
        logger.info("Signing out from iCloud")

        updateAuthenticationState(AuthState(
            isAuthenticated: false,
            accountStatus: .noAccount,
            userID: nil,
            familyID: nil
        ))

        syncStatus = .disconnected
        lastSyncTime = nil

        // Clear local cache
        await clearLocalAuthenticationCache()
    }

    /// Test iCloud connectivity
    public func testConnectivity() async -> Bool {
        logger.info("Testing iCloud connectivity")

        do {
            // Perform a lightweight CloudKit operation to test connectivity
            let _ = try await container.accountStatus()
            isOnline = true
            return true
        } catch {
            logger.warning("iCloud connectivity test failed: \(error.localizedDescription)")
            isOnline = false
            return false
        }
    }

    // MARK: - Sync Status Management

    /// Update current sync status
    private func updateSyncStatus() async {
        guard authenticationState.isAuthenticated else {
            syncStatus = .disconnected
            return
        }

        let isConnected = await testConnectivity()

        if isConnected {
            syncStatus = .synced
            lastSyncTime = Date()
        } else {
            syncStatus = .offline
        }
    }

    /// Manual sync trigger
    public func triggerSync() async -> Bool {
        logger.info("Manual sync triggered")

        guard authenticationState.isAuthenticated else {
            showAuthenticationError(.notAuthenticated)
            return false
        }

        syncStatus = .syncing

        let success = await testConnectivity()
        if success {
            syncStatus = .synced
            lastSyncTime = Date()
        } else {
            syncStatus = .failed
        }

        return success
    }

    // MARK: - Error Handling

    private func handleAuthenticationError(_ error: Error) {
        if let ckError = error as? CKError {
            let appError = errorHandler.mapCloudKitError(ckError)
            authenticationError = mapAppErrorToAuthError(appError)
        } else {
            authenticationError = .unknownError(error.localizedDescription)
        }

        showAuthenticationAlert = true
    }

    private func showAuthenticationError(_ error: AuthenticationError) {
        authenticationError = error
        showAuthenticationAlert = true
    }

    private func mapAppErrorToAuthError(_ appError: AppError) -> AuthenticationError {
        switch appError {
        case .authenticationFailed:
            return .authenticationFailed
        case .networkUnavailable:
            return .networkUnavailable
        case .cloudKitNotAvailable:
            return .iCloudUnavailable
        default:
            return .unknownError(appError.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    private func updateAuthenticationState(_ newState: AuthState) {
        DispatchQueue.main.async {
            self.authenticationState = newState
        }
    }

    private func mapCKAccountStatus(_ status: CKAccountStatus) -> AccountStatus {
        switch status {
        case .available:
            return .available
        case .noAccount:
            return .noAccount
        case .restricted:
            return .restricted
        case .couldNotDetermine:
            return .couldNotDetermine
        default:
            return .couldNotDetermine
        }
    }

    private func fetchFamilyID() async -> String? {
        // In a real implementation, this would fetch the family ID from CloudKit
        // For now, return a mock family ID if authenticated
        return authenticationState.isAuthenticated ? "family_\(UUID().uuidString.prefix(8))" : nil
    }

    private func clearLocalAuthenticationCache() async {
        // Clear any cached authentication data
        logger.info("Clearing local authentication cache")
        UserDefaults.standard.removeObject(forKey: "cachedUserID")
        UserDefaults.standard.removeObject(forKey: "cachedFamilyID")
    }

    // MARK: - Periodic Status Checks

    private func startPeriodicStatusChecks() {
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: statusCheckInterval, repeats: true) { _ in
            Task {
                await self.checkAuthenticationStatus()
            }
        }
    }

    private func stopPeriodicStatusChecks() {
        statusCheckTimer?.invalidate()
        statusCheckTimer = nil
    }
}

// MARK: - Supporting Types

public enum iCloudSyncStatus: String, CaseIterable {
    case unknown = "unknown"
    case syncing = "syncing"
    case synced = "synced"
    case failed = "failed"
    case offline = "offline"
    case disconnected = "disconnected"

    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .failed: return "Sync Failed"
        case .offline: return "Offline"
        case .disconnected: return "Disconnected"
        }
    }

    public var color: Color {
        switch self {
        case .unknown: return .gray
        case .syncing: return .blue
        case .synced: return .green
        case .failed: return .red
        case .offline: return .orange
        case .disconnected: return .gray
        }
    }

    public var icon: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.icloud"
        case .failed: return "exclamationmark.icloud"
        case .offline: return "wifi.slash"
        case .disconnected: return "icloud.slash"
        }
    }
}

public enum AuthenticationError: LocalizedError, Equatable {
    case notAuthenticated
    case authenticationFailed
    case noiCloudAccount
    case accountRestricted
    case undeterminedStatus
    case networkUnavailable
    case iCloudUnavailable
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with iCloud"
        case .authenticationFailed:
            return "iCloud authentication failed"
        case .noiCloudAccount:
            return "No iCloud account found. Please sign in to iCloud in Settings."
        case .accountRestricted:
            return "iCloud account is restricted. Check Screen Time or parental controls."
        case .undeterminedStatus:
            return "Could not determine iCloud account status"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .iCloudUnavailable:
            return "iCloud service is temporarily unavailable"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .noiCloudAccount:
            return "Go to Settings > [Your Name] to sign in to iCloud"
        case .accountRestricted:
            return "Check Screen Time restrictions or parental controls in Settings"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .iCloudUnavailable:
            return "Try again later or check Apple's system status"
        default:
            return "Try signing out and back in to iCloud"
        }
    }
}

// MARK: - Extensions

extension AuthState {
    public var isFullyAuthenticated: Bool {
        return isAuthenticated && accountStatus == .available && userID != nil
    }

    public var needsAuthentication: Bool {
        return !isAuthenticated || accountStatus != .available
    }
}

#if DEBUG
// MARK: - Mock Data for Previews
extension iCloudAuthenticationService {
    public static func mockAuthenticated() -> iCloudAuthenticationService {
        let service = iCloudAuthenticationService()
        service.authenticationState = AuthState(
            isAuthenticated: true,
            accountStatus: .available,
            userID: "mock_user_123",
            familyID: "mock_family_456"
        )
        service.syncStatus = .synced
        service.lastSyncTime = Date()
        service.isOnline = true
        return service
    }

    public static func mockUnauthenticated() -> iCloudAuthenticationService {
        let service = iCloudAuthenticationService()
        service.authenticationState = AuthState(
            isAuthenticated: false,
            accountStatus: .noAccount,
            userID: nil,
            familyID: nil
        )
        service.syncStatus = .disconnected
        service.isOnline = false
        return service
    }
}
#endif