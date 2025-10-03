import SwiftUI

/// Comprehensive iCloud settings and management interface
@available(iOS 15.0, *)
struct iCloudSettingsView: View {
    @StateObject private var authService = iCloudAuthenticationService.shared
    @StateObject private var offlineManager = OfflineDataManager.shared
    @State private var showAuthenticationSheet = false
    @State private var showOfflineDataSheet = false
    @State private var showClearDataAlert = false
    @State private var showTroubleshootingSheet = false

    var body: some View {
        NavigationStack {
            Form {
                // Account Status Section
                Section("iCloud Account") {
                    iCloudAccountStatusRow()

                    if !authService.authenticationState.isAuthenticated {
                        Button("Sign In to iCloud") {
                            Task {
                                await authService.requestAuthentication()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }

                // Sync Status Section
                Section("Sync Status") {
                    iCloudSyncStatusView(showLabel: true, compact: false)

                    HStack {
                        Button("Check Status") {
                            Task {
                                await authService.checkAuthenticationStatus()
                            }
                        }

                        Spacer()

                        Button("Manual Sync") {
                            Task {
                                await authService.triggerSync()
                            }
                        }
                        .disabled(!authService.authenticationState.isAuthenticated)
                    }
                }

                // Offline Data Section
                if offlineManager.hasOfflineChanges {
                    Section("Offline Data") {
                        OfflineDataRow()

                        Button("View Offline Data") {
                            showOfflineDataSheet = true
                        }

                        if authService.authenticationState.isAuthenticated {
                            Button("Sync Offline Data") {
                                Task {
                                    await offlineManager.processOfflineQueue()
                                }
                            }
                            .disabled(offlineManager.isProcessingOfflineData)
                        }
                    }
                }

                // Data Management Section
                Section("Data Management") {
                    NavigationLink("Sync History") {
                        SyncHistoryView()
                    }

                    NavigationLink("Storage Usage") {
                        StorageUsageView()
                    }

                    Button("Clear Offline Data", role: .destructive) {
                        showClearDataAlert = true
                    }
                    .foregroundColor(.red)
                }

                // Troubleshooting Section
                Section("Troubleshooting") {
                    Button("Connection Test") {
                        Task {
                            await authService.testConnectivity()
                        }
                    }

                    Button("Troubleshooting Guide") {
                        showTroubleshootingSheet = true
                    }

                    NavigationLink("Advanced Settings") {
                        AdvancediCloudSettingsView()
                    }
                }

                // Information Section
                Section("Information") {
                    InfoRow(title: "About iCloud Sync", value: "Learn how your data syncs")
                    InfoRow(title: "Privacy & Security", value: "Your data is encrypted")
                    InfoRow(title: "Data Retention", value: "Data stored for 30 days")
                }
            }
            .navigationTitle("iCloud Settings")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await authService.checkAuthenticationStatus()
            }
        }
        .sheet(isPresented: $showOfflineDataSheet) {
            OfflineDataDetailView()
        }
        .sheet(isPresented: $showTroubleshootingSheet) {
            TroubleshootingGuideView()
        }
        .alert("Clear Offline Data", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                offlineManager.clearOfflineData()
            }
        } message: {
            Text("This will permanently delete all offline data that hasn't been synced. This action cannot be undone.")
        }
        .alert("Authentication Error", isPresented: $authService.showAuthenticationAlert) {
            Button("OK") { }

            if let error = authService.authenticationError, error.recoverySuggestion != nil {
                Button("Settings") {
                    openSettings()
                }
            }
        } message: {
            if let error = authService.authenticationError {
                Text(error.localizedDescription + "\n\n" + (error.recoverySuggestion ?? ""))
            }
        }
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Supporting Views

struct iCloudAccountStatusRow: View {
    @StateObject private var authService = iCloudAuthenticationService.shared

    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Account Status")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if authService.authenticationState.userID != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("User ID")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(authService.authenticationState.userID?.suffix(8) ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: String {
        switch authService.authenticationState.accountStatus {
        case .available:
            return "checkmark.circle.fill"
        case .noAccount:
            return "person.circle.fill"
        case .restricted:
            return "exclamationmark.triangle.fill"
        case .couldNotDetermine:
            return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch authService.authenticationState.accountStatus {
        case .available:
            return .green
        case .noAccount:
            return .orange
        case .restricted:
            return .red
        case .couldNotDetermine:
            return .gray
        }
    }

    private var statusText: String {
        switch authService.authenticationState.accountStatus {
        case .available:
            return "Signed in and ready"
        case .noAccount:
            return "No iCloud account found"
        case .restricted:
            return "Account is restricted"
        case .couldNotDetermine:
            return "Status unknown"
        }
    }
}

struct OfflineDataRow: View {
    @StateObject private var offlineManager = OfflineDataManager.shared

    var body: some View {
        HStack {
            Image(systemName: "icloud.and.arrow.up")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pending Changes")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(offlineManager.offlineItemCount) items waiting to sync")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if offlineManager.isProcessingOfflineData {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Detail Views

struct OfflineDataDetailView: View {
    @StateObject private var offlineManager = OfflineDataManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                let summary = offlineManager.getOfflineDataSummary()

                Section("Summary") {
                    LabeledContent("Total Items", value: "\(summary.totalOperations)")
                    LabeledContent("Estimated Sync Time", value: summary.formattedSyncTime)

                    if let age = summary.oldestOperationAge {
                        LabeledContent("Oldest Item", value: formatTimeInterval(age))
                    }
                }

                Section("By Type") {
                    ForEach(Array(summary.operationsByType.keys), id: \.self) { type in
                        LabeledContent(type.displayName, value: "\(summary.operationsByType[type] ?? 0)")
                    }
                }

                Section("Actions") {
                    Button("Export Debug Data") {
                        exportOfflineData()
                    }

                    Button("Process Now") {
                        Task {
                            await offlineManager.processOfflineQueue()
                        }
                    }
                    .disabled(offlineManager.isProcessingOfflineData)

                    Button("Clear All Data", role: .destructive) {
                        offlineManager.clearOfflineData()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Offline Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: Date().addingTimeInterval(-interval), relativeTo: Date())
    }

    private func exportOfflineData() {
        if let data = offlineManager.exportOfflineData() {
            // Handle data export (e.g., share sheet)
            print("Exported \(data.count) bytes of offline data")
        }
    }
}

struct SyncHistoryView: View {
    var body: some View {
        List {
            // Mock sync history - replace with actual data
            ForEach(0..<10) { index in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync #\(10 - index)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("\(5 + index) items synced")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Success")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("\(index + 1)h ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Sync History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StorageUsageView: View {
    var body: some View {
        Form {
            Section("iCloud Storage") {
                LabeledContent("Used Space", value: "2.3 MB")
                LabeledContent("Available Space", value: "4.2 GB")
                LabeledContent("Total Records", value: "1,247")
            }

            Section("Data Breakdown") {
                LabeledContent("Usage Sessions", value: "856 KB")
                LabeledContent("Point Transactions", value: "623 KB")
                LabeledContent("User Profiles", value: "445 KB")
                LabeledContent("App Settings", value: "234 KB")
                LabeledContent("Other Data", value: "142 KB")
            }

            Section("Cache") {
                LabeledContent("Local Cache", value: "1.8 MB")
                LabeledContent("Offline Queue", value: "145 KB")

                Button("Clear Cache") {
                    // Implement cache clearing
                }
            }
        }
        .navigationTitle("Storage Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdvancediCloudSettingsView: View {
    @AppStorage("iCloudSyncEnabled") private var syncEnabled = true
    @AppStorage("iCloudAutoSync") private var autoSync = true
    @AppStorage("iCloudSyncInterval") private var syncInterval = 300.0 // 5 minutes
    @AppStorage("iCloudConflictResolution") private var conflictResolution = "latest"

    var body: some View {
        Form {
            Section("Sync Settings") {
                Toggle("Enable iCloud Sync", isOn: $syncEnabled)
                Toggle("Automatic Sync", isOn: $autoSync)

                if autoSync {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sync Interval")
                            .font(.subheadline)

                        Slider(value: $syncInterval, in: 60...3600, step: 60) {
                            Text("Interval")
                        } minimumValueLabel: {
                            Text("1m")
                        } maximumValueLabel: {
                            Text("1h")
                        }

                        Text("\(Int(syncInterval / 60)) minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Conflict Resolution") {
                Picker("When data conflicts occur", selection: $conflictResolution) {
                    Text("Use latest changes").tag("latest")
                    Text("Prefer local data").tag("local")
                    Text("Prefer cloud data").tag("cloud")
                    Text("Ask me each time").tag("ask")
                }
                .pickerStyle(.navigationLink)
            }

            Section("Performance") {
                LabeledContent("Batch Size", value: "100 records")
                LabeledContent("Retry Attempts", value: "3 times")
                LabeledContent("Timeout", value: "30 seconds")
            }

            Section("Developer") {
                Button("Reset iCloud Schema") {
                    // Implement schema reset
                }
                .foregroundColor(.red)

                Button("Force Full Sync") {
                    // Implement full sync
                }
            }
        }
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TroubleshootingGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TroubleshootingSection(
                        title: "Common Issues",
                        items: [
                            "Data not syncing: Check your internet connection and iCloud settings",
                            "Sign-in problems: Go to Settings > [Your Name] > iCloud",
                            "Storage full: Free up iCloud storage or upgrade your plan",
                            "Sync conflicts: Latest changes are automatically chosen"
                        ]
                    )

                    TroubleshootingSection(
                        title: "Quick Fixes",
                        items: [
                            "Restart the app",
                            "Check internet connection",
                            "Sign out and back into iCloud",
                            "Update iOS to the latest version",
                            "Clear app cache and restart"
                        ]
                    )

                    TroubleshootingSection(
                        title: "When to Contact Support",
                        items: [
                            "Data loss or corruption",
                            "Persistent sync failures",
                            "Account access issues",
                            "Billing or subscription problems"
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("Troubleshooting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TroubleshootingSection: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)

                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct iCloudSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudSettingsView()
    }
}
#endif