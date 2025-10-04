import SwiftUI
import FamilyControls
import FamilyControlsKit

/// Main parent settings view with general and child-specific configurations
struct ParentSettingsView: View {
    @State private var selectedChild: FamilyMemberInfo?
    @StateObject private var familyMemberService = FamilyMemberService()

    var body: some View {
        NavigationStack {
            List {
                // General Settings
                Section("GENERAL SETTINGS") {
                    NavigationLink(destination: FamilySetupView()) {
                        Label("Family Setup", systemImage: "house.fill")
                    }

                    NavigationLink(destination: FamilyControlsSetupView()) {
                        Label("Family Controls", systemImage: "shield.fill")
                    }

                    NavigationLink(destination: FamilyMembersView()) {
                        Label("Family Members", systemImage: "person.2.fill")
                    }


                    NavigationLink(destination: SubscriptionView()) {
                        Label("Subscription", systemImage: "star.fill")
                    }
                }

                // Reward System
                Section("REWARD SYSTEM") {
                    NavigationLink(destination: LearningAppRewardsView()) {
                        Label("Learning App Points", systemImage: "graduationcap.fill")
                    }
                }

                // Child Settings
                if !familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    Section("CHILD SETTINGS") {
                        NavigationLink(destination: ChildSpecificAppCategoriesView()) {
                            Label("App Categories", systemImage: "square.grid.2x2.fill")
                        }
                        NavigationLink(destination: ChildSpecificLearningAppView()) {
                            Label("Learning Apps", systemImage: "graduationcap.fill")
                        }

                        NavigationLink(destination: ChildSpecificRewardAppView()) {
                            Label("Reward Apps", systemImage: "gift.fill")
                        }

                        NavigationLink(destination: BasicTimeLimitsView()) {
                            Label("Daily Time Limits", systemImage: "clock.fill")
                        }

                        NavigationLink(destination: ChildSpecificSpecialRewardsView()) {
                            Label("Special Rewards", systemImage: "gift.fill")
                        }

                        NavigationLink(destination: ReportsView()) {
                            Label("Detailed Reports", systemImage: "chart.bar.fill")
                        }

                        NavigationLink(destination: UsageTrendsView()) {
                            Label("Usage Trends", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }
                } else {
                    Section("Child Settings") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.slash")
                                    .foregroundColor(.orange)
                                Text("No children found in Family Sharing")
                                    .foregroundColor(.secondary)
                            }

                            NavigationLink(destination: FamilySetupView()) {
                                Text("Set up Family Sharing →")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Account") {
                    Button(action: {
                        // Switch to child profile
                        UserDefaults.standard.set("child", forKey: "userRole")
                    }) {
                        Label("Switch to Child Profile", systemImage: "person.fill")
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        // Reset onboarding
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    }) {
                        Label("Reset App", systemImage: "arrow.clockwise")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
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
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Enable screen time monitoring and app management for your family.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Status Section
                    VStack(spacing: 16) {
                        StatusCard(
                            title: "Authorization Status",
                            status: statusText,
                            statusColor: statusColor,
                            icon: statusIcon
                        )

                        if authorizationStatus == .approved {
                            StatusCard(
                                title: "App Categories",
                                status: "Configured",
                                statusColor: .green,
                                icon: "checkmark.circle.fill"
                            )
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        if authorizationStatus != .approved {
                            Button("Enable Family Controls") {
                                requestAuthorization()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        if authorizationStatus == .denied {
                            VStack(spacing: 8) {
                                Text("Family Controls permission was denied.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("Please enable it in Settings > Screen Time > Family Controls")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }

                    // Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What Family Controls Enables:")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(spacing: 12) {
                            FamilyControlsFeatureRow(
                                icon: "clock.fill",
                                title: "Screen Time Tracking",
                                description: "Monitor educational vs entertainment app usage"
                            )

                            FamilyControlsFeatureRow(
                                icon: "star.fill",
                                title: "Automatic Point Earning",
                                description: "Children earn points for educational app usage"
                            )

                            FamilyControlsFeatureRow(
                                icon: "lock.fill",
                                title: "App Management",
                                description: "Control access to entertainment apps with earned points"
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Family Controls")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkAuthorizationStatus()
            }
        }
    }

    // MARK: - Computed Properties

    private var statusText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Setup Required"
        case .denied:
            return "Permission Denied"
        case .approved:
            return "Ready to Use"
        @unknown default:
            return "Unknown"
        }
    }

    private var statusColor: Color {
        switch authorizationStatus {
        case .notDetermined:
            return .orange
        case .denied:
            return .red
        case .approved:
            return .green
        @unknown default:
            return .gray
        }
    }

    private var statusIcon: String {
        switch authorizationStatus {
        case .notDetermined:
            return "exclamationmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .approved:
            return "checkmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    // MARK: - Methods

    private func checkAuthorizationStatus() {
        authorizationStatus = familyControlsService.authorizationStatus
    }

    private func requestAuthorization() {
        Task {
            do {
                try await familyControlsService.requestAuthorization()
                await MainActor.run {
                    authorizationStatus = familyControlsService.authorizationStatus
                }
            } catch {
                print("Authorization failed: \(error)")
            }
        }
    }
}

struct FamilyMembersView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Family Members")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Your family members from Apple Family Sharing.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Sync Status
                    if familyMemberService.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Syncing with Family Sharing...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }

                    // Family Members List
                    if familyMemberService.familyMembers.isEmpty && !familyMemberService.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)

                            Text("No Family Members Found")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            VStack(spacing: 8) {
                                Text("To use ScreenTime Rewards with multiple family members:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("1. Set up Family Sharing in iOS Settings")
                                    Text("2. Enable Family Controls permission")
                                    Text("3. Add children to your Apple Family")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }

                            Button("Open iOS Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(familyMemberService.familyMembers) { member in
                                FamilyMemberCard(member: member)
                            }
                        }
                    }

                    // Refresh Button
                    Button(action: {
                        loadFamilyMembers()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Family Data")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .disabled(familyMemberService.isLoading)

                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Family Sync")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 8) {
                            FamilyInfoRow(
                                icon: "icloud.fill",
                                text: "Family members are automatically synced from your Apple Family Sharing"
                            )
                            FamilyInfoRow(
                                icon: "shield.fill",
                                text: "Family Controls permission is required to detect family members"
                            )
                            FamilyInfoRow(
                                icon: "person.2.fill",
                                text: "Children must install the app on their devices to participate"
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadFamilyMembers()
            }
            .refreshable {
                await refreshFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let members = try await familyMemberService.fetchFamilyMembers()
                await MainActor.run {
                    familyMemberService.familyMembers = members
                }
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }

    private func refreshFamilyMembers() async {
        do {
            let members = try await familyMemberService.fetchFamilyMembers()
            await MainActor.run {
                familyMemberService.familyMembers = members
            }
        } catch {
            print("Error refreshing family members: \(error)")
        }
    }
}

// MARK: - Family Info Row Component
struct FamilyInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let status: String
    let statusColor: Color
    let icon: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }

            Spacer()

            Image(systemName: icon)
                .foregroundColor(statusColor)
                .font(.title2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct FamilyControlsFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMemberInfo

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(member.isChild ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: member.isChild ? "person.crop.circle.fill" : "person.circle.fill")
                        .foregroundColor(member.isChild ? .green : .blue)
                        .font(.title2)
                )

            // Member Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack {
                    Text(member.isChild ? "Child" : "Parent")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(member.isChild ? Color.green : Color.blue)
                        )

                    Text(member.hasAppInstalled ? "App Installed" : "App Not Installed")
                        .font(.caption)
                        .foregroundColor(member.hasAppInstalled ? .green : .secondary)
                }

                if member.isCurrentUser {
                    Text("Current User")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
            }

            Spacer()

            // Action Button
            Button(action: {
                // Edit member action
            }) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}


struct AppCategorizationView: View {
    @StateObject private var familyControlsService = FamilyControlsService()
    @State private var educationalApps: [AppInfo] = []
    @State private var entertainmentApps: [AppInfo] = []
    @State private var showingAppPicker = false
    @State private var selectedCategory: AppCategory = .educational

    enum AppCategory {
        case educational, entertainment
    }

    var body: some View {
        NavigationStack {
            List {
                // Educational Apps Section
                Section {
                    if educationalApps.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "graduationcap.circle")
                                .font(.title)
                                .foregroundColor(.green)

                            Text("No educational apps configured")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Educational apps earn points when used by children")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ForEach(educationalApps, id: \.name) { app in
                            AppRow(app: app, category: .educational) {
                                removeApp(app, from: .educational)
                            }
                        }
                    }

                    Button("Add Educational Apps") {
                        selectedCategory = .educational
                        showingAppPicker = true
                    }
                    .foregroundColor(.green)
                } header: {
                    Label("Educational Apps", systemImage: "graduationcap.fill")
                        .foregroundColor(.green)
                }

                // Entertainment Apps Section
                Section {
                    if entertainmentApps.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tv.circle")
                                .font(.title)
                                .foregroundColor(.orange)

                            Text("No entertainment apps configured")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Entertainment apps require points to access")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ForEach(entertainmentApps, id: \.name) { app in
                            AppRow(app: app, category: .entertainment) {
                                removeApp(app, from: .entertainment)
                            }
                        }
                    }

                    Button("Add Entertainment Apps") {
                        selectedCategory = .entertainment
                        showingAppPicker = true
                    }
                    .foregroundColor(.orange)
                } header: {
                    Label("Entertainment Apps", systemImage: "tv.fill")
                        .foregroundColor(.orange)
                }

                // Info Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoItem(
                            icon: "star.fill",
                            title: "Educational Apps",
                            description: "Children earn 1 point per minute of educational app usage",
                            color: .green
                        )

                        InfoItem(
                            icon: "clock.fill",
                            title: "Entertainment Apps",
                            description: "Children spend points to unlock entertainment app time",
                            color: .orange
                        )

                        InfoItem(
                            icon: "shield.fill",
                            title: "Family Controls Required",
                            description: "Enable Family Controls to automatically enforce app restrictions",
                            color: .blue
                        )
                    }
                } header: {
                    Text("How It Works")
                }
            }
            .navigationTitle("App Categories")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAppPicker) {
                AppPickerView(
                    category: selectedCategory,
                    onAppsSelected: { apps in
                        addApps(apps, to: selectedCategory)
                    }
                )
            }
        }
    }

    private func addApps(_ apps: [AppInfo], to category: AppCategory) {
        switch category {
        case .educational:
            educationalApps.append(contentsOf: apps)
        case .entertainment:
            entertainmentApps.append(contentsOf: apps)
        }
    }

    private func removeApp(_ app: AppInfo, from category: AppCategory) {
        switch category {
        case .educational:
            educationalApps.removeAll { $0.name == app.name }
        case .entertainment:
            entertainmentApps.removeAll { $0.name == app.name }
        }
    }
}

// MARK: - Supporting Views

struct AppRow: View {
    let app: AppInfo
    let category: AppCategorizationView.AppCategory
    let onRemove: () -> Void

    var body: some View {
        HStack {
            // App Icon Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(category == .educational ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: category == .educational ? "graduationcap.fill" : "tv.fill")
                        .foregroundColor(category == .educational ? .green : .orange)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AppInfo {
    let name: String
    let bundleIdentifier: String
}

struct AppPickerView: View {
    let category: AppCategorizationView.AppCategory
    let onAppsSelected: ([AppInfo]) -> Void
    @Environment(\.dismiss) private var dismiss

    // Sample apps for demonstration
    private let sampleEducationalApps = [
        AppInfo(name: "Khan Academy", bundleIdentifier: "org.khanacademy.khanacademy"),
        AppInfo(name: "Duolingo", bundleIdentifier: "com.duolingo.DuolingoMobile"),
        AppInfo(name: "Swift Playgrounds", bundleIdentifier: "com.apple.swift.playgrounds"),
        AppInfo(name: "ScratchJr", bundleIdentifier: "org.scratchfoundation.scratchjr")
    ]

    private let sampleEntertainmentApps = [
        AppInfo(name: "YouTube", bundleIdentifier: "com.google.ios.youtube"),
        AppInfo(name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically"),
        AppInfo(name: "Netflix", bundleIdentifier: "com.netflix.Netflix"),
        AppInfo(name: "Spotify", bundleIdentifier: "com.spotify.client")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(availableApps, id: \.bundleIdentifier) { app in
                    Button(action: {
                        onAppsSelected([app])
                        dismiss()
                    }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(category == .educational ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: category == .educational ? "graduationcap.fill" : "tv.fill")
                                        .foregroundColor(category == .educational ? .green : .orange)
                                )

                            VStack(alignment: .leading) {
                                Text(app.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var availableApps: [AppInfo] {
        category == .educational ? sampleEducationalApps : sampleEntertainmentApps
    }
}

struct SubscriptionView: View {
    var body: some View {
        SubscriptionManagementView()
    }
}

struct ChildSpecificLearningAppView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var learningApps: [LearningApp] = [
        LearningApp(name: "Khan Academy", targetMinutes: 30, pointsPerMinute: 2, isEnabled: true),
        LearningApp(name: "Duolingo", targetMinutes: 20, pointsPerMinute: 1, isEnabled: true),
        LearningApp(name: "Reading Eggs", targetMinutes: 25, pointsPerMinute: 1, isEnabled: true),
        LearningApp(name: "Scratch Jr", targetMinutes: 15, pointsPerMinute: 2, isEnabled: false),
        LearningApp(name: "DragonBox Math", targetMinutes: 20, pointsPerMinute: 2, isEnabled: false)
    ]
    @State private var showingAddApp = false

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                }

                if selectedChild != nil {
                    // Learning Apps Configuration
                    Section {
                        ForEach($learningApps) { $app in
                            LearningAppConfigRow(app: $app)
                        }

                        Button("Add Learning App") {
                            showingAddApp = true
                        }
                        .foregroundColor(.blue)
                    } header: {
                        Text("Learning Apps")
                    } footer: {
                        Text("Set target duration and reward points for each learning app. When your child reaches the target time, they earn the specified points.")
                    }

                    // Daily Summary
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Target Time")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("per day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(totalTargetTime) min")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Max Points Available")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("per day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("\(maxPointsPerDay)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                    } header: {
                        Text("Daily Summary")
                    }
                }
            }
            .navigationTitle("Learning Apps")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
            .sheet(isPresented: $showingAddApp) {
                AddLearningAppView { newApp in
                    learningApps.append(newApp)
                }
            }
        }
    }

    private var totalTargetTime: Int {
        learningApps.filter(\.isEnabled).reduce(0) { $0 + $1.targetMinutes }
    }

    private var maxPointsPerDay: Int {
        learningApps.filter(\.isEnabled).reduce(0) { $0 + ($1.targetMinutes * $1.pointsPerMinute) }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

struct LearningApp: Identifiable {
    let id = UUID()
    var name: String
    var targetMinutes: Int
    var pointsPerMinute: Int
    var isEnabled: Bool
}

struct LearningAppConfigRow: View {
    @Binding var app: LearningApp

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Target: \(app.targetMinutes) min • \(app.pointsPerMinute) pts/min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $app.isEnabled)
                    .labelsHidden()
            }

            if app.isEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Target Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack {
                            Button("-") {
                                if app.targetMinutes > 5 {
                                    app.targetMinutes -= 5
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)

                            Text("\(app.targetMinutes) min")
                                .font(.caption)
                                .frame(width: 50)

                            Button("+") {
                                if app.targetMinutes < 120 {
                                    app.targetMinutes += 5
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }

                    HStack {
                        Text("Points per Minute")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack {
                            Button("-") {
                                if app.pointsPerMinute > 1 {
                                    app.pointsPerMinute -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)

                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                                Text("\(app.pointsPerMinute)")
                                    .font(.caption)
                                    .frame(width: 30)
                            }

                            Button("+") {
                                if app.pointsPerMinute < 10 {
                                    app.pointsPerMinute += 1
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }

                    HStack {
                        Text("Max Points")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("\(app.targetMinutes * app.pointsPerMinute)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddLearningAppView: View {
    let onAppAdded: (LearningApp) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var appName = ""
    @State private var targetMinutes = 20
    @State private var pointsPerMinute = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("App Details") {
                    TextField("App name", text: $appName)

                    HStack {
                        Text("Target Time")
                        Spacer()
                        Stepper("\(targetMinutes) minutes", value: $targetMinutes, in: 5...120, step: 5)
                    }

                    HStack {
                        Text("Points per Minute")
                        Spacer()
                        Stepper("\(pointsPerMinute) points", value: $pointsPerMinute, in: 1...10)
                    }
                }

                Section {
                    HStack {
                        Text("Max Points per Day")
                            .fontWeight(.medium)
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(targetMinutes * pointsPerMinute)")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle("Add Learning App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newApp = LearningApp(
                            name: appName,
                            targetMinutes: targetMinutes,
                            pointsPerMinute: pointsPerMinute,
                            isEnabled: true
                        )
                        onAppAdded(newApp)
                        dismiss()
                    }
                    .disabled(appName.isEmpty)
                }
            }
        }
    }
}

struct LearningGoalRow: View {
    let title: String
    let icon: String
    let goal: Int
    let color: Color
    let onGoalChanged: (Int) -> Void

    @State private var currentGoal: Int

    init(title: String, icon: String, goal: Int, color: Color, onGoalChanged: @escaping (Int) -> Void) {
        self.title = title
        self.icon = icon
        self.goal = goal
        self.color = color
        self.onGoalChanged = onGoalChanged
        self._currentGoal = State(initialValue: goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(currentGoal) min")
                    .font(.subheadline)
                    .foregroundColor(color)
                    .fontWeight(.medium)
            }

            Slider(value: Binding(
                get: { Double(currentGoal) },
                set: { newValue in
                    currentGoal = Int(newValue)
                    onGoalChanged(currentGoal)
                }
            ), in: 5...60, step: 5) {
                Text("\(title) goal")
            }
            .accentColor(color)

            Text("Daily goal: \(currentGoal) minutes of \(title.lowercased()) learning")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PreferredAppRow: View {
    let appName: String
    let subject: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subject)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: .constant(true))
                .labelsHidden()
        }
    }
}

struct AchievementRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
    }
}

struct ChildSpecificActivityView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var activityReportEnabled = true
    @State private var detailedLoggingEnabled = false
    @State private var activityGoals = ActivityGoals()

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                }

                if selectedChild != nil {
                    // Activity Monitoring Settings
                    Section {
                        Toggle("Activity Reporting", isOn: $activityReportEnabled)
                        Toggle("Detailed App Logging", isOn: $detailedLoggingEnabled)

                        NavigationLink(destination: ActivityNotificationSettingsView()) {
                            Label("Notification Preferences", systemImage: "bell.fill")
                        }

                        NavigationLink(destination: ActivityPrivacySettingsView()) {
                            Label("Privacy Settings", systemImage: "lock.fill")
                        }
                    } header: {
                        Text("Monitoring Settings")
                    } footer: {
                        Text("Control how activity data is collected and reported for this child.")
                    }

                    // Activity Goals
                    Section {
                        ActivityGoalRow(
                            title: "Daily Learning Goal",
                            current: activityGoals.dailyLearningMinutes,
                            target: 60,
                            color: .green,
                            icon: "book.fill"
                        )

                        ActivityGoalRow(
                            title: "Weekly Exercise Goal",
                            current: activityGoals.weeklyExerciseMinutes,
                            target: 300,
                            color: .orange,
                            icon: "figure.run"
                        )

                        ActivityGoalRow(
                            title: "Monthly Reading Goal",
                            current: activityGoals.monthlyReadingBooks,
                            target: 4,
                            color: .blue,
                            icon: "book.closed.fill"
                        )

                        Button("Customize Goals") {
                            // Show goals customization
                        }
                        .foregroundColor(.blue)
                    } header: {
                        Text("Activity Goals")
                    }

                    // Recent Activity Summary
                    Section {
                        VStack(spacing: 12) {
                            ActivitySummaryRow(
                                title: "Today's Learning",
                                value: "45 min",
                                change: "+12 min",
                                isPositive: true,
                                icon: "graduationcap.fill"
                            )

                            ActivitySummaryRow(
                                title: "Screen Time",
                                value: "2h 15m",
                                change: "-30 min",
                                isPositive: true,
                                icon: "iphone"
                            )

                            ActivitySummaryRow(
                                title: "Points Earned",
                                value: "45",
                                change: "+12",
                                isPositive: true,
                                icon: "star.fill"
                            )
                        }

                        NavigationLink(destination: Text("Detailed Activity Report")) {
                            Label("View Detailed Report", systemImage: "chart.bar.fill")
                        }
                    } header: {
                        Text("Recent Activity")
                    }
                }
            }
            .navigationTitle("Activity Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

struct ActivityGoals {
    var dailyLearningMinutes = 45
    var weeklyExerciseMinutes = 180
    var monthlyReadingBooks = 2
}

struct ActivityGoalRow: View {
    let title: String
    let current: Int
    let target: Int
    let color: Color
    let icon: String

    var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(current) / \(target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(color)
        }
        .padding(.vertical, 4)
    }
}

struct ActivitySummaryRow: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(change)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isPositive ? .green : .red)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct ActivityNotificationSettingsView: View {
    @State private var dailyGoalReminders = true
    @State private var activityMilestones = true
    @State private var weeklyReports = false

    var body: some View {
        Form {
            Section {
                Toggle("Daily Goal Reminders", isOn: $dailyGoalReminders)
                Toggle("Activity Milestones", isOn: $activityMilestones)
                Toggle("Weekly Summary Reports", isOn: $weeklyReports)
            } footer: {
                Text("Choose which activity notifications you'd like to receive.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActivityPrivacySettingsView: View {
    @State private var shareWithFamily = true
    @State private var anonymizeData = false
    @State private var dataRetentionDays = 90

    var body: some View {
        Form {
            Section {
                Toggle("Share with Family", isOn: $shareWithFamily)
                Toggle("Anonymize Activity Data", isOn: $anonymizeData)

                HStack {
                    Text("Data Retention")
                    Spacer()
                    Picker("Data Retention", selection: $dataRetentionDays) {
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("1 year").tag(365)
                    }
                    .pickerStyle(.menu)
                }
            } footer: {
                Text("Control how activity data is stored and shared.")
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChildSpecificRewardAppView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var rewardApps: [SimpleRewardApp] = [
        SimpleRewardApp(name: "YouTube Kids", pointsCost: 15, baseDuration: 10, dailyLimit: 30, isEnabled: true),
        SimpleRewardApp(name: "Minecraft", pointsCost: 30, baseDuration: 15, dailyLimit: 60, isEnabled: true),
        SimpleRewardApp(name: "Netflix", pointsCost: 20, baseDuration: 10, dailyLimit: 45, isEnabled: false),
        SimpleRewardApp(name: "Roblox", pointsCost: 25, baseDuration: 12, dailyLimit: 48, isEnabled: true),
        SimpleRewardApp(name: "TikTok", pointsCost: 10, baseDuration: 5, dailyLimit: 15, isEnabled: false)
    ]
    @State private var showingAddApp = false

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                }

                if selectedChild != nil {
                    // Reward Apps Configuration
                    Section {
                        ForEach($rewardApps) { $app in
                            RewardAppConfigRow(app: $app)
                        }

                        Button("Add Reward App") {
                            showingAddApp = true
                        }
                        .foregroundColor(.blue)
                    } header: {
                        Text("Reward Apps")
                    } footer: {
                        Text("Set the point cost to unlock each reward app. Children spend earned points to access these apps.")
                    }

                    // Current Status
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Available Apps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("currently enabled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(enabledAppsCount)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Cheapest Entry")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("minimum cost to start")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text("\(cheapestUnlockCost)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                if let cheapestApp = cheapestApp {
                                    Text("\(cheapestApp.baseDuration)min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Best Value")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("lowest cost per minute")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(String(format: "%.1f", bestValueRate)) pts/min")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                                if let bestValueApp = bestValueApp {
                                    Text(bestValueApp.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Longest Session")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("highest daily limit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(highestDailyLimit)min")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                if let longestApp = longestDailyLimitApp {
                                    Text(longestApp.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Status")
                    }
                }
            }
            .navigationTitle("Reward Apps")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
            .sheet(isPresented: $showingAddApp) {
                AddSimpleRewardAppView { newApp in
                    rewardApps.append(newApp)
                }
            }
        }
    }

    private var enabledAppsCount: Int {
        rewardApps.filter(\.isEnabled).count
    }

    private var cheapestUnlockCost: Int {
        rewardApps.filter(\.isEnabled).map(\.pointsCost).min() ?? 0
    }

    private var cheapestApp: SimpleRewardApp? {
        rewardApps.filter(\.isEnabled).min(by: { $0.pointsCost < $1.pointsCost })
    }

    private var bestValueRate: Double {
        rewardApps.filter(\.isEnabled).map(\.costPerMinute).min() ?? 0
    }

    private var bestValueApp: SimpleRewardApp? {
        rewardApps.filter(\.isEnabled).min(by: { $0.costPerMinute < $1.costPerMinute })
    }

    private var highestDailyLimit: Int {
        rewardApps.filter(\.isEnabled).map(\.dailyLimit).max() ?? 0
    }

    private var longestDailyLimitApp: SimpleRewardApp? {
        rewardApps.filter(\.isEnabled).max(by: { $0.dailyLimit < $1.dailyLimit })
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

struct SimpleRewardApp: Identifiable {
    let id = UUID()
    var name: String
    var pointsCost: Int        // Points needed for base duration
    var baseDuration: Int      // Minutes unlocked for the cost
    var dailyLimit: Int        // Maximum minutes per day regardless of points
    var isEnabled: Bool

    // Calculated property for cost per minute
    var costPerMinute: Double {
        guard baseDuration > 0 else { return 0 }
        return Double(pointsCost) / Double(baseDuration)
    }

    // Maximum sessions per day based on daily limit
    var maxSessionsPerDay: Int {
        guard baseDuration > 0 else { return 0 }
        return dailyLimit / baseDuration
    }
}

struct RewardAppConfigRow: View {
    @Binding var app: SimpleRewardApp

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tv.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text("\(app.pointsCost)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        Text("=")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(app.baseDuration)min")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Text("(\(String(format: "%.1f", app.costPerMinute)) pts/min)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("Daily limit: \(app.dailyLimit)min")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("(max \(app.maxSessionsPerDay) sessions)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: $app.isEnabled)
                    .labelsHidden()
            }

            if app.isEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Cost")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack {
                            Button("-") {
                                if app.pointsCost > 5 {
                                    app.pointsCost -= 5
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)

                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                                Text("\(app.pointsCost)")
                                    .font(.caption)
                                    .frame(width: 30)
                            }

                            Button("+") {
                                if app.pointsCost < 100 {
                                    app.pointsCost += 5
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }

                    HStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack {
                            Button("-") {
                                if app.baseDuration > 5 {
                                    app.baseDuration -= 5
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)

                            Text("\(app.baseDuration) min")
                                .font(.caption)
                                .frame(width: 50)

                            Button("+") {
                                if app.baseDuration < 60 {
                                    app.baseDuration += 5
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }

                    HStack {
                        Text("Daily Limit")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack {
                            Button("-") {
                                if app.dailyLimit > app.baseDuration {
                                    app.dailyLimit -= app.baseDuration
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)

                            Text("\(app.dailyLimit) min")
                                .font(.caption)
                                .frame(width: 50)

                            Button("+") {
                                if app.dailyLimit < 240 {
                                    app.dailyLimit += app.baseDuration
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }

                    HStack {
                        Text("Rate")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(String(format: "%.1f", app.costPerMinute)) points per minute")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Max Sessions")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(app.maxSessionsPerDay) per day")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSimpleRewardAppView: View {
    let onAppAdded: (SimpleRewardApp) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var appName = ""
    @State private var pointsCost = 20
    @State private var baseDuration = 10
    @State private var dailyLimit = 30

    private var costPerMinute: Double {
        guard baseDuration > 0 else { return 0 }
        return Double(pointsCost) / Double(baseDuration)
    }

    private var maxSessionsPerDay: Int {
        guard baseDuration > 0 else { return 0 }
        return dailyLimit / baseDuration
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("App Details") {
                    TextField("App name", text: $appName)

                    HStack {
                        Text("Points Cost")
                        Spacer()
                        Stepper("\(pointsCost) points", value: $pointsCost, in: 5...100, step: 5)
                    }

                    HStack {
                        Text("Session Duration")
                        Spacer()
                        Stepper("\(baseDuration) minutes", value: $baseDuration, in: 5...60, step: 5)
                    }

                    HStack {
                        Text("Daily Limit")
                        Spacer()
                        Stepper("\(dailyLimit) minutes", value: $dailyLimit, in: baseDuration...240, step: baseDuration)
                    }
                }

                Section {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Cost per minute:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(String(format: "%.1f", costPerMinute)) points/min")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("Max sessions per day:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(maxSessionsPerDay) sessions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("How it works:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Child spends \(pointsCost) points to unlock \(baseDuration) minutes of \(appName.isEmpty ? "this app" : appName). Maximum \(dailyLimit) minutes per day (\(maxSessionsPerDay) sessions). They can extend time by spending more points at the same rate until daily limit is reached.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle("Add Reward App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newApp = SimpleRewardApp(
                            name: appName,
                            pointsCost: pointsCost,
                            baseDuration: baseDuration,
                            dailyLimit: dailyLimit,
                            isEnabled: true
                        )
                        onAppAdded(newApp)
                        dismiss()
                    }
                    .disabled(appName.isEmpty)
                }
            }
        }
    }
}

struct RewardApp: Identifiable {
    let id = UUID()
    var name: String
    var category: RewardAppCategory
    var pointsCost: Int
    var timeLimit: Int // minutes
    var isEnabled: Bool

    enum RewardAppCategory {
        case entertainment, gaming, social, other

        var displayName: String {
            switch self {
            case .entertainment: return "Entertainment"
            case .gaming: return "Gaming"
            case .social: return "Social"
            case .other: return "Other"
            }
        }

        var color: Color {
            switch self {
            case .entertainment: return .red
            case .gaming: return .green
            case .social: return .blue
            case .other: return .gray
            }
        }

        var icon: String {
            switch self {
            case .entertainment: return "tv.fill"
            case .gaming: return "gamecontroller.fill"
            case .social: return "person.2.fill"
            case .other: return "app.fill"
            }
        }
    }
}

struct RewardAppRow: View {
    let app: RewardApp
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            // App Info
            HStack(spacing: 12) {
                Image(systemName: app.category.icon)
                    .foregroundColor(app.category.color)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        Text(app.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.purple)
                                .font(.caption)

                            Text("\(app.pointsCost)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(app.timeLimit)m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.caption)
                }

                Toggle("", isOn: .constant(app.isEnabled))
                    .labelsHidden()
                    .onChange(of: app.isEnabled) { _ in
                        onToggle()
                    }
            }
        }
        .padding(.vertical, 4)
        .opacity(app.isEnabled ? 1.0 : 0.6)
    }
}

struct RewardStatsRow: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
}

struct AddRewardAppView: View {
    let onAppAdded: (RewardApp) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var appName = ""
    @State private var selectedCategory: RewardApp.RewardAppCategory = .entertainment
    @State private var pointsCost = 3
    @State private var timeLimit = 30

    var body: some View {
        NavigationStack {
            Form {
                Section("App Details") {
                    TextField("App name", text: $appName)

                    Picker("Category", selection: $selectedCategory) {
                        Text("Entertainment").tag(RewardApp.RewardAppCategory.entertainment)
                        Text("Gaming").tag(RewardApp.RewardAppCategory.gaming)
                        Text("Social").tag(RewardApp.RewardAppCategory.social)
                        Text("Other").tag(RewardApp.RewardAppCategory.other)
                    }
                }

                Section("Cost & Limits") {
                    HStack {
                        Text("Points Cost")
                        Spacer()
                        Stepper("\(pointsCost) points", value: $pointsCost, in: 1...10)
                    }

                    HStack {
                        Text("Time Limit")
                        Spacer()
                        Stepper("\(timeLimit) minutes", value: $timeLimit, in: 5...120, step: 5)
                    }
                }
            }
            .navigationTitle("Add Reward App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newApp = RewardApp(
                            name: appName,
                            category: selectedCategory,
                            pointsCost: pointsCost,
                            timeLimit: timeLimit,
                            isEnabled: true
                        )
                        onAppAdded(newApp)
                        dismiss()
                    }
                    .disabled(appName.isEmpty)
                }
            }
        }
    }
}

struct DefaultRewardSettingsView: View {
    @State private var entertainmentCost = 2
    @State private var gamingCost = 3
    @State private var socialCost = 4
    @State private var otherCost = 2

    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Entertainment Apps", systemImage: "tv.fill")
                        .foregroundColor(.red)
                    Spacer()
                    Stepper("\(entertainmentCost) points", value: $entertainmentCost, in: 1...10)
                }

                HStack {
                    Label("Gaming Apps", systemImage: "gamecontroller.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Stepper("\(gamingCost) points", value: $gamingCost, in: 1...10)
                }

                HStack {
                    Label("Social Apps", systemImage: "person.2.fill")
                        .foregroundColor(.blue)
                    Spacer()
                    Stepper("\(socialCost) points", value: $socialCost, in: 1...10)
                }

                HStack {
                    Label("Other Apps", systemImage: "app.fill")
                        .foregroundColor(.gray)
                    Spacer()
                    Stepper("\(otherCost) points", value: $otherCost, in: 1...10)
                }
            } header: {
                Text("Default Point Costs")
            } footer: {
                Text("These costs will be applied to new reward apps by category.")
            }
        }
        .navigationTitle("Default Costs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RewardTimeLimitSettingsView: View {
    @State private var defaultTimeLimit = 30
    @State private var maxDailyRewardTime = 120
    @State private var resetTime = Date()

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Default Time Limit")
                    Spacer()
                    Stepper("\(defaultTimeLimit) min", value: $defaultTimeLimit, in: 5...120, step: 5)
                }

                HStack {
                    Text("Daily Reward Limit")
                    Spacer()
                    Stepper("\(maxDailyRewardTime) min", value: $maxDailyRewardTime, in: 30...300, step: 15)
                }

                DatePicker("Daily Reset Time", selection: $resetTime, displayedComponents: .hourAndMinute)
            } footer: {
                Text("Time limits help maintain healthy screen time habits.")
            }
        }
        .navigationTitle("Time Limits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RewardScheduleSettingsView: View {
    @State private var weekdayStart = Date()
    @State private var weekdayEnd = Date()
    @State private var weekendStart = Date()
    @State private var weekendEnd = Date()
    @State private var allowDuringBedtime = false

    var body: some View {
        Form {
            Section("Weekdays") {
                DatePicker("Available From", selection: $weekdayStart, displayedComponents: .hourAndMinute)
                DatePicker("Available Until", selection: $weekdayEnd, displayedComponents: .hourAndMinute)
            }

            Section("Weekends") {
                DatePicker("Available From", selection: $weekendStart, displayedComponents: .hourAndMinute)
                DatePicker("Available Until", selection: $weekendEnd, displayedComponents: .hourAndMinute)
            }

            Section {
                Toggle("Allow During Bedtime", isOn: $allowDuringBedtime)
            } footer: {
                Text("Control when reward apps can be accessed throughout the week.")
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChildSpecificSpecialRewardsView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var specialRewards: [SpecialReward] = [
        SpecialReward(name: "Extra 30 min screen time", cost: 50, icon: "clock.fill", category: .screenTime),
        SpecialReward(name: "Choose family movie", cost: 80, icon: "tv.fill", category: .privilege),
        SpecialReward(name: "Stay up 30 min later", cost: 60, icon: "moon.fill", category: .privilege),
        SpecialReward(name: "Pick dinner restaurant", cost: 100, icon: "fork.knife", category: .privilege),
        SpecialReward(name: "Ice cream after dinner", cost: 40, icon: "birthday.cake.fill", category: .treat)
    ]
    @State private var showingAddReward = false

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                }

                if selectedChild != nil {
                    // Special Rewards List
                    Section {
                        ForEach($specialRewards) { $reward in
                            SpecialRewardConfigRow(reward: $reward)
                        }
                        .onDelete(perform: deleteRewards)

                        Button("Add Special Reward") {
                            showingAddReward = true
                        }
                        .foregroundColor(.purple)
                    } header: {
                        Text("Special Rewards")
                    } footer: {
                        Text("Special rewards are unique privileges and treats that children can earn with points. These are typically non-app rewards like extra privileges or real-world treats.")
                    }

                    // Category Summary
                    Section {
                        let groupedRewards = Dictionary(grouping: specialRewards.filter(\.isEnabled)) { $0.category }

                        ForEach(SpecialReward.RewardCategory.allCases, id: \.self) { category in
                            if let rewards = groupedRewards[category], !rewards.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: category.icon)
                                            .foregroundColor(category.color)
                                            .font(.title3)
                                            .frame(width: 24)

                                        Text(category.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Spacer()

                                        Text("\(rewards.count) reward\(rewards.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    HStack {
                                        Text("Cost range:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        let costs = rewards.map(\.cost)
                                        if let minCost = costs.min(), let maxCost = costs.max() {
                                            HStack(spacing: 2) {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                    .font(.caption2)
                                                if minCost == maxCost {
                                                    Text("\(minCost)")
                                                } else {
                                                    Text("\(minCost) - \(maxCost)")
                                                }
                                            }
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                        }
                                    }
                                    .padding(.leading, 32)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Categories Summary")
                    }

                    // Example Costs
                    Section {
                        VStack(spacing: 8) {
                            ForEach(specialRewards.filter(\.isEnabled).prefix(3)) { reward in
                                HStack {
                                    Image(systemName: reward.icon)
                                        .foregroundColor(reward.category.color)
                                        .font(.caption)
                                        .frame(width: 20)

                                    Text(reward.name)
                                        .font(.caption)

                                    Spacer()

                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption2)
                                        Text("\(reward.cost)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Example Costs")
                    }
                }
            }
            .navigationTitle("Special Rewards")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
            .sheet(isPresented: $showingAddReward) {
                AddSpecialRewardView { newReward in
                    specialRewards.append(newReward)
                }
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }

    private func deleteRewards(at offsets: IndexSet) {
        specialRewards.remove(atOffsets: offsets)
    }
}

struct SpecialReward: Identifiable {
    let id = UUID()
    var name: String
    var cost: Int
    var icon: String
    var category: RewardCategory
    var isEnabled: Bool = true

    enum RewardCategory: CaseIterable {
        case privilege, screenTime, treat, activity

        var displayName: String {
            switch self {
            case .privilege: return "Special Privilege"
            case .screenTime: return "Screen Time Bonus"
            case .treat: return "Treat"
            case .activity: return "Activity"
            }
        }

        var color: Color {
            switch self {
            case .privilege: return .blue
            case .screenTime: return .orange
            case .treat: return .pink
            case .activity: return .green
            }
        }

        var icon: String {
            switch self {
            case .privilege: return "star.fill"
            case .screenTime: return "clock.fill"
            case .treat: return "birthday.cake.fill"
            case .activity: return "figure.run"
            }
        }
    }
}

struct SpecialRewardConfigRow: View {
    @Binding var reward: SpecialReward

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: reward.icon)
                    .foregroundColor(reward.category.color)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reward.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        Text(reward.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text("\(reward.cost)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        Text("points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: $reward.isEnabled)
                    .labelsHidden()
            }

            if reward.isEnabled {
                HStack {
                    Text("Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack {
                        Button("-") {
                            if reward.cost > 10 {
                                reward.cost -= 10
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption2)
                            Text("\(reward.cost)")
                                .font(.caption)
                                .frame(width: 30)
                        }

                        Button("+") {
                            if reward.cost < 500 {
                                reward.cost += 10
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSpecialRewardView: View {
    let onRewardAdded: (SpecialReward) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var rewardName = ""
    @State private var rewardCost = 50
    @State private var selectedIcon = "gift.fill"
    @State private var selectedCategory: SpecialReward.RewardCategory = .privilege

    private let availableIcons = [
        "gift.fill", "star.fill", "crown.fill", "trophy.fill",
        "clock.fill", "tv.fill", "gamecontroller.fill",
        "birthday.cake.fill", "ice.cream", "fork.knife",
        "figure.run", "bicycle", "basketball.fill", "music.note"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Reward name", text: $rewardName)

                    HStack {
                        Text("Point Cost")
                        Spacer()
                        Stepper("\(rewardCost) points", value: $rewardCost, in: 10...500, step: 10)
                    }

                    Picker("Category", selection: $selectedCategory) {
                        Text("Special Privilege").tag(SpecialReward.RewardCategory.privilege)
                        Text("Screen Time Bonus").tag(SpecialReward.RewardCategory.screenTime)
                        Text("Treat").tag(SpecialReward.RewardCategory.treat)
                        Text("Activity").tag(SpecialReward.RewardCategory.activity)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : selectedCategory.color)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedIcon == icon ? selectedCategory.color : Color(.systemGray6))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Category:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(selectedCategory.displayName)
                                .font(.subheadline)
                                .foregroundColor(selectedCategory.color)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("How it works:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Child saves up \(rewardCost) points to unlock '\(rewardName.isEmpty ? "this reward" : rewardName)'. Special rewards are unique privileges that go beyond regular app access.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle("Add Special Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newReward = SpecialReward(
                            name: rewardName,
                            cost: rewardCost,
                            icon: selectedIcon,
                            category: selectedCategory,
                            isEnabled: true
                        )
                        onRewardAdded(newReward)
                        dismiss()
                    }
                    .disabled(rewardName.isEmpty)
                }
            }
        }
    }
}

struct BasicTimeLimitsView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var dailyLimits = DailyLimits()

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                }

                if selectedChild != nil {
                    // Basic Time Limits
                    Section {
                        BasicLimitRow(
                            title: "Learning Apps",
                            description: "No limit - encourage learning!",
                            currentLimit: 0,
                            color: .green,
                            icon: "graduationcap.fill",
                            isUnlimited: true
                        )

                        BasicLimitRow(
                            title: "Reward Apps",
                            description: "Total daily allowance",
                            currentLimit: dailyLimits.rewardAppLimit,
                            color: .orange,
                            icon: "tv.fill"
                        ) { newLimit in
                            dailyLimits.rewardAppLimit = newLimit
                        }
                    } header: {
                        Text("Daily Limits")
                    } footer: {
                        Text("Set basic daily limits. Learning apps have no time restrictions to encourage education.")
                    }

                    // Summary
                    Section {
                        HStack {
                            Text("Reward App Time")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(dailyLimits.rewardAppLimit) minutes")
                                .foregroundColor(.orange)
                        }

                        HStack {
                            Text("Learning App Time")
                                .fontWeight(.medium)
                            Spacer()
                            Text("Unlimited")
                                .foregroundColor(.green)
                        }
                    } header: {
                        Text("Summary")
                    }
                }
            }
            .navigationTitle("Time Limits")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

struct DailyLimits {
    var rewardAppLimit = 60 // minutes
}

struct BasicLimitRow: View {
    let title: String
    let description: String
    let currentLimit: Int
    let color: Color
    let icon: String
    var isUnlimited: Bool = false
    var onLimitChanged: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isUnlimited {
                    Text("∞")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                } else {
                    Text("\(currentLimit)m")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }
            }

            if !isUnlimited, let onLimitChanged = onLimitChanged {
                HStack {
                    Text("Daily Limit")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack {
                        Button("-") {
                            if currentLimit > 15 {
                                onLimitChanged(currentLimit - 15)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)

                        Text("\(currentLimit) min")
                            .font(.caption)
                            .frame(width: 60)

                        Button("+") {
                            if currentLimit < 240 {
                                onLimitChanged(currentLimit + 15)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TimeLimitsView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var timeLimitSettings = TimeLimitSettings()
    @State private var showingCustomSchedule = false

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                }

                if selectedChild != nil {
                    // Daily Time Limits
                    Section {
                        TimeLimitRow(
                            title: "Educational Apps",
                            current: timeLimitSettings.educationalAppsLimit,
                            color: .green,
                            icon: "book.fill"
                        ) { newValue in
                            timeLimitSettings.educationalAppsLimit = newValue
                        }

                        TimeLimitRow(
                            title: "Entertainment Apps",
                            current: timeLimitSettings.entertainmentAppsLimit,
                            color: .orange,
                            icon: "tv.fill"
                        ) { newValue in
                            timeLimitSettings.entertainmentAppsLimit = newValue
                        }

                        TimeLimitRow(
                            title: "Social Apps",
                            current: timeLimitSettings.socialAppsLimit,
                            color: .blue,
                            icon: "person.2.fill"
                        ) { newValue in
                            timeLimitSettings.socialAppsLimit = newValue
                        }

                        TimeLimitRow(
                            title: "Gaming Apps",
                            current: timeLimitSettings.gamingAppsLimit,
                            color: .purple,
                            icon: "gamecontroller.fill"
                        ) { newValue in
                            timeLimitSettings.gamingAppsLimit = newValue
                        }

                        HStack {
                            Text("Total Daily Limit")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(totalDailyLimit) minutes")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Daily Time Limits")
                    } footer: {
                        Text("Set maximum daily usage for different app categories.")
                    }

                    // Weekday vs Weekend
                    Section {
                        Toggle("Different Weekend Limits", isOn: $timeLimitSettings.hasWeekendLimits)

                        if timeLimitSettings.hasWeekendLimits {
                            NavigationLink(destination: WeekendTimeLimitsView(settings: $timeLimitSettings)) {
                                Label("Weekend Limits", systemImage: "calendar.badge.plus")
                            }
                        }

                        NavigationLink(destination: CustomScheduleView(settings: $timeLimitSettings)) {
                            Label("Custom Schedule", systemImage: "clock.arrow.circlepath")
                        }
                    } header: {
                        Text("Schedule Options")
                    }

                    // Downtime Settings
                    Section {
                        Toggle("Enable Downtime", isOn: $timeLimitSettings.downtimeEnabled)

                        if timeLimitSettings.downtimeEnabled {
                            DatePicker("Start Time", selection: $timeLimitSettings.downtimeStart, displayedComponents: .hourAndMinute)

                            DatePicker("End Time", selection: $timeLimitSettings.downtimeEnd, displayedComponents: .hourAndMinute)

                            Toggle("Allow Educational Apps", isOn: $timeLimitSettings.allowEducationalDuringDowntime)
                        }
                    } header: {
                        Text("Downtime")
                    } footer: {
                        if timeLimitSettings.downtimeEnabled {
                            Text("During downtime, access to selected apps will be limited.")
                        }
                    }

                    // Break Reminders
                    Section {
                        Toggle("Break Reminders", isOn: $timeLimitSettings.breakRemindersEnabled)

                        if timeLimitSettings.breakRemindersEnabled {
                            HStack {
                                Text("Remind Every")
                                Spacer()
                                Picker("Break Interval", selection: $timeLimitSettings.breakInterval) {
                                    Text("15 minutes").tag(15)
                                    Text("30 minutes").tag(30)
                                    Text("45 minutes").tag(45)
                                    Text("60 minutes").tag(60)
                                }
                                .pickerStyle(.menu)
                            }

                            HStack {
                                Text("Break Duration")
                                Spacer()
                                Picker("Break Duration", selection: $timeLimitSettings.breakDuration) {
                                    Text("5 minutes").tag(5)
                                    Text("10 minutes").tag(10)
                                    Text("15 minutes").tag(15)
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    } header: {
                        Text("Break Reminders")
                    } footer: {
                        if timeLimitSettings.breakRemindersEnabled {
                            Text("Encourage healthy screen time habits with regular break reminders.")
                        }
                    }

                    // Current Usage Today
                    Section {
                        VStack(spacing: 12) {
                            UsageProgressRow(
                                title: "Educational Apps",
                                used: 45,
                                limit: timeLimitSettings.educationalAppsLimit,
                                color: .green
                            )

                            UsageProgressRow(
                                title: "Entertainment Apps",
                                used: 30,
                                limit: timeLimitSettings.entertainmentAppsLimit,
                                color: .orange
                            )

                            UsageProgressRow(
                                title: "Social Apps",
                                used: 15,
                                limit: timeLimitSettings.socialAppsLimit,
                                color: .blue
                            )

                            UsageProgressRow(
                                title: "Gaming Apps",
                                used: 20,
                                limit: timeLimitSettings.gamingAppsLimit,
                                color: .purple
                            )
                        }

                        NavigationLink(destination: Text("Detailed Usage Report")) {
                            Label("View Detailed Usage", systemImage: "chart.bar.fill")
                        }
                    } header: {
                        Text("Today's Usage")
                    }
                }
            }
            .navigationTitle("Time Limits")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private var totalDailyLimit: Int {
        timeLimitSettings.educationalAppsLimit +
        timeLimitSettings.entertainmentAppsLimit +
        timeLimitSettings.socialAppsLimit +
        timeLimitSettings.gamingAppsLimit
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

struct TimeLimitSettings {
    var educationalAppsLimit = 120 // minutes
    var entertainmentAppsLimit = 60
    var socialAppsLimit = 30
    var gamingAppsLimit = 45

    var hasWeekendLimits = false
    var weekendEducationalLimit = 180
    var weekendEntertainmentLimit = 90
    var weekendSocialLimit = 45
    var weekendGamingLimit = 60

    var downtimeEnabled = true
    var downtimeStart = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    var downtimeEnd = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var allowEducationalDuringDowntime = true

    var breakRemindersEnabled = true
    var breakInterval = 30 // minutes
    var breakDuration = 10 // minutes
}

struct TimeLimitRow: View {
    let title: String
    let current: Int
    let color: Color
    let icon: String
    let onChange: (Int) -> Void

    @State private var isEditing = false
    @State private var tempValue: Int

    init(title: String, current: Int, color: Color, icon: String, onChange: @escaping (Int) -> Void) {
        self.title = title
        self.current = current
        self.color = color
        self.icon = icon
        self.onChange = onChange
        self._tempValue = State(initialValue: current)
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            if isEditing {
                HStack {
                    Button("-") {
                        if tempValue > 0 {
                            tempValue -= 15
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Text("\(tempValue)m")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 50)

                    Button("+") {
                        if tempValue < 480 {
                            tempValue += 15
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Done") {
                        onChange(tempValue)
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                Button("\(current) min") {
                    tempValue = current
                    isEditing = true
                }
                .foregroundColor(.blue)
                .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}

struct UsageProgressRow: View {
    let title: String
    let used: Int
    let limit: Int
    let color: Color

    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(Double(used) / Double(limit), 1.0)
    }

    var isOverLimit: Bool {
        used > limit
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(used) / \(limit) min")
                    .font(.subheadline)
                    .foregroundColor(isOverLimit ? .red : .secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(isOverLimit ? .red : color)
        }
        .padding(.vertical, 2)
    }
}

struct WeekendTimeLimitsView: View {
    @Binding var settings: TimeLimitSettings

    var body: some View {
        Form {
            Section {
                TimeLimitRow(
                    title: "Educational Apps",
                    current: settings.weekendEducationalLimit,
                    color: .green,
                    icon: "book.fill"
                ) { newValue in
                    settings.weekendEducationalLimit = newValue
                }

                TimeLimitRow(
                    title: "Entertainment Apps",
                    current: settings.weekendEntertainmentLimit,
                    color: .orange,
                    icon: "tv.fill"
                ) { newValue in
                    settings.weekendEntertainmentLimit = newValue
                }

                TimeLimitRow(
                    title: "Social Apps",
                    current: settings.weekendSocialLimit,
                    color: .blue,
                    icon: "person.2.fill"
                ) { newValue in
                    settings.weekendSocialLimit = newValue
                }

                TimeLimitRow(
                    title: "Gaming Apps",
                    current: settings.weekendGamingLimit,
                    color: .purple,
                    icon: "gamecontroller.fill"
                ) { newValue in
                    settings.weekendGamingLimit = newValue
                }
            } header: {
                Text("Weekend Limits")
            } footer: {
                Text("Different time limits for Saturday and Sunday.")
            }
        }
        .navigationTitle("Weekend Limits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CustomScheduleView: View {
    @Binding var settings: TimeLimitSettings
    @State private var scheduleItems: [ScheduleItem] = [
        ScheduleItem(day: .monday, startTime: Date(), endTime: Date(), isEnabled: true),
        ScheduleItem(day: .tuesday, startTime: Date(), endTime: Date(), isEnabled: true),
        ScheduleItem(day: .wednesday, startTime: Date(), endTime: Date(), isEnabled: true),
        ScheduleItem(day: .thursday, startTime: Date(), endTime: Date(), isEnabled: true),
        ScheduleItem(day: .friday, startTime: Date(), endTime: Date(), isEnabled: true),
        ScheduleItem(day: .saturday, startTime: Date(), endTime: Date(), isEnabled: true),
        ScheduleItem(day: .sunday, startTime: Date(), endTime: Date(), isEnabled: true)
    ]

    var body: some View {
        Form {
            Section {
                ForEach($scheduleItems) { $item in
                    VStack(spacing: 8) {
                        HStack {
                            Text(item.day.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Toggle("", isOn: $item.isEnabled)
                                .labelsHidden()
                        }

                        if item.isEnabled {
                            HStack {
                                DatePicker("From", selection: $item.startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()

                                Text("to")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                DatePicker("To", selection: $item.endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Custom Schedule")
            } footer: {
                Text("Set specific time ranges when apps are available each day.")
            }
        }
        .navigationTitle("Custom Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ScheduleItem: Identifiable {
    let id = UUID()
    let day: Weekday
    var startTime: Date
    var endTime: Date
    var isEnabled: Bool

    enum Weekday: CaseIterable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday

        var displayName: String {
            switch self {
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            case .sunday: return "Sunday"
            }
        }
    }
}

struct BedtimeSettingsView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var bedtimeSettings = BedtimeSettings()

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                }

                if selectedChild != nil {
                    // Bedtime Schedule
                    Section {
                        Toggle("Enable Bedtime", isOn: $bedtimeSettings.isEnabled)

                        if bedtimeSettings.isEnabled {
                            DatePicker("Bedtime", selection: $bedtimeSettings.bedtime, displayedComponents: .hourAndMinute)

                            DatePicker("Wake Time", selection: $bedtimeSettings.wakeTime, displayedComponents: .hourAndMinute)

                            Toggle("Different Weekend Schedule", isOn: $bedtimeSettings.hasWeekendSchedule)

                            if bedtimeSettings.hasWeekendSchedule {
                                DatePicker("Weekend Bedtime", selection: $bedtimeSettings.weekendBedtime, displayedComponents: .hourAndMinute)

                                DatePicker("Weekend Wake Time", selection: $bedtimeSettings.weekendWakeTime, displayedComponents: .hourAndMinute)
                            }
                        }
                    } header: {
                        Text("Sleep Schedule")
                    } footer: {
                        if bedtimeSettings.isEnabled {
                            Text("Devices will be restricted during bedtime hours to promote healthy sleep habits.")
                        }
                    }

                    // Device Restrictions
                    if bedtimeSettings.isEnabled {
                        Section {
                            Toggle("Block All Apps", isOn: $bedtimeSettings.blockAllApps)

                            if !bedtimeSettings.blockAllApps {
                                Toggle("Allow Educational Apps", isOn: $bedtimeSettings.allowEducationalApps)
                                Toggle("Allow Reading Apps", isOn: $bedtimeSettings.allowReadingApps)
                                Toggle("Allow Music Apps", isOn: $bedtimeSettings.allowMusicApps)
                            }

                            Toggle("Dim Display", isOn: $bedtimeSettings.dimDisplay)
                            Toggle("Enable Do Not Disturb", isOn: $bedtimeSettings.enableDoNotDisturb)

                            NavigationLink(destination: BedtimeAllowedAppsView(settings: $bedtimeSettings)) {
                                Label("Allowed Apps", systemImage: "app.badge.checkmark")
                            }
                        } header: {
                            Text("Device Restrictions")
                        }

                        // Wind Down Period
                        Section {
                            Toggle("Enable Wind Down", isOn: $bedtimeSettings.enableWindDown)

                            if bedtimeSettings.enableWindDown {
                                HStack {
                                    Text("Wind Down Duration")
                                    Spacer()
                                    Picker("Duration", selection: $bedtimeSettings.windDownDuration) {
                                        Text("15 minutes").tag(15)
                                        Text("30 minutes").tag(30)
                                        Text("45 minutes").tag(45)
                                        Text("60 minutes").tag(60)
                                    }
                                    .pickerStyle(.menu)
                                }

                                Toggle("Gradual Restrictions", isOn: $bedtimeSettings.gradualRestrictions)
                                Toggle("Wind Down Reminders", isOn: $bedtimeSettings.windDownReminders)
                            }
                        } header: {
                            Text("Wind Down")
                        } footer: {
                            if bedtimeSettings.enableWindDown {
                                Text("Wind down helps children prepare for bedtime by gradually reducing stimulating content.")
                            }
                        }

                        // Sleep Goal Tracking
                        Section {
                            HStack {
                                Text("Target Sleep Duration")
                                Spacer()
                                Picker("Sleep Duration", selection: $bedtimeSettings.targetSleepHours) {
                                    Text("8 hours").tag(8.0)
                                    Text("9 hours").tag(9.0)
                                    Text("10 hours").tag(10.0)
                                    Text("11 hours").tag(11.0)
                                    Text("12 hours").tag(12.0)
                                }
                                .pickerStyle(.menu)
                            }

                            Toggle("Sleep Goal Reminders", isOn: $bedtimeSettings.sleepGoalReminders)
                            Toggle("Weekly Sleep Reports", isOn: $bedtimeSettings.weeklySleepReports)

                            NavigationLink(destination: SleepAnalyticsView()) {
                                Label("Sleep Analytics", systemImage: "moon.stars.fill")
                            }
                        } header: {
                            Text("Sleep Goals")
                        }

                        // Current Status
                        Section {
                            VStack(spacing: 12) {
                                SleepStatusRow(
                                    title: "Bedtime Tonight",
                                    value: DateFormatter.bedtimeFormatter.string(from: bedtimeSettings.bedtime),
                                    icon: "moon.fill",
                                    color: .indigo
                                )

                                SleepStatusRow(
                                    title: "Wake Time Tomorrow",
                                    value: DateFormatter.bedtimeFormatter.string(from: bedtimeSettings.wakeTime),
                                    icon: "sun.max.fill",
                                    color: .orange
                                )

                                SleepStatusRow(
                                    title: "Sleep Duration",
                                    value: String(format: "%.1f hours", bedtimeSettings.targetSleepHours),
                                    icon: "bed.double.fill",
                                    color: .blue
                                )

                                SleepStatusRow(
                                    title: "This Week Average",
                                    value: "8.5 hours",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .green
                                )
                            }
                        } header: {
                            Text("Sleep Status")
                        }
                    }
                }
            }
            .navigationTitle("Bedtime Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

struct BedtimeSettings {
    var isEnabled = true
    var bedtime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    var wakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()

    var hasWeekendSchedule = false
    var weekendBedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var weekendWakeTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    var blockAllApps = false
    var allowEducationalApps = true
    var allowReadingApps = true
    var allowMusicApps = true
    var dimDisplay = true
    var enableDoNotDisturb = true

    var enableWindDown = true
    var windDownDuration = 30 // minutes
    var gradualRestrictions = true
    var windDownReminders = true

    var targetSleepHours = 9.0
    var sleepGoalReminders = true
    var weeklySleepReports = true

    var allowedApps: [String] = ["Books", "Calm", "Headspace"]
}

struct SleepStatusRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct BedtimeAllowedAppsView: View {
    @Binding var settings: BedtimeSettings
    @State private var availableApps = [
        "Books", "Audible", "Kindle", "Calm", "Headspace", "Sleep Stories",
        "Spotify", "Apple Music", "Podcasts", "White Noise", "Nature Sounds"
    ]

    var body: some View {
        Form {
            Section {
                ForEach(availableApps, id: \.self) { app in
                    HStack {
                        Image(systemName: getAppIcon(for: app))
                            .foregroundColor(getAppColor(for: app))
                            .font(.title3)
                            .frame(width: 24)

                        Text(app)
                            .font(.subheadline)

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { settings.allowedApps.contains(app) },
                            set: { isOn in
                                if isOn {
                                    if !settings.allowedApps.contains(app) {
                                        settings.allowedApps.append(app)
                                    }
                                } else {
                                    settings.allowedApps.removeAll { $0 == app }
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Available Apps")
            } footer: {
                Text("Select apps that will remain accessible during bedtime hours.")
            }
        }
        .navigationTitle("Allowed Apps")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func getAppIcon(for app: String) -> String {
        switch app {
        case "Books", "Audible", "Kindle": return "book.fill"
        case "Calm", "Headspace", "Sleep Stories": return "moon.stars.fill"
        case "Spotify", "Apple Music": return "music.note"
        case "Podcasts": return "mic.fill"
        case "White Noise", "Nature Sounds": return "speaker.wave.2.fill"
        default: return "app.fill"
        }
    }

    private func getAppColor(for app: String) -> Color {
        switch app {
        case "Books", "Audible", "Kindle": return .brown
        case "Calm", "Headspace", "Sleep Stories": return .indigo
        case "Spotify": return .green
        case "Apple Music": return .red
        case "Podcasts": return .purple
        case "White Noise", "Nature Sounds": return .blue
        default: return .gray
        }
    }
}

struct SleepAnalyticsView: View {
    @State private var selectedPeriod: SleepPeriod = .week

    enum SleepPeriod: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case threeMonths = "3 Months"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(SleepPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Sleep Statistics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    SleepStatCard(
                        title: "Average Sleep",
                        value: "8.5 hrs",
                        subtitle: "This week",
                        color: .blue,
                        icon: "bed.double.fill"
                    )

                    SleepStatCard(
                        title: "Sleep Goal",
                        value: "94%",
                        subtitle: "Achievement",
                        color: .green,
                        icon: "target"
                    )

                    SleepStatCard(
                        title: "Bedtime Consistency",
                        value: "85%",
                        subtitle: "On time",
                        color: .purple,
                        icon: "clock.fill"
                    )

                    SleepStatCard(
                        title: "Quality Score",
                        value: "Good",
                        subtitle: "Based on routine",
                        color: .orange,
                        icon: "star.fill"
                    )
                }
                .padding(.horizontal)

                // Sleep Trend Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sleep Duration Trend")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    // Placeholder for chart
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay(
                            Text("Sleep duration chart would go here")
                                .foregroundColor(.secondary)
                        )
                        .padding(.horizontal)
                }

                // Weekly Sleep Schedule
                VStack(alignment: .leading, spacing: 12) {
                    Text("This Week's Schedule")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            SleepScheduleRow(
                                day: day,
                                bedtime: "9:00 PM",
                                wakeTime: "7:00 AM",
                                duration: "10.0 hrs",
                                onTime: day != "Fri"
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Sleep Analytics")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SleepStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct SleepScheduleRow: View {
    let day: String
    let bedtime: String
    let wakeTime: String
    let duration: String
    let onTime: Bool

    var body: some View {
        HStack {
            Text(day)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(bedtime) - \(wakeTime)")
                    .font(.subheadline)

                Text(duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: onTime ? "checkmark.circle.fill" : "clock.fill")
                .foregroundColor(onTime ? .green : .orange)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

extension DateFormatter {
    static let bedtimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

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

struct UsageTrendsView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var selectedTimeRange: UsageTrendTimeRange = .week
    @State private var trendData = UsageTrendData()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Child Selection
                    VStack(spacing: 12) {
                        let children = familyMemberService.familyMembers.filter { $0.isChild }
                        if !children.isEmpty {
                            Picker("Child", selection: $selectedChild) {
                                Text("All Children").tag(nil as FamilyMemberInfo?)
                                ForEach(children) { child in
                                    Text(child.name).tag(child as FamilyMemberInfo?)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Time Range Selector
                        Picker("Time Range", selection: $selectedTimeRange) {
                            Text("Week").tag(UsageTrendTimeRange.week)
                            Text("Month").tag(UsageTrendTimeRange.month)
                            Text("3 Months").tag(UsageTrendTimeRange.threeMonths)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Usage Overview Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        UsageTrendCard(
                            title: "Total Screen Time",
                            value: trendData.totalScreenTime,
                            change: trendData.screenTimeChange,
                            isPositive: false,
                            color: .blue,
                            icon: "iphone"
                        )

                        UsageTrendCard(
                            title: "Learning Time",
                            value: trendData.learningTime,
                            change: trendData.learningTimeChange,
                            isPositive: true,
                            color: .green,
                            icon: "book.fill"
                        )

                        UsageTrendCard(
                            title: "Entertainment",
                            value: trendData.entertainmentTime,
                            change: trendData.entertainmentTimeChange,
                            isPositive: false,
                            color: .orange,
                            icon: "tv.fill"
                        )

                        UsageTrendCard(
                            title: "Points Earned",
                            value: "\(trendData.pointsEarned)",
                            change: trendData.pointsChange,
                            isPositive: true,
                            color: .purple,
                            icon: "star.fill"
                        )
                    }
                    .padding(.horizontal)

                    // Daily Usage Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Usage Trends")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        // Placeholder for chart
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                    Text("Usage trends chart would go here")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                            .padding(.horizontal)
                    }

                    // App Category Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App Category Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            CategoryUsageRow(
                                category: "Educational",
                                time: "2h 15m",
                                percentage: 45,
                                color: .green,
                                icon: "graduationcap.fill"
                            )

                            CategoryUsageRow(
                                category: "Entertainment",
                                time: "1h 30m",
                                percentage: 30,
                                color: .orange,
                                icon: "tv.fill"
                            )

                            CategoryUsageRow(
                                category: "Social",
                                time: "45m",
                                percentage: 15,
                                color: .blue,
                                icon: "person.2.fill"
                            )

                            CategoryUsageRow(
                                category: "Gaming",
                                time: "30m",
                                percentage: 10,
                                color: .purple,
                                icon: "gamecontroller.fill"
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Top Apps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most Used Apps")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            TopAppRow(
                                appName: "Khan Academy",
                                time: "45m",
                                category: "Educational",
                                trend: "+5m",
                                isPositive: true,
                                color: .green
                            )

                            TopAppRow(
                                appName: "YouTube Kids",
                                time: "35m",
                                category: "Entertainment",
                                trend: "-10m",
                                isPositive: true,
                                color: .red
                            )

                            TopAppRow(
                                appName: "Duolingo",
                                time: "25m",
                                category: "Educational",
                                trend: "+8m",
                                isPositive: true,
                                color: .green
                            )

                            TopAppRow(
                                appName: "Minecraft",
                                time: "20m",
                                category: "Gaming",
                                trend: "=",
                                isPositive: true,
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Usage Patterns
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Usage Patterns")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            PatternRow(
                                title: "Peak Usage Time",
                                value: "4:00 PM - 6:00 PM",
                                icon: "clock.fill",
                                color: .blue
                            )

                            PatternRow(
                                title: "Most Active Day",
                                value: "Saturday",
                                icon: "calendar.fill",
                                color: .green
                            )

                            PatternRow(
                                title: "Learning Streak",
                                value: "5 days",
                                icon: "flame.fill",
                                color: .orange
                            )

                            PatternRow(
                                title: "Screen-Free Time",
                                value: "2h 30m daily avg",
                                icon: "moon.fill",
                                color: .indigo
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Goals Progress
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goals Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            GoalProgressRow(
                                title: "Weekly Learning Goal",
                                current: 8.5,
                                target: 10.0,
                                unit: "hours",
                                color: .green
                            )

                            GoalProgressRow(
                                title: "Daily Screen Time Limit",
                                current: 4.5,
                                target: 5.0,
                                unit: "hours",
                                color: .orange
                            )

                            GoalProgressRow(
                                title: "Points Goal",
                                current: 85,
                                target: 100,
                                unit: "points",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Usage Trends")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

enum UsageTrendTimeRange: CaseIterable {
    case week, month, threeMonths

    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .threeMonths: return "3 Months"
        }
    }
}

struct UsageTrendData {
    let totalScreenTime = "4h 30m"
    let screenTimeChange = "-15m"
    let learningTime = "2h 15m"
    let learningTimeChange = "+20m"
    let entertainmentTime = "1h 30m"
    let entertainmentTimeChange = "-10m"
    let pointsEarned = 125
    let pointsChange = "+15"
}

struct UsageTrendCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)

                Spacer()

                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(changeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    private var changeColor: Color {
        if change.contains("+") {
            return isPositive ? .green : .red
        } else if change.contains("-") {
            return isPositive ? .red : .green
        } else {
            return .secondary
        }
    }
}

struct CategoryUsageRow: View {
    let category: String
    let time: String
    let percentage: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)

                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(time)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(percentage)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ProgressView(value: Double(percentage), total: 100)
                .progressViewStyle(.linear)
                .tint(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct TopAppRow: View {
    let appName: String
    let time: String
    let category: String
    let trend: String
    let isPositive: Bool
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(trend)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var trendColor: Color {
        if trend.contains("+") {
            return .green
        } else if trend.contains("-") {
            return .red
        } else {
            return .secondary
        }
    }
}

struct PatternRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct GoalProgressRow: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color

    var progress: Double {
        min(current / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(String(format: "%.1f / %.0f %@", current, target, unit))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct LearningAppRewardsView: View {
    @State private var pointsPerMinute: Double = 1.0
    @State private var bonusMultiplier: Double = 1.5
    @State private var dailyStreakBonus: Int = 5
    @State private var weeklyGoalBonus: Int = 50
    @State private var enableStreakBonus: Bool = true
    @State private var enableWeeklyBonus: Bool = true

    var body: some View {
        NavigationStack {
            List {
                // Points Configuration
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Points per minute")
                                .font(.subheadline)

                            Spacer()

                            Text("\(Int(pointsPerMinute)) points")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }

                        Slider(value: $pointsPerMinute, in: 0.5...5.0, step: 0.5) {
                            Text("Points per minute")
                        }
                        .accentColor(.green)

                        Text("Children earn \(Int(pointsPerMinute)) point\(pointsPerMinute == 1 ? "" : "s") for every minute spent in educational apps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Base Points", systemImage: "star.fill")
                        .foregroundColor(.green)
                }

                // Bonus System
                Section {
                    // Streak Bonus
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Daily streak bonus", isOn: $enableStreakBonus)

                        if enableStreakBonus {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Bonus amount")
                                        .font(.subheadline)

                                    Spacer()

                                    Text("+\(dailyStreakBonus) points")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                }

                                Stepper("", value: $dailyStreakBonus, in: 1...20)
                                    .labelsHidden()

                                Text("Extra points awarded when children meet their daily learning goal for consecutive days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 16)
                        }
                    }

                    Divider()

                    // Weekly Goal Bonus
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Weekly goal bonus", isOn: $enableWeeklyBonus)

                        if enableWeeklyBonus {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Bonus amount")
                                        .font(.subheadline)

                                    Spacer()

                                    Text("+\(weeklyGoalBonus) points")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.purple)
                                }

                                Stepper("", value: $weeklyGoalBonus, in: 10...100, step: 10)
                                    .labelsHidden()

                                Text("Extra points awarded when children complete their weekly learning goals")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 16)
                        }
                    }
                } header: {
                    Label("Bonus Points", systemImage: "gift.fill")
                        .foregroundColor(.orange)
                }

                // Special Multipliers
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Weekend multiplier")
                                .font(.subheadline)

                            Spacer()

                            Text("\(String(format: "%.1f", bonusMultiplier))x")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }

                        Slider(value: $bonusMultiplier, in: 1.0...3.0, step: 0.1) {
                            Text("Weekend multiplier")
                        }
                        .accentColor(.blue)

                        Text("Points are multiplied by \(String(format: "%.1f", bonusMultiplier)) on weekends to encourage learning during free time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Multipliers", systemImage: "multiply.circle.fill")
                        .foregroundColor(.blue)
                }

                // Preview Section
                Section {
                    VStack(spacing: 16) {
                        PointsPreviewRow(
                            scenario: "15 min Khan Academy (weekday)",
                            points: Int(15 * pointsPerMinute),
                            color: .green
                        )

                        PointsPreviewRow(
                            scenario: "15 min Khan Academy (weekend)",
                            points: Int(15 * pointsPerMinute * bonusMultiplier),
                            color: .blue
                        )

                        if enableStreakBonus {
                            PointsPreviewRow(
                                scenario: "Daily goal achieved (3-day streak)",
                                points: dailyStreakBonus,
                                color: .orange
                            )
                        }

                        if enableWeeklyBonus {
                            PointsPreviewRow(
                                scenario: "Weekly goal completed",
                                points: weeklyGoalBonus,
                                color: .purple
                            )
                        }
                    }
                } header: {
                    Text("Points Preview")
                }
            }
            .navigationTitle("Learning App Points")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PointsPreviewRow: View {
    let scenario: String
    let points: Int
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Example calculation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(color)
                    .font(.caption)

                Text("+\(points)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RewardCostConfigurationView: View {
    @State private var entertainmentAppCost: Int = 10
    @State private var bonusScreenTimeCost: Int = 5
    @State private var specialRewardCosts: [RewardItem] = [
        RewardItem(name: "Extra 30 min screen time", cost: 15, icon: "clock.fill", category: .screenTime),
        RewardItem(name: "Choose family movie", cost: 25, icon: "tv.fill", category: .privilege),
        RewardItem(name: "Stay up 30 min later", cost: 20, icon: "moon.fill", category: .privilege),
        RewardItem(name: "Pick dinner restaurant", cost: 30, icon: "fork.knife", category: .privilege)
    ]
    @State private var showingAddReward = false

    var body: some View {
        NavigationStack {
            List {
                // Entertainment Apps
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Points per minute")
                                .font(.subheadline)

                            Spacer()

                            Text("\(entertainmentAppCost) points")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }

                        Stepper("", value: $entertainmentAppCost, in: 1...50)
                            .labelsHidden()

                        Text("Children spend \(entertainmentAppCost) point\(entertainmentAppCost == 1 ? "" : "s") for every minute of entertainment app usage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Entertainment Apps", systemImage: "tv.fill")
                        .foregroundColor(.orange)
                }

                // Bonus Screen Time
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Points per minute")
                                .font(.subheadline)

                            Spacer()

                            Text("\(bonusScreenTimeCost) points")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }

                        Stepper("", value: $bonusScreenTimeCost, in: 1...25)
                            .labelsHidden()

                        Text("Additional screen time beyond daily limits costs \(bonusScreenTimeCost) point\(bonusScreenTimeCost == 1 ? "" : "s") per minute")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Bonus Screen Time", systemImage: "clock.badge.plus.fill")
                        .foregroundColor(.blue)
                }

                // Special Rewards
                Section {
                    ForEach(specialRewardCosts) { reward in
                        RewardCostRow(reward: reward) {
                            removeReward(reward)
                        }
                    }

                    Button("Add Custom Reward") {
                        showingAddReward = true
                    }
                    .foregroundColor(.purple)
                } header: {
                    Label("Special Rewards", systemImage: "gift.fill")
                        .foregroundColor(.purple)
                }

                // Cost Examples
                Section {
                    VStack(spacing: 12) {
                        CostExampleRow(
                            activity: "15 min YouTube",
                            cost: entertainmentAppCost * 15,
                            color: .orange
                        )

                        CostExampleRow(
                            activity: "30 min bonus screen time",
                            cost: bonusScreenTimeCost * 30,
                            color: .blue
                        )

                        ForEach(specialRewardCosts.prefix(2)) { reward in
                            CostExampleRow(
                                activity: reward.name,
                                cost: reward.cost,
                                color: .purple
                            )
                        }
                    }
                } header: {
                    Text("Cost Examples")
                }
            }
            .navigationTitle("Reward Costs")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddReward) {
                AddCustomRewardView { newReward in
                    specialRewardCosts.append(newReward)
                }
            }
        }
    }

    private func removeReward(_ reward: RewardItem) {
        specialRewardCosts.removeAll { $0.id == reward.id }
    }
}

struct RewardItem: Identifiable {
    let id = UUID()
    let name: String
    let cost: Int
    let icon: String
    let category: RewardCategory

    enum RewardCategory {
        case screenTime, privilege, treat, activity
    }
}

struct RewardCostRow: View {
    let reward: RewardItem
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Image(systemName: reward.icon)
                .foregroundColor(.purple)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(categoryName(for: reward.category))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.purple)
                    .font(.caption)

                Text("\(reward.cost)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }

            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func categoryName(for category: RewardItem.RewardCategory) -> String {
        switch category {
        case .screenTime: return "Screen Time"
        case .privilege: return "Special Privilege"
        case .treat: return "Treat"
        case .activity: return "Activity"
        }
    }
}

struct CostExampleRow: View {
    let activity: String
    let cost: Int
    let color: Color

    var body: some View {
        HStack {
            Text(activity)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(color)
                    .font(.caption)

                Text("-\(cost)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddCustomRewardView: View {
    let onRewardAdded: (RewardItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var rewardName = ""
    @State private var rewardCost = 10
    @State private var selectedIcon = "gift.fill"
    @State private var selectedCategory: RewardItem.RewardCategory = .privilege

    private let availableIcons = [
        "gift.fill", "star.fill", "heart.fill", "crown.fill",
        "tv.fill", "gamecontroller.fill", "book.fill", "music.note"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Reward name", text: $rewardName)

                    HStack {
                        Text("Cost")
                        Spacer()
                        Stepper("\(rewardCost) points", value: $rewardCost, in: 1...100)
                    }

                    Picker("Category", selection: $selectedCategory) {
                        Text("Special Privilege").tag(RewardItem.RewardCategory.privilege)
                        Text("Screen Time").tag(RewardItem.RewardCategory.screenTime)
                        Text("Treat").tag(RewardItem.RewardCategory.treat)
                        Text("Activity").tag(RewardItem.RewardCategory.activity)
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.purple.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color.purple : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newReward = RewardItem(
                            name: rewardName,
                            cost: rewardCost,
                            icon: selectedIcon,
                            category: selectedCategory
                        )
                        onRewardAdded(newReward)
                        dismiss()
                    }
                    .disabled(rewardName.isEmpty)
                }
            }
        }
    }
}

struct EntertainmentAppCostConfigurationView: View {
    var body: some View {
        Text("Entertainment App Cost Configuration View - To be modularized")
    }
}

// MARK: - Child-Specific App Categories

struct ChildSpecificAppCategoriesView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @StateObject private var familyControlsService = FamilyControlsService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var educationalApps: [String: [AppInfo]] = [:]
    @State private var entertainmentApps: [String: [AppInfo]] = [:]
    @State private var showingAppPicker = false
    @State private var selectedCategory: AppCategory = .educational

    enum AppCategory {
        case educational, entertainment
    }

    var body: some View {
        NavigationStack {
            Form {
                // Child Selection
                Section {
                    let children = familyMemberService.familyMembers.filter { $0.isChild }
                    if children.isEmpty {
                        Text("No children found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Child", selection: $selectedChild) {
                            Text("Select a child").tag(nil as FamilyMemberInfo?)
                            ForEach(children) { child in
                                Text(child.name).tag(child as FamilyMemberInfo?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Child Selection")
                } footer: {
                    Text("App categories are configured per child based on their device.")
                }

                if let selectedChild = selectedChild {
                    // Educational Apps Section
                    Section {
                        let childEducationalApps = educationalApps[selectedChild.id] ?? []
                        if childEducationalApps.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "graduationcap.circle")
                                    .font(.title)
                                    .foregroundColor(.green)
                                Text("No educational apps configured")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Educational apps earn points when used by \(selectedChild.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        } else {
                            ForEach(childEducationalApps, id: \.name) { app in
                                ChildAppRow(app: app, category: .educational) {
                                    removeApp(app, from: .educational, childId: selectedChild.id)
                                }
                            }
                        }

                        Button("Add Educational Apps") {
                            selectedCategory = .educational
                            showingAppPicker = true
                        }
                        .foregroundColor(.green)
                    } header: {
                        Label("Educational Apps", systemImage: "graduationcap.fill")
                            .foregroundColor(.green)
                    }

                    // Entertainment Apps Section
                    Section {
                        let childEntertainmentApps = entertainmentApps[selectedChild.id] ?? []
                        if childEntertainmentApps.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tv.circle")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text("No entertainment apps configured")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Entertainment apps require points to access for \(selectedChild.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        } else {
                            ForEach(childEntertainmentApps, id: \.name) { app in
                                ChildAppRow(app: app, category: .entertainment) {
                                    removeApp(app, from: .entertainment, childId: selectedChild.id)
                                }
                            }
                        }

                        Button("Add Entertainment Apps") {
                            selectedCategory = .entertainment
                            showingAppPicker = true
                        }
                        .foregroundColor(.orange)
                    } header: {
                        Label("Entertainment Apps", systemImage: "tv.fill")
                            .foregroundColor(.orange)
                    }

                    // Summary for Selected Child
                    Section {
                        let childEducationalCount = educationalApps[selectedChild.id]?.count ?? 0
                        let childEntertainmentCount = entertainmentApps[selectedChild.id]?.count ?? 0

                        HStack {
                            Text("Educational Apps")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(childEducationalCount)")
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("Entertainment Apps")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(childEntertainmentCount)")
                                .foregroundColor(.orange)
                        }
                    } header: {
                        Text("\(selectedChild.name)'s App Summary")
                    }

                    // Info Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            ChildInfoItem(
                                icon: "star.fill",
                                title: "Educational Apps",
                                description: "\(selectedChild.name) earns points when using educational apps",
                                color: .green
                            )
                            ChildInfoItem(
                                icon: "clock.fill",
                                title: "Entertainment Apps",
                                description: "\(selectedChild.name) spends points to unlock entertainment apps",
                                color: .orange
                            )
                            ChildInfoItem(
                                icon: "shield.fill",
                                title: "Device-Specific",
                                description: "Apps are detected from \(selectedChild.name)'s device",
                                color: .blue
                            )
                        }
                    } header: {
                        Text("How It Works")
                    }
                }
            }
            .navigationTitle("App Categories")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
            .sheet(isPresented: $showingAppPicker) {
                if let selectedChild = selectedChild {
                    ChildAppPickerView(
                        child: selectedChild,
                        category: selectedCategory,
                        onAppsSelected: { apps in
                            addApps(apps, to: selectedCategory, childId: selectedChild.id)
                        }
                    )
                }
            }
        }
    }

    private func addApps(_ apps: [AppInfo], to category: AppCategory, childId: String) {
        switch category {
        case .educational:
            if educationalApps[childId] == nil {
                educationalApps[childId] = []
            }
            educationalApps[childId]?.append(contentsOf: apps)
        case .entertainment:
            if entertainmentApps[childId] == nil {
                entertainmentApps[childId] = []
            }
            entertainmentApps[childId]?.append(contentsOf: apps)
        }
    }

    private func removeApp(_ app: AppInfo, from category: AppCategory, childId: String) {
        switch category {
        case .educational:
            educationalApps[childId]?.removeAll { $0.name == app.name }
        case .entertainment:
            entertainmentApps[childId]?.removeAll { $0.name == app.name }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

// MARK: - Child-Specific Supporting Views

struct ChildAppRow: View {
    let app: AppInfo
    let category: ChildSpecificAppCategoriesView.AppCategory
    let onRemove: () -> Void

    var body: some View {
        HStack {
            // App Icon Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(category == .educational ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: category == .educational ? "graduationcap.fill" : "tv.fill")
                        .foregroundColor(category == .educational ? .green : .orange)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChildInfoItem: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
    }
}

struct ChildAppPickerView: View {
    let child: FamilyMemberInfo
    let category: ChildSpecificAppCategoriesView.AppCategory
    let onAppsSelected: ([AppInfo]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedApps: [AppInfo] = []
    @State private var availableApps: [AppInfo] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if availableApps.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "iphone")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("Loading apps from \(child.name)'s device...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        ForEach(availableApps, id: \.name) { app in
                            HStack {
                                // App Icon Placeholder
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(category == .educational ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: category == .educational ? "graduationcap.fill" : "tv.fill")
                                            .foregroundColor(category == .educational ? .green : .orange)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(app.bundleIdentifier)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedApps.contains(where: { $0.name == app.name }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleAppSelection(app)
                            }
                        }
                    }
                } header: {
                    Text("\(category == .educational ? "Educational" : "Entertainment") Apps on \(child.name)'s Device")
                }
            }
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedApps.count))") {
                        onAppsSelected(selectedApps)
                        dismiss()
                    }
                    .disabled(selectedApps.isEmpty)
                }
            }
            .onAppear {
                loadAppsForChild()
            }
        }
    }

    private func toggleAppSelection(_ app: AppInfo) {
        if let index = selectedApps.firstIndex(where: { $0.name == app.name }) {
            selectedApps.remove(at: index)
        } else {
            selectedApps.append(app)
        }
    }

    private func loadAppsForChild() {
        // Mock data for now - in real implementation, this would fetch apps from the child's device
        availableApps = [
            AppInfo(name: "Khan Academy Kids", bundleIdentifier: "org.khanacademy.khanacademykids"),
            AppInfo(name: "Duolingo", bundleIdentifier: "com.duolingo.DuolingoMobile"),
            AppInfo(name: "Scratch Jr", bundleIdentifier: "org.scratchfoundation.scratchjr"),
            AppInfo(name: "YouTube Kids", bundleIdentifier: "com.google.ios.youtubemobile"),
            AppInfo(name: "Minecraft", bundleIdentifier: "com.mojang.minecraftpe"),
            AppInfo(name: "Netflix", bundleIdentifier: "com.netflix.Netflix"),
            AppInfo(name: "Disney+", bundleIdentifier: "com.disney.disneyplus"),
            AppInfo(name: "Roblox", bundleIdentifier: "com.roblox.robloxmobile")
        ]
    }
}

#if DEBUG
struct ParentSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ParentSettingsView()
    }
}
#endif