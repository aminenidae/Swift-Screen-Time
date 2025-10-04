import SwiftUI
import FamilyControls
import FamilyControlsKit

/// Main parent settings view with general and child-specific configurations
struct ParentSettingsView: View {

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Configure your family's Screen Time\nRewards experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search settings...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Family Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Family Settings")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            NavigationLink(destination: FamilySetupView()) {
                                VStack(spacing: 12) {
                                    Image(systemName: "house.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(.blue))

                                    VStack(spacing: 4) {
                                        Text("Family Setup")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("Set up and manage your family")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: FamilyControlsSetupView()) {
                                VStack(spacing: 12) {
                                    Image(systemName: "shield.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(.green))

                                    VStack(spacing: 4) {
                                        Text("Family Controls")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("Manage screen time rules")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: FamilyMembersView()) {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(.purple))

                                    VStack(spacing: 4) {
                                        Text("Family Members")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("View and manage family members")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: SubscriptionManagementView()) {
                                VStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(.orange))

                                    VStack(spacing: 4) {
                                        Text("Family Plan")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text("Manage your subscription")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }





                    Spacer()
                }
            }
            .navigationBarHidden(true)

        }
    }


}

// MARK: - Supporting Views

// MARK: - Placeholder Views

struct GeneralSettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: FamilySetupView()) {
                    Label("Family Setup", systemImage: "house.fill")
                }
                NavigationLink(destination: FamilyControlsSetupView()) {
                    Label("Family Controls", systemImage: "shield.fill")
                }
                NavigationLink(destination: FamilyMembersView()) {
                    Label("Family Members", systemImage: "person.2.fill")
                }
                NavigationLink(destination: SubscriptionManagementView()) {
                    Label("Subscription", systemImage: "star.fill")
                }
            }
            .navigationTitle("General Settings")
        }
    }
}

struct BedtimeSettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Bedtime Settings")
                    .font(.title)
                Text("Schedule bedtime restrictions")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Bedtime Settings")
        }
    }
}



// Forward declarations for views that will be modularized later
struct FamilyControlsSetupView: View {
    @StateObject private var familyControlsService = FamilyControlsService()
    @State private var authorizationStatus: AuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Family Controls Setup")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Configure Family Controls to manage your children's device usage effectively.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Status Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("Current Status")
                                .font(.headline)
                            Spacer()
                            Text(statusText(for: authorizationStatus))
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(for: authorizationStatus).opacity(0.2))
                                .foregroundColor(statusColor(for: authorizationStatus))
                                .cornerRadius(8)
                        }

                        Text(statusDescription(for: authorizationStatus))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Action Button
                    if authorizationStatus != .approved {
                        Button(action: {
                            requestFamilyControlsAuthorization()
                        }) {
                            Text("Enable Family Controls")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Family Controls")
            .onAppear {
                checkAuthorizationStatus()
            }
        }
    }

    private func checkAuthorizationStatus() {
        // In a real implementation, this would check the actual authorization status
        authorizationStatus = familyControlsService.authorizationStatus
    }

    private func requestFamilyControlsAuthorization() {
        Task {
            do {
                if #available(iOS 16.0, *) {
                    try await familyControlsService.requestAuthorization()
                    await MainActor.run {
                        checkAuthorizationStatus()
                    }
                }
            } catch {
                print("Error requesting authorization: \(error)")
            }
        }
    }

    private func statusDescription(for status: AuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Family Controls authorization has not been requested yet."
        case .denied:
            return "Family Controls access has been denied. Please enable it in Settings."
        case .approved:
            return "Family Controls is enabled and ready to use."
        @unknown default:
            return "Unknown authorization status."
        }
    }

    private func statusText(for status: AuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Set"
        case .denied: return "Denied"
        case .approved: return "Enabled"
        @unknown default: return "Unknown"
        }
    }

    private func statusColor(for status: AuthorizationStatus) -> Color {
        switch status {
        case .notDetermined: return .orange
        case .denied: return .red
        case .approved: return .green
        @unknown default: return .gray
        }
    }
}


// Reports view that uses analytics
struct ReportsView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            AnalyticsDashboardView()
        } else {
            Text("Analytics requires iOS 16.0 or later")
                .foregroundColor(.secondary)
        }
    }
}

// Usage trends view
struct UsageTrendsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Usage Trends")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("View detailed usage trends and patterns for your family")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("Usage Trends")
        }
    }
}



struct FamilyMembersView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Family Members")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Manage your family sharing group and member settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("Family Members")
        }
    }
}

#if DEBUG
struct ParentSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ParentSettingsView()
    }
}
#endif