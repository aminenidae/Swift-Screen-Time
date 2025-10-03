import SwiftUI

/// Sync status indicators for displaying iCloud sync state throughout the app
@available(iOS 15.0, *)
struct iCloudSyncStatusView: View {
    @StateObject private var authService = iCloudAuthenticationService.shared
    let showLabel: Bool
    let compact: Bool

    init(showLabel: Bool = true, compact: Bool = false) {
        self.showLabel = showLabel
        self.compact = compact
    }

    var body: some View {
        if compact {
            CompactSyncStatusView(
                status: authService.syncStatus,
                showLabel: showLabel
            )
        } else {
            FullSyncStatusView(
                authState: authService.authenticationState,
                syncStatus: authService.syncStatus,
                lastSyncTime: authService.lastSyncTime,
                isOnline: authService.isOnline
            )
        }
    }
}

/// Compact sync status indicator for navigation bars and headers
struct CompactSyncStatusView: View {
    let status: iCloudSyncStatus
    let showLabel: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.caption)

            if showLabel {
                Text(status.displayName)
                    .font(.caption)
                    .foregroundColor(status.color)
            }
        }
        .padding(.horizontal, showLabel ? 8 : 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(status.color.opacity(0.1))
        )
    }
}

/// Full sync status view with detailed information
struct FullSyncStatusView: View {
    let authState: AuthState
    let syncStatus: iCloudSyncStatus
    let lastSyncTime: Date?
    let isOnline: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Authentication Status
            HStack {
                Image(systemName: authState.isAuthenticated ? "person.fill.checkmark" : "person.fill.xmark")
                    .foregroundColor(authState.isAuthenticated ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Account")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(authState.isAuthenticated ? "Signed In" : "Not Signed In")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if authState.accountStatus != .available {
                    Button("Fix") {
                        // Open Settings or trigger authentication
                        openSettings()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }

            Divider()

            // Sync Status
            HStack {
                Image(systemName: syncStatus.icon)
                    .foregroundColor(syncStatus.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync Status")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(syncStatus.displayName)
                        .font(.caption)
                        .foregroundColor(syncStatus.color)
                }

                Spacer()

                if let lastSync = lastSyncTime {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last Sync")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(formatSyncTime(lastSync))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Network Status
            HStack {
                Image(systemName: isOnline ? "wifi" : "wifi.slash")
                    .foregroundColor(isOnline ? .green : .orange)

                Text(isOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func formatSyncTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

/// Animated sync indicator for active syncing states
struct AnimatedSyncIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .foregroundColor(.blue)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Sync status banner for displaying at the top of views
struct SyncStatusBanner: View {
    @StateObject private var authService = iCloudAuthenticationService.shared
    @State private var showBanner = false

    var body: some View {
        Group {
            if shouldShowBanner {
                HStack {
                    Image(systemName: bannerIcon)
                        .foregroundColor(bannerColor)

                    Text(bannerMessage)
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()

                    if authService.syncStatus == .failed {
                        Button("Retry") {
                            Task {
                                await authService.triggerSync()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    Button("Dismiss") {
                        withAnimation {
                            showBanner = false
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(bannerColor.opacity(0.1))
                .overlay(
                    Rectangle()
                        .fill(bannerColor)
                        .frame(height: 1),
                    alignment: .bottom
                )
            }
        }
        .onChange(of: authService.syncStatus) { status in
            withAnimation {
                showBanner = shouldShowBannerForStatus(status)
            }
        }
    }

    private var shouldShowBanner: Bool {
        showBanner && shouldShowBannerForStatus(authService.syncStatus)
    }

    private func shouldShowBannerForStatus(_ status: iCloudSyncStatus) -> Bool {
        switch status {
        case .failed, .offline, .disconnected:
            return true
        default:
            return false
        }
    }

    private var bannerIcon: String {
        switch authService.syncStatus {
        case .failed:
            return "exclamationmark.triangle.fill"
        case .offline:
            return "wifi.slash"
        case .disconnected:
            return "icloud.slash"
        default:
            return "info.circle.fill"
        }
    }

    private var bannerColor: Color {
        switch authService.syncStatus {
        case .failed:
            return .red
        case .offline:
            return .orange
        case .disconnected:
            return .gray
        default:
            return .blue
        }
    }

    private var bannerMessage: String {
        switch authService.syncStatus {
        case .failed:
            return "Sync failed. Your data may not be up to date."
        case .offline:
            return "You're offline. Changes will sync when connected."
        case .disconnected:
            return "iCloud is disconnected. Sign in to sync your data."
        default:
            return "Sync status unknown"
        }
    }
}

/// Floating sync status indicator that can be positioned anywhere
struct FloatingSyncIndicator: View {
    @StateObject private var authService = iCloudAuthenticationService.shared
    let position: FloatingPosition

    enum FloatingPosition {
        case topTrailing
        case bottomTrailing
        case topLeading
        case bottomLeading
    }

    var body: some View {
        VStack {
            if position == .bottomTrailing || position == .bottomLeading {
                Spacer()
            }

            HStack {
                if position == .topTrailing || position == .bottomTrailing {
                    Spacer()
                }

                syncIndicator

                if position == .topLeading || position == .bottomLeading {
                    Spacer()
                }
            }

            if position == .topTrailing || position == .topLeading {
                Spacer()
            }
        }
        .padding()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var syncIndicator: some View {
        if authService.syncStatus == .syncing {
            AnimatedSyncIndicator()
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(radius: 4)
                )
        } else if authService.syncStatus == .failed {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(radius: 4)
                )
        }
    }
}

/// Navigation bar sync status indicator
struct NavigationSyncIndicator: View {
    @StateObject private var authService = iCloudAuthenticationService.shared

    var body: some View {
        Menu {
            VStack(alignment: .leading) {
                Label("Account: \(authService.authenticationState.isAuthenticated ? "Signed In" : "Not Signed In")",
                      systemImage: authService.authenticationState.isAuthenticated ? "checkmark.circle" : "xmark.circle")

                Label("Sync: \(authService.syncStatus.displayName)",
                      systemImage: authService.syncStatus.icon)

                if let lastSync = authService.lastSyncTime {
                    Label("Last sync: \(formatSyncTime(lastSync))",
                          systemImage: "clock")
                }

                Divider()

                Button("Refresh") {
                    Task {
                        await authService.checkAuthenticationStatus()
                    }
                }

                if authService.syncStatus == .failed {
                    Button("Retry Sync") {
                        Task {
                            await authService.triggerSync()
                        }
                    }
                }
            }
        } label: {
            CompactSyncStatusView(
                status: authService.syncStatus,
                showLabel: false
            )
        }
    }

    private func formatSyncTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct iCloudSyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Compact indicators
            HStack {
                CompactSyncStatusView(status: .synced, showLabel: true)
                CompactSyncStatusView(status: .syncing, showLabel: true)
                CompactSyncStatusView(status: .failed, showLabel: true)
            }

            // Full status view
            FullSyncStatusView(
                authState: AuthState(isAuthenticated: true, accountStatus: .available, userID: "test", familyID: "family"),
                syncStatus: .synced,
                lastSyncTime: Date(),
                isOnline: true
            )

            // Banner
            SyncStatusBanner()

            // Navigation indicator
            NavigationSyncIndicator()
        }
        .padding()
    }
}
#endif