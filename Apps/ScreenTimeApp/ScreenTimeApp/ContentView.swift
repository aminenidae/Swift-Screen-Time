//
//  ContentView.swift
//  ScreenTimeApp
//
//  Created by Amine Nidae on 2025-09-25.
//

import SwiftUI
import CoreData
import FamilyControls
import FamilyControlsKit
import DesignSystem
import SharedModels

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if userRole == "child" {
                    ChildMainView()
                } else {
                    ParentMainView()
                }
            } else {
                OnboardingView()
            }
        }
    }
}

// MARK: - Child Dashboard
struct ChildMainView: View {
    @State private var currentPoints: Int = 125
    @State private var dailyGoal: Int = 200
    @State private var todayStreak: Int = 3

    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress Section
                        VStack(spacing: 16) {
                            // Progress Ring
                            ZStack {
                                Circle()
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 12)
                                    .frame(width: 150, height: 150)

                                Circle()
                                    .trim(from: 0, to: CGFloat(currentPoints) / CGFloat(dailyGoal))
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .frame(width: 150, height: 150)
                                    .rotationEffect(.degrees(-90))

                                VStack {
                                    Text("\(currentPoints)")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Text("points")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("Daily Goal: \(dailyGoal) points")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Streak Section
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text("\(todayStreak) Day Streak!")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Text("Keep learning to maintain your streak")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )

                        // Recent Activity
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Learning")
                                .font(.headline)
                                .fontWeight(.semibold)

                            VStack(spacing: 8) {
                                LearningActivityRow(
                                    appName: "Khan Academy",
                                    duration: "25 min",
                                    pointsEarned: 25,
                                    timeAgo: "2 hours ago"
                                )

                                LearningActivityRow(
                                    appName: "Duolingo",
                                    duration: "15 min",
                                    pointsEarned: 15,
                                    timeAgo: "Yesterday"
                                )

                                LearningActivityRow(
                                    appName: "Brilliant",
                                    duration: "30 min",
                                    pointsEarned: 30,
                                    timeAgo: "2 days ago"
                                )
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("My Dashboard")
                .refreshable {
                    // Refresh data
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Dashboard")
            }

            // Rewards Tab
            RewardsView()
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Rewards")
                }

            // Profile Tab
            ChildProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

struct LearningActivityRow: View {
    let appName: String
    let duration: String
    let pointsEarned: Int
    let timeAgo: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(duration) • \(timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)

                Text("+\(pointsEarned)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct RewardsView: View {
    let availableRewards = [
        ("Extra Screen Time", 50, "30 minutes of reward time"),
        ("Movie Night", 100, "Choose tonight's family movie"),
        ("Late Bedtime", 75, "Stay up 30 minutes later"),
        ("Ice Cream Treat", 25, "Special dessert")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(availableRewards.enumerated()), id: \.offset) { index, reward in
                        RewardCard(
                            title: reward.0,
                            cost: reward.1,
                            description: reward.2,
                            canAfford: true
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Rewards")
        }
    }
}

struct RewardCard: View {
    let title: String
    let cost: Int
    let description: String
    let canAfford: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Text("\(cost)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    Button("Redeem") {
                        // Handle redemption
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canAfford)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ChildProfileView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingProfileSwitcher = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Alex")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Learning Enthusiast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Stats")
                            .font(.headline)
                            .fontWeight(.semibold)

                        HStack(spacing: 20) {
                            StatCard(title: "Total Points", value: "1,250", icon: "star.fill", color: .yellow)
                            StatCard(title: "Learning Hours", value: "24.5", icon: "book.fill", color: .green)
                            StatCard(title: "Current Streak", value: "3", icon: "flame.fill", color: .orange)
                        }
                    }

                    // Profile Switching Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Button(action: {
                            showingProfileSwitcher = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading) {
                                    Text("Switch Profile")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text("Switch to parent view or change user")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingProfileSwitcher) {
                ProfileSwitcherView()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Parent Dashboard
struct ParentMainView: View {
    var body: some View {
        TabView {
            // Family Overview Tab
            FamilyOverviewView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Family")
                }

            // Activity Tab
            ActivityView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Activity")
                }

            // Settings Tab
            ParentSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}

struct FamilyOverviewView: View {
    let children = [
        ("Alex", 125, 85, 3),
        ("Sam", 95, 60, 1)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Family Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Family Overview")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            OverviewStatCard(title: "Children", value: "\(children.count)", icon: "person.2.fill", color: .blue)
                            OverviewStatCard(title: "Total Points", value: "\(children.reduce(0) { $0 + $1.1 })", icon: "star.fill", color: .yellow)
                            OverviewStatCard(title: "Active Today", value: "\(children.filter { $0.3 > 0 }.count)", icon: "checkmark.circle.fill", color: .green)
                        }
                    }

                    // Children Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Children's Progress")
                            .font(.title2)
                            .fontWeight(.bold)

                        ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                            ChildProgressCard(
                                name: child.0,
                                points: child.1,
                                learningMinutes: child.2,
                                streak: child.3
                            )
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.bold)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            QuickActionCard(title: "Add Child", icon: "person.badge.plus.fill", action: {})
                            QuickActionCard(title: "App Categories", icon: "apps.iphone", action: {})
                            QuickActionCard(title: "Time Limits", icon: "clock.fill", action: {})
                            QuickActionCard(title: "Reports", icon: "chart.bar.fill", action: {})
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Family Dashboard")
            .refreshable {
                // Refresh family data
            }
        }
    }
}

struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ChildProgressCard: View {
    let name: String
    let points: Int
    let learningMinutes: Int
    let streak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("\(points) points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Text("\(streak) day streak")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.2))
                    )
                }
            }

            HStack {
                Label("\(learningMinutes) min learning today", systemImage: "book.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActivityView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Recent family activity will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Activity Feed")
        }
    }
}

struct ParentSettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Family Management") {
                    NavigationLink(destination: Text("Family Settings")) {
                        Label("Family Settings", systemImage: "house.fill")
                    }

                    NavigationLink(destination: Text("Add Child")) {
                        Label("Add Child", systemImage: "person.badge.plus.fill")
                    }
                }

                Section("Screen Time Controls") {
                    NavigationLink(destination: FamilyControlsSetupView()) {
                        Label("Family Controls Setup", systemImage: "shield.fill")
                    }

                    NavigationLink(destination: AppCategorizationView()) {
                        Label("App Categories", systemImage: "apps.iphone")
                    }

                    NavigationLink(destination: Text("Time Limits")) {
                        Label("Daily Time Limits", systemImage: "clock.fill")
                    }

                    NavigationLink(destination: Text("Bedtime")) {
                        Label("Bedtime Settings", systemImage: "moon.fill")
                    }
                }

                Section("Reports & Analytics") {
                    NavigationLink(destination: Text("Detailed Reports")) {
                        Label("Detailed Reports", systemImage: "chart.bar.fill")
                    }

                    NavigationLink(destination: Text("Usage Trends")) {
                        Label("Usage Trends", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                Section("Account") {
                    NavigationLink(destination: Text("Subscription")) {
                        Label("Subscription", systemImage: "star.fill")
                    }

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
        }
    }
}

// MARK: - Onboarding
struct OnboardingView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Logo and Welcome
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Screen Time Rewards")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Transform screen time into learning time with our reward-based system")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Role Selection
                VStack(spacing: 16) {
                    Text("Who will be using this device?")
                        .font(.headline)

                    VStack(spacing: 12) {
                        RoleSelectionButton(
                            title: "I'm a Parent",
                            subtitle: "Set up family profiles, track progress, and manage rewards",
                            icon: "person.2.fill",
                            isSelected: userRole == "parent"
                        ) {
                            userRole = "parent"
                        }

                        RoleSelectionButton(
                            title: "I'm a Child",
                            subtitle: "View my progress, earn points, and redeem rewards",
                            icon: "person.fill",
                            isSelected: userRole == "child"
                        ) {
                            userRole = "child"
                        }
                    }
                }

                Spacer()

                // Continue Button
                Button("Get Started") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
            }
            .padding()
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RoleSelectionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Switcher
struct ProfileSwitcherView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Switch Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose which profile to use")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    ProfileSwitchButton(
                        title: "Parent Profile",
                        subtitle: "Manage family settings, view reports, and control screen time",
                        icon: "person.2.fill",
                        isSelected: userRole == "parent"
                    ) {
                        userRole = "parent"
                        dismiss()
                    }

                    ProfileSwitchButton(
                        title: "Child Profile",
                        subtitle: "View progress, earn points, and redeem rewards",
                        icon: "person.fill",
                        isSelected: userRole == "child"
                    ) {
                        userRole = "child"
                        dismiss()
                    }
                }

                Divider()

                Button("Reset App") {
                    hasCompletedOnboarding = false
                    dismiss()
                }
                .foregroundColor(.red)
                .font(.subheadline)

                Spacer()
            }
            .padding()
            .navigationTitle("Switch Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileSwitchButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Family Controls Setup
struct FamilyControlsSetupView: View {
    @StateObject private var appDiscoveryService = AppDiscoveryService()
    @State private var isRequestingAuthorization = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            // Status Section
            VStack(spacing: 16) {
                Image(systemName: statusIcon)
                    .font(.system(size: 60))
                    .foregroundColor(statusColor)

                Text(statusTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Action Section
            if appDiscoveryService.authorizationStatus != .approved {
                VStack(spacing: 16) {
                    Button(action: requestAuthorization) {
                        HStack {
                            if isRequestingAuthorization {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "shield.fill")
                            }

                            Text(isRequestingAuthorization ? "Requesting..." : "Enable Family Controls")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingAuthorization)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Button("Test App Discovery") {
                        Task {
                            do {
                                let apps = try await appDiscoveryService.fetchInstalledApps()
                                print("Found \(apps.count) apps")
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Family Controls is enabled and working!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            // Information Section
            VStack(alignment: .leading, spacing: 12) {
                Text("What Family Controls enables:")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "apps.iphone", text: "Monitor app usage and screen time")
                    InfoRow(icon: "clock.fill", text: "Track educational vs entertainment apps")
                    InfoRow(icon: "star.fill", text: "Award points for productive screen time")
                    InfoRow(icon: "shield.fill", text: "Secure, privacy-focused monitoring")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding()
        .navigationTitle("Family Controls")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appDiscoveryService.updateAuthorizationStatus()
        }
    }

    private var statusIcon: String {
        switch appDiscoveryService.authorizationStatus {
        case .notDetermined:
            return "questionmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .approved:
            return "checkmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch appDiscoveryService.authorizationStatus {
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

    private var statusTitle: String {
        switch appDiscoveryService.authorizationStatus {
        case .notDetermined:
            return "Setup Required"
        case .denied:
            return "Permission Denied"
        case .approved:
            return "Ready to Use"
        @unknown default:
            return "Unknown Status"
        }
    }

    private var statusDescription: String {
        switch appDiscoveryService.authorizationStatus {
        case .notDetermined:
            return "Enable Family Controls to start monitoring screen time and awarding points for educational activities."
        case .denied:
            return "Family Controls permission was denied. Please enable it in Settings > Screen Time > Family Controls."
        case .approved:
            return "Family Controls is enabled. You can now monitor app usage and award points for learning activities."
        @unknown default:
            return "Unable to determine Family Controls status."
        }
    }

    private func requestAuthorization() {
        isRequestingAuthorization = true
        errorMessage = nil

        Task {
            do {
                if #available(iOS 16.0, *) {
                    try await appDiscoveryService.requestAuthorization()
                } else {
                    try await appDiscoveryService.requestAuthorizationLegacy()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isRequestingAuthorization = false
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.subheadline)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - App Categorization
struct AppCategorizationView: View {
    @StateObject private var appDiscoveryService = AppDiscoveryService()
    @State private var apps: [AppMetadata] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if appDiscoveryService.authorizationStatus != .approved {
                VStack(spacing: 16) {
                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text("Family Controls Required")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Please enable Family Controls first to categorize apps.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    NavigationLink(destination: FamilyControlsSetupView()) {
                        Text("Enable Family Controls")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            } else {
                List {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading apps...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if apps.isEmpty {
                        Button("Load Apps") {
                            loadApps()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Section("Educational Apps") {
                            ForEach(apps.filter { isEducationalApp($0) }, id: \.id) { app in
                                AppCategoryRow(app: app, category: .educational)
                            }
                        }

                        Section("Entertainment Apps") {
                            ForEach(apps.filter { !isEducationalApp($0) }, id: \.id) { app in
                                AppCategoryRow(app: app, category: .entertainment)
                            }
                        }
                    }
                }
                .refreshable {
                    loadApps()
                }
            }
        }
        .navigationTitle("App Categories")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if appDiscoveryService.authorizationStatus == .approved && apps.isEmpty {
                loadApps()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadApps() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedApps = try await appDiscoveryService.fetchInstalledApps()
                await MainActor.run {
                    apps = loadedApps
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func isEducationalApp(_ app: AppMetadata) -> Bool {
        let educationalBundleIDs = [
            "com.khanacademy.iphone",
            "com.duolingo.DuolingoMobile",
            "com.brilliant.Brilliant"
        ]
        return educationalBundleIDs.contains(app.bundleID)
    }
}

struct AppCategoryRow: View {
    let app: AppMetadata
    let category: AppCategory

    var body: some View {
        HStack {
            Image(systemName: "app.fill")
                .foregroundColor(category == .educational ? .green : .orange)

            VStack(alignment: .leading) {
                Text(app.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(app.bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(category.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(category == .educational ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                )
                .foregroundColor(category == .educational ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}

enum AppCategory: String, CaseIterable {
    case educational = "educational"
    case entertainment = "entertainment"
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
