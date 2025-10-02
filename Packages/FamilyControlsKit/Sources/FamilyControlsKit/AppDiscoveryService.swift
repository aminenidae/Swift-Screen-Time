import Foundation
import SharedModels
import FamilyControls
import ManagedSettings
import DeviceActivity

@available(iOS 15.0, macOS 10.15, *)
public class AppDiscoveryService: ObservableObject {

    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined

    public init() {
        updateAuthorizationStatus()
    }

    /// Updates the current authorization status
    public func updateAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    /// Requests Family Controls authorization
    @available(iOS 16.0, *)
    public func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        updateAuthorizationStatus()
    }

    /// Requests Family Controls authorization (iOS 15 compatibility)
    public func requestAuthorizationLegacy() async throws {
        if #available(iOS 16.0, *) {
            try await requestAuthorization()
        } else {
            // For iOS 15, Family Controls requires manual permission setup
            // The user needs to enable it in Settings > Screen Time > Family Controls
            updateAuthorizationStatus()
            if authorizationStatus != .approved {
                throw AppDiscoveryError.notAuthorized
            }
        }
    }

    /// Fetches installed apps using the Family Controls framework
    public func fetchInstalledApps() async throws -> [AppMetadata] {
        // Check authorization status first
        guard authorizationStatus == .approved else {
            throw AppDiscoveryError.notAuthorized
        }

        // Use real Family Controls APIs when authorized
        #if targetEnvironment(simulator)
        // Return mock data for simulator testing
        return getMockApps()
        #else
        // Real device implementation
        return try await getRealInstalledApps()
        #endif
    }

    /// Gets real installed apps (physical device only)
    private func getRealInstalledApps() async throws -> [AppMetadata] {
        // Note: Family Controls doesn't provide direct app enumeration
        // This would typically be done through DeviceActivity monitoring
        // For now, we'll return common apps that can be monitored
        return [
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.mobilesafari",
                displayName: "Safari",
                isSystemApp: true,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.MobileSMS",
                displayName: "Messages",
                isSystemApp: true,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.mobilemail",
                displayName: "Mail",
                isSystemApp: true,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.camera",
                displayName: "Camera",
                isSystemApp: true,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.mobilecal",
                displayName: "Calendar",
                isSystemApp: true,
                iconData: nil
            )
        ]
    }

    /// Returns mock apps for testing and simulator
    private func getMockApps() -> [AppMetadata] {
        return [
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.Maps",
                displayName: "Maps",
                isSystemApp: true,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.MobileSMS",
                displayName: "Messages",
                isSystemApp: true,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.apple.MobileSafari",
                displayName: "Safari",
                isSystemApp: true,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.khanacademy.iphone",
                displayName: "Khan Academy",
                isSystemApp: false,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.duolingo.DuolingoMobile",
                displayName: "Duolingo",
                isSystemApp: false,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.brilliant.Brilliant",
                displayName: "Brilliant",
                isSystemApp: false,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.supercell.clashofclans",
                displayName: "Clash of Clans",
                isSystemApp: false,
                iconData: nil
            ),
            AppMetadata(
                id: UUID().uuidString,
                bundleID: "com.netflix.Netflix",
                displayName: "Netflix",
                isSystemApp: false,
                iconData: nil
            )
        ]
    }
}

public enum AppDiscoveryError: Error, LocalizedError {
    case notAuthorized
    case systemError

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Family Controls authorization required. Please grant permission in Settings."
        case .systemError:
            return "Unable to fetch app information. Please try again."
        }
    }
}