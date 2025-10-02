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
import CloudKitService
import SubscriptionService

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
                    AuthenticatedParentView {
                        ParentMainView()
                    }
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
            NavigationStack {
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
    @State private var currentPoints: Int = 125
    @State private var entertainmentApps: [EntertainmentAppConfig] = []
    @State private var unlockedApps: [AppUnlockInfo] = []
    @State private var redeemedRewards: [RedeemedReward] = []
    @State private var showingRedemptionAlert = false
    @State private var selectedReward: String = ""
    @StateObject private var familyControlsService = FamilyControlsService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Points Balance Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)

                        VStack(spacing: 4) {
                            Text("\(currentPoints)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)

                            Text("Available Points")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Available Entertainment Apps
                    LazyVStack(spacing: 16) {
                        ForEach(entertainmentApps, id: \.bundleID) { app in
                            EntertainmentAppUnlockCard(
                                app: app,
                                currentPoints: currentPoints,
                                isUnlocked: isAppCurrentlyUnlocked(app.bundleID),
                                onUnlock: { durationMinutes in
                                    unlockApp(app, durationMinutes: durationMinutes)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Recent Redemptions
                    if !redeemedRewards.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Redemptions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            LazyVStack(spacing: 12) {
                                ForEach(redeemedRewards.prefix(3), id: \.id) { reward in
                                    RecentRedemptionRow(reward: reward)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Rewards")
            .refreshable {
                // Refresh points and rewards
                loadRewardsConfiguration()
            }
            .onAppear {
                loadRewardsConfiguration()
            }
        }
        .alert("Reward Redeemed!", isPresented: $showingRedemptionAlert) {
            Button("Awesome!") { }
        } message: {
            Text("Your \(selectedReward) reward has been redeemed! Ask your parent to approve it.")
        }
    }

    private func loadRewardsConfiguration() {
        // Load entertainment app configurations from UserDefaults
        loadEntertainmentApps()
        loadUnlockedApps()
    }

    private func loadEntertainmentApps() {
        // Load saved entertainment app configurations
        let defaults = UserDefaults.standard
        var apps: [EntertainmentAppConfig] = []

        // Common entertainment apps with default costs
        let defaultApps = [
            ("com.zhiliaoapp.musically", "TikTok", 30, 50),
            ("com.instagram.instagram", "Instagram", 25, 45),
            ("com.snapchat.snapchat", "Snapchat", 25, 45),
            ("com.youtube.youtube", "YouTube", 20, 35),
            ("com.spotify.client", "Spotify", 15, 25),
            ("com.netflix.Netflix", "Netflix", 40, 70),
            ("com.roblox.robloxmobile", "Roblox", 35, 60),
            ("com.miHoYo.GenshinImpact", "Genshin Impact", 45, 80)
        ]

        for (bundleID, name, cost30, cost60) in defaultApps {
            if let data = defaults.data(forKey: "entertainment_app_\(bundleID)"),
               let saved = try? JSONDecoder().decode(EntertainmentAppConfig.self, from: data) {
                apps.append(saved)
            } else {
                // Use default configuration
                let config = EntertainmentAppConfig(
                    bundleID: bundleID,
                    displayName: name,
                    pointsCostPer30Min: cost30,
                    pointsCostPer60Min: cost60,
                    isEnabled: true,
                    parentConfiguredAt: Date()
                )
                apps.append(config)
            }
        }

        entertainmentApps = apps.filter { $0.isEnabled }
    }

    private func loadUnlockedApps() {
        Task {
            do {
                unlockedApps = try await familyControlsService.getUnlockedApps(for: "default")
            } catch {
                print("Error loading unlocked apps: \(error)")
            }
        }
    }

    private func isAppCurrentlyUnlocked(_ bundleID: String) -> Bool {
        return unlockedApps.contains { $0.bundleID == bundleID && $0.isActive }
    }

    private func unlockApp(_ app: EntertainmentAppConfig, durationMinutes: Int) {
        let pointsCost = app.pointsCost(for: durationMinutes)

        guard currentPoints >= pointsCost else {
            // Not enough points
            return
        }

        Task {
            do {
                let result = try await familyControlsService.unlockApp(
                    bundleID: app.bundleID,
                    durationMinutes: durationMinutes,
                    pointsCost: pointsCost,
                    childID: "default"
                )

                await MainActor.run {
                    switch result {
                    case .success(let unlockInfo):
                        // Deduct points
                        currentPoints -= pointsCost

                        // Add to unlocked apps
                        unlockedApps.append(unlockInfo)

                        // Show success
                        selectedReward = "\(app.displayName) (\(durationMinutes) min)"
                        showingRedemptionAlert = true

                    case .authorizationRequired:
                        // Handle authorization needed
                        break
                    case .appNotFound:
                        // Handle app not found
                        break
                    case .alreadyUnlocked:
                        // Handle already unlocked
                        break
                    case .systemError:
                        // Handle system error
                        break
                    }
                }
            } catch {
                print("Error unlocking app: \(error)")
            }
        }
    }

    private func getRewardDescription(_ rewardName: String) -> String {
        switch rewardName {
        case "Extra Screen Time":
            return "30 minutes of bonus screen time"
        case "Movie Night":
            return "Choose tonight's family movie"
        case "Late Bedtime":
            return "Stay up 30 minutes later"
        case "Ice Cream Treat":
            return "Special dessert after dinner"
        case "Special Toy":
            return "Pick a new toy or game"
        case "Friend Playdate":
            return "Invite a friend over to play"
        case "Choose Dinner":
            return "Pick what's for dinner tonight"
        case "Stay Up Late":
            return "Stay up 1 hour past bedtime"
        default:
            return "Special reward from your parents"
        }
    }

    private func redeemReward(_ rewardName: String, cost: Int) {
        guard currentPoints >= cost else { return }

        // Deduct points
        currentPoints -= cost

        // Add to redeemed rewards
        let redemption = RedeemedReward(
            id: UUID(),
            name: rewardName,
            cost: cost,
            redeemedAt: Date(),
            status: .pending
        )
        redeemedRewards.insert(redemption, at: 0)

        // Show success alert
        selectedReward = rewardName
        showingRedemptionAlert = true

        // In a real app, this would sync with parent's device and send notifications
        // TODO: Implement CloudKit sync and parent notifications
    }
}

struct RewardCard: View {
    let title: String
    let cost: Int
    let description: String
    let canAfford: Bool
    let currentPoints: Int
    let onRedeem: () -> Void

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
                            .foregroundColor(canAfford ? .primary : .secondary)
                    }

                    Button("Redeem") {
                        onRedeem()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canAfford)
                }
            }

            if !canAfford {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text("Need \(cost - currentPoints) more points")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(canAfford ? 1.0 : 0.7)
    }
}

// MARK: - Entertainment App Unlock Card
struct EntertainmentAppUnlockCard: View {
    let app: EntertainmentAppConfig
    let currentPoints: Int
    let isUnlocked: Bool
    let onUnlock: (Int) -> Void

    @State private var showingDurationPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(app.bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isUnlocked {
                        Label("Currently Unlocked", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Blocked", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Text("\(app.pointsCostPer30Min)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("/ 30min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isUnlocked {
                        Button("Already Unlocked") {
                            // Already unlocked, can't unlock again
                        }
                        .buttonStyle(.bordered)
                        .disabled(true)
                    } else {
                        Button("Unlock App") {
                            showingDurationPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentPoints < app.pointsCostPer30Min)
                    }
                }
            }

            // Duration and cost options
            if !isUnlocked {
                HStack(spacing: 16) {
                    DurationOptionButton(
                        duration: 30,
                        cost: app.pointsCostPer30Min,
                        canAfford: currentPoints >= app.pointsCostPer30Min,
                        onTap: { onUnlock(30) }
                    )

                    DurationOptionButton(
                        duration: 60,
                        cost: app.pointsCostPer60Min,
                        canAfford: currentPoints >= app.pointsCostPer60Min,
                        onTap: { onUnlock(60) }
                    )
                }
            }

            // Insufficient points warning
            if !isUnlocked && currentPoints < app.pointsCostPer30Min {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text("Need \(app.pointsCostPer30Min - currentPoints) more points")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(isUnlocked ? 0.8 : 1.0)
        .sheet(isPresented: $showingDurationPicker) {
            AppUnlockDurationPickerView(
                app: app,
                currentPoints: currentPoints,
                onUnlock: onUnlock
            )
        }
    }
}

struct DurationOptionButton: View {
    let duration: Int
    let cost: Int
    let canAfford: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(duration) min")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(cost) pts")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(canAfford ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canAfford ? Color.blue : Color.gray, lineWidth: 1)
            )
        }
        .disabled(!canAfford)
        .buttonStyle(.plain)
    }
}

struct AppUnlockDurationPickerView: View {
    let app: EntertainmentAppConfig
    let currentPoints: Int
    let onUnlock: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDuration = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // App Info
                VStack(spacing: 16) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Unlock \(app.displayName)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose how long you want to unlock this app")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Duration Options
                VStack(spacing: 16) {
                    DurationPickerRow(
                        duration: 15,
                        cost: app.pointsCost(for: 15),
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 15,
                        onSelect: { selectedDuration = 15 }
                    )

                    DurationPickerRow(
                        duration: 30,
                        cost: app.pointsCostPer30Min,
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 30,
                        onSelect: { selectedDuration = 30 }
                    )

                    DurationPickerRow(
                        duration: 60,
                        cost: app.pointsCostPer60Min,
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 60,
                        onSelect: { selectedDuration = 60 }
                    )

                    DurationPickerRow(
                        duration: 120,
                        cost: app.pointsCost(for: 120),
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 120,
                        onSelect: { selectedDuration = 120 }
                    )
                }

                Spacer()

                // Unlock Button
                Button("Unlock for \(selectedDuration) minutes") {
                    onUnlock(selectedDuration)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(currentPoints < app.pointsCost(for: selectedDuration))
            }
            .padding()
            .navigationTitle("Unlock Duration")
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
}

struct DurationPickerRow: View {
    let duration: Int
    let cost: Int
    let currentPoints: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var canAfford: Bool {
        currentPoints >= cost
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(duration) minutes")
                        .font(.headline)
                        .fontWeight(.medium)

                    if canAfford {
                        Text("You have enough points")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Need \(cost - currentPoints) more points")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(cost) points")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!canAfford)
        .buttonStyle(.plain)
    }
}

// MARK: - Reward Redemption Models
struct RedeemedReward: Identifiable {
    let id: UUID
    let name: String
    let cost: Int
    let redeemedAt: Date
    var status: RedemptionStatus
}

enum RedemptionStatus {
    case pending, approved, denied

    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .denied: return .red
        }
    }

    var text: String {
        switch self {
        case .pending: return "Pending Approval"
        case .approved: return "Approved"
        case .denied: return "Denied"
        }
    }
}

struct RecentRedemptionRow: View {
    let reward: RedeemedReward

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(reward.redeemedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("-\(reward.cost) pts")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)

                Text(reward.status.text)
                    .font(.caption)
                    .foregroundColor(reward.status.color)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ChildProfileView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingProfileSwitcher = false

    var body: some View {
        NavigationStack {
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
    @State private var showingAppCategories = false
    @State private var showingTimeLimits = false
    @State private var showingReports = false
    @StateObject private var familyMemberService = FamilyMemberService()

    // Mock data for children progress - replace with real data later
    let mockChildrenData = [
        ("Alex", 125, 85, 3),
        ("Sam", 95, 60, 1)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Family Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Family Overview")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            let children = familyMemberService.familyMembers.filter { $0.isChild }
                            OverviewStatCard(title: "Children", value: "\(children.count)", icon: "person.2.fill", color: .blue)
                            OverviewStatCard(title: "Total Points", value: "\(mockChildrenData.reduce(0) { $0 + $1.1 })", icon: "star.fill", color: .yellow)
                            OverviewStatCard(title: "Active Today", value: "\(mockChildrenData.filter { $0.3 > 0 }.count)", icon: "checkmark.circle.fill", color: .green)
                        }
                    }

                    // Children Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Children's Progress")
                            .font(.title2)
                            .fontWeight(.bold)

                        let children = familyMemberService.familyMembers.filter { $0.isChild }
                        if children.isEmpty {
                            // Empty state when no children found
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.slash.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)

                                Text("No children found in Family Sharing")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                NavigationLink(destination: FamilySetupView()) {
                                    Text("Set up Family Sharing")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        } else {
                            // Show children progress using mock data for now
                            ForEach(Array(mockChildrenData.enumerated()), id: \.offset) { index, child in
                                ChildProgressCard(
                                    name: child.0,
                                    points: child.1,
                                    learningMinutes: child.2,
                                    streak: child.3
                                )
                            }
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
                            NavigationLink(destination: FamilySetupView()) {
                                QuickActionCard(title: "Family Setup", icon: "house.circle.fill", action: {})
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: AppCategorizationView()) {
                                QuickActionCard(title: "App Categories", icon: "apps.iphone", action: {})
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ChildSelectionView(
                                onChildSelected: { _ in },
                                destinationType: .timeLimits
                            )) {
                                QuickActionCard(title: "Time Limits", icon: "clock.fill", action: {})
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ChildSelectionView(
                                onChildSelected: { _ in },
                                destinationType: .reports
                            )) {
                                QuickActionCard(title: "Reports", icon: "chart.bar.fill", action: {})
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Family Dashboard")
            .refreshable {
                loadFamilyMembers()
            }
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
        NavigationStack {
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
    @State private var selectedChild: FamilyMemberInfo?
    @StateObject private var familyMemberService = FamilyMemberService()

    var body: some View {
        NavigationStack {
            List {
                // General App Settings
                Section("General Settings") {
                    NavigationLink(destination: FamilySetupView()) {
                        Label("Family Setup", systemImage: "house.fill")
                    }

                    NavigationLink(destination: FamilyControlsSetupView()) {
                        Label("Family Controls", systemImage: "shield.fill")
                    }

                    NavigationLink(destination: FamilyMembersView()) {
                        Label("Family Members", systemImage: "person.2.fill")
                    }

                    NavigationLink(destination: AppCategorizationView()) {
                        Label("App Categories", systemImage: "apps.iphone")
                    }

                    NavigationLink(destination: SubscriptionView()) {
                        Label("Subscription", systemImage: "star.fill")
                    }
                }

                // Child-Related Settings
                if !familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    Section("Child Settings") {
                        NavigationLink(destination: LearningAppRewardsView()) {
                            Label("Learning App Points", systemImage: "graduationcap.fill")
                        }

                        NavigationLink(destination: RewardCostConfigurationView()) {
                            Label("Reward Costs", systemImage: "gift.fill")
                        }

                        NavigationLink(destination: EntertainmentAppCostConfigurationView()) {
                            Label("Reward App Costs", systemImage: "iphone")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .timeLimits
                        )) {
                            Label("Daily Time Limits", systemImage: "clock.fill")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .bedtime
                        )) {
                            Label("Bedtime Settings", systemImage: "moon.fill")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .reports
                        )) {
                            Label("Detailed Reports", systemImage: "chart.bar.fill")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .trends
                        )) {
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

// MARK: - Child Selection View
struct ChildSelectionView: View {
    let onChildSelected: (FamilyMemberInfo) -> Void
    let destinationType: ChildSettingDestination
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?

    enum ChildSettingDestination {
        case timeLimits, bedtime, reports, trends

        var title: String {
            switch self {
            case .timeLimits: return "Daily Time Limits"
            case .bedtime: return "Bedtime Settings"
            case .reports: return "Detailed Reports"
            case .trends: return "Usage Trends"
            }
        }

        var description: String {
            switch self {
            case .timeLimits: return "Set daily screen time limits for your child"
            case .bedtime: return "Configure bedtime schedules and restrictions"
            case .reports: return "View detailed screen time and learning reports"
            case .trends: return "Analyze usage patterns and trends over time"
            }
        }

        func destinationView(for child: FamilyMemberInfo) -> some View {
            switch self {
            case .timeLimits:
                return AnyView(TimeLimitsView())
            case .bedtime:
                return AnyView(BedtimeSettingsView())
            case .reports:
                return AnyView(ReportsView())
            case .trends:
                return AnyView(UsageTrendsView())
            }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Select Child")
                    .font(.title)
                    .fontWeight(.bold)

                Text(destinationType.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Children List
            if familyMemberService.isLoading {
                ProgressView("Loading family members...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let children = familyMemberService.familyMembers.filter { $0.isChild }

                if children.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text("No Children Found")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("Set up Family Sharing to add children to your family group.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        NavigationLink(destination: FamilySetupView()) {
                            Text("Family Setup Guide")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(children, id: \.id) { child in
                                NavigationLink(destination: destinationType.destinationView(for: child)) {
                                    ChildSelectionCard(child: child)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }

            Spacer()
        }
        .navigationTitle(destinationType.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFamilyMembers()
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

struct ChildSelectionCard: View {
    let child: FamilyMemberInfo

    var body: some View {
        HStack(spacing: 16) {
            // Child Avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            // Child Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if child.hasAppInstalled {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("App Installed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("App needed on child's device")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Entertainment App Cost Configuration
struct EntertainmentAppCostConfigurationView: View {
    @StateObject private var appDiscoveryService = AppDiscoveryService()
    @State private var apps: [AppMetadata] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var entertainmentAppCosts: [String: EntertainmentAppConfig] = [:]

    var body: some View {
        VStack {
            if appDiscoveryService.authorizationStatus != .approved {
                // Family Controls Required State
                VStack(spacing: 16) {
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text("Family Controls Required")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Please enable Family Controls first to configure entertainment app costs.")
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
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "iphone.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)

                            Text("Reward App Costs")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Configure how many points it costs to unlock entertainment apps")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Quick Setup Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Setup")
                                .font(.title2)
                                .fontWeight(.bold)

                            VStack(spacing: 12) {
                                QuickSetupCard(
                                    title: "Popular Entertainment Apps",
                                    subtitle: "Apply preset costs to common apps like TikTok, Instagram",
                                    icon: "star.fill",
                                    action: {
                                        applyPresetCosts()
                                    }
                                )

                                QuickSetupCard(
                                    title: "Scan Device Apps",
                                    subtitle: "Find and configure all installed entertainment apps",
                                    icon: "magnifyingglass",
                                    action: {
                                        loadApps()
                                    }
                                )
                            }
                        }

                        // Entertainment Apps Configuration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Entertainment Apps")
                                .font(.title2)
                                .fontWeight(.bold)

                            if isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Loading apps...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else {
                                // Default entertainment apps list
                                VStack(spacing: 12) {
                                    ForEach(Array(getDefaultEntertainmentApps().keys.sorted()), id: \.self) { bundleID in
                                        if let config = entertainmentAppCosts[bundleID] ?? getDefaultEntertainmentApps()[bundleID] {
                                            EntertainmentAppCostRow(
                                                config: config,
                                                onUpdate: { updatedConfig in
                                                    entertainmentAppCosts[bundleID] = updatedConfig
                                                    saveConfiguration(updatedConfig)
                                                }
                                            )
                                        }
                                    }
                                }

                                // Show discovered apps if available
                                if !apps.isEmpty {
                                    Text("Discovered Apps")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .padding(.top)

                                    VStack(spacing: 12) {
                                        ForEach(apps.filter { !getDefaultEntertainmentApps().keys.contains($0.bundleID) }, id: \.id) { app in
                                            let config = entertainmentAppCosts[app.bundleID] ?? EntertainmentAppConfig(
                                                bundleID: app.bundleID,
                                                displayName: app.displayName,
                                                pointsCostPer30Min: 30,
                                                pointsCostPer60Min: 50,
                                                isEnabled: true,
                                                parentConfiguredAt: Date()
                                            )

                                            EntertainmentAppCostRow(
                                                config: config,
                                                onUpdate: { updatedConfig in
                                                    entertainmentAppCosts[app.bundleID] = updatedConfig
                                                    saveConfiguration(updatedConfig)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Reward App Costs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSavedConfigurations()
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

    private func getDefaultEntertainmentApps() -> [String: EntertainmentAppConfig] {
        return [
            "com.zhiliaoapp.musically": EntertainmentAppConfig(
                bundleID: "com.zhiliaoapp.musically",
                displayName: "TikTok",
                pointsCostPer30Min: 30,
                pointsCostPer60Min: 50,
                isEnabled: true,
                parentConfiguredAt: Date()
            ),
            "com.instagram.instagram": EntertainmentAppConfig(
                bundleID: "com.instagram.instagram",
                displayName: "Instagram",
                pointsCostPer30Min: 25,
                pointsCostPer60Min: 45,
                isEnabled: true,
                parentConfiguredAt: Date()
            ),
            "com.snapchat.snapchat": EntertainmentAppConfig(
                bundleID: "com.snapchat.snapchat",
                displayName: "Snapchat",
                pointsCostPer30Min: 25,
                pointsCostPer60Min: 45,
                isEnabled: true,
                parentConfiguredAt: Date()
            ),
            "com.youtube.youtube": EntertainmentAppConfig(
                bundleID: "com.youtube.youtube",
                displayName: "YouTube",
                pointsCostPer30Min: 20,
                pointsCostPer60Min: 35,
                isEnabled: true,
                parentConfiguredAt: Date()
            ),
            "com.spotify.client": EntertainmentAppConfig(
                bundleID: "com.spotify.client",
                displayName: "Spotify",
                pointsCostPer30Min: 15,
                pointsCostPer60Min: 25,
                isEnabled: true,
                parentConfiguredAt: Date()
            ),
            "com.netflix.Netflix": EntertainmentAppConfig(
                bundleID: "com.netflix.Netflix",
                displayName: "Netflix",
                pointsCostPer30Min: 40,
                pointsCostPer60Min: 70,
                isEnabled: true,
                parentConfiguredAt: Date()
            ),
            "com.roblox.robloxmobile": EntertainmentAppConfig(
                bundleID: "com.roblox.robloxmobile",
                displayName: "Roblox",
                pointsCostPer30Min: 35,
                pointsCostPer60Min: 60,
                isEnabled: true,
                parentConfiguredAt: Date()
            ),
            "com.miHoYo.GenshinImpact": EntertainmentAppConfig(
                bundleID: "com.miHoYo.GenshinImpact",
                displayName: "Genshin Impact",
                pointsCostPer30Min: 45,
                pointsCostPer60Min: 80,
                isEnabled: true,
                parentConfiguredAt: Date()
            )
        ]
    }

    private func loadApps() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedApps = try await appDiscoveryService.fetchInstalledApps()
                await MainActor.run {
                    apps = loadedApps.filter { !isEducationalApp($0) }
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
            "com.codecademy.CodecademyiOS",
            "com.brilliant.Brilliant"
        ]
        return educationalBundleIDs.contains(app.bundleID) ||
               app.displayName.lowercased().contains("learn") ||
               app.displayName.lowercased().contains("education") ||
               app.displayName.lowercased().contains("math") ||
               app.displayName.lowercased().contains("science")
    }

    private func applyPresetCosts() {
        entertainmentAppCosts = getDefaultEntertainmentApps()
        for config in entertainmentAppCosts.values {
            saveConfiguration(config)
        }
    }

    private func loadSavedConfigurations() {
        let defaults = UserDefaults.standard
        for bundleID in getDefaultEntertainmentApps().keys {
            if let data = defaults.data(forKey: "entertainment_app_\(bundleID)"),
               let saved = try? JSONDecoder().decode(EntertainmentAppConfig.self, from: data) {
                entertainmentAppCosts[bundleID] = saved
            }
        }
    }

    private func saveConfiguration(_ config: EntertainmentAppConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "entertainment_app_\(config.bundleID)")
        }
    }
}

struct EntertainmentAppCostRow: View {
    let config: EntertainmentAppConfig
    let onUpdate: (EntertainmentAppConfig) -> Void
    @State private var cost30Min: Int
    @State private var cost60Min: Int
    @State private var isEnabled: Bool
    @State private var showingDetail = false

    init(config: EntertainmentAppConfig, onUpdate: @escaping (EntertainmentAppConfig) -> Void) {
        self.config = config
        self.onUpdate = onUpdate
        self._cost30Min = State(initialValue: config.pointsCostPer30Min)
        self._cost60Min = State(initialValue: config.pointsCostPer60Min)
        self._isEnabled = State(initialValue: config.isEnabled)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.displayName)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(config.bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Text("30min: \(cost30Min)pts")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text("60min: \(cost60Min)pts")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .onChange(of: isEnabled) { _ in
                        updateConfiguration()
                    }

                Button("Configure") {
                    showingDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .disabled(!isEnabled)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
        .sheet(isPresented: $showingDetail) {
            EntertainmentAppCostConfigView(
                appName: config.displayName,
                bundleID: config.bundleID,
                cost30Min: $cost30Min,
                cost60Min: $cost60Min
            )
            .onDisappear {
                updateConfiguration()
            }
        }
    }

    private func updateConfiguration() {
        let updatedConfig = EntertainmentAppConfig(
            bundleID: config.bundleID,
            displayName: config.displayName,
            pointsCostPer30Min: cost30Min,
            pointsCostPer60Min: cost60Min,
            isEnabled: isEnabled,
            parentConfiguredAt: Date()
        )
        onUpdate(updatedConfig)
    }
}

// MARK: - Learning App Rewards Configuration
struct LearningAppRewardsView: View {
    @StateObject private var appDiscoveryService = AppDiscoveryService()
    @State private var apps: [AppMetadata] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pointsPerMinute: [String: Int] = [
        "com.khanacademy.iphone": 2,
        "com.duolingo.DuolingoMobile": 3,
        "com.brilliant.Brilliant": 4,
        "com.codecademy.CodecademyiOS": 3,
        "com.mathway.mathway": 2
    ]

    var body: some View {
        VStack {
            if appDiscoveryService.authorizationStatus != .approved {
                // Family Controls Required State
                VStack(spacing: 16) {
                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text("Family Controls Required")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Please enable Family Controls first to configure learning app rewards.")
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
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "graduationcap.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text("Learning App Points")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Configure how many points children earn per minute of using educational apps")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Quick Setup Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Setup")
                                .font(.title2)
                                .fontWeight(.bold)

                            VStack(spacing: 12) {
                                QuickSetupCard(
                                    title: "Popular Learning Apps",
                                    subtitle: "Apply preset values to common educational apps",
                                    icon: "star.fill",
                                    action: {
                                        applyPresetValues()
                                    }
                                )

                                QuickSetupCard(
                                    title: "Scan Device Apps",
                                    subtitle: "Find and configure all installed learning apps",
                                    icon: "magnifyingglass",
                                    action: {
                                        loadApps()
                                    }
                                )
                            }
                        }

                        // Educational Apps Configuration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Educational Apps")
                                .font(.title2)
                                .fontWeight(.bold)

                            if isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Loading apps...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else if apps.isEmpty {
                                // Default apps list when no apps loaded
                                VStack(spacing: 12) {
                                    ForEach(Array(pointsPerMinute.keys), id: \.self) { bundleID in
                                        LearningAppConfigRow(
                                            appName: getAppDisplayName(bundleID: bundleID),
                                            bundleID: bundleID,
                                            pointsPerMinute: Binding(
                                                get: { pointsPerMinute[bundleID] ?? 1 },
                                                set: { pointsPerMinute[bundleID] = $0 }
                                            )
                                        )
                                    }
                                }
                            } else {
                                // Loaded apps list
                                VStack(spacing: 12) {
                                    ForEach(apps.filter { isEducationalApp($0) }, id: \.id) { app in
                                        LearningAppConfigRow(
                                            appName: app.displayName,
                                            bundleID: app.bundleID,
                                            pointsPerMinute: Binding(
                                                get: { pointsPerMinute[app.bundleID] ?? 1 },
                                                set: { pointsPerMinute[app.bundleID] = $0 }
                                            )
                                        )
                                    }
                                }
                            }
                        }

                        // Custom App Addition
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Add Custom App")
                                .font(.title2)
                                .fontWeight(.bold)

                            CustomAppAdditionView { bundleID, pointValue in
                                pointsPerMinute[bundleID] = pointValue
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Learning App Points")
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
        let educationalBundleIDs = Array(pointsPerMinute.keys) + [
            "com.apple.classroom",
            "com.apple.swift.playgrounds",
            "com.scratchfoundation.scratchjr"
        ]
        return educationalBundleIDs.contains(app.bundleID) ||
               app.displayName.lowercased().contains("learn") ||
               app.displayName.lowercased().contains("education") ||
               app.displayName.lowercased().contains("math") ||
               app.displayName.lowercased().contains("science")
    }

    private func getAppDisplayName(bundleID: String) -> String {
        switch bundleID {
        case "com.khanacademy.iphone":
            return "Khan Academy"
        case "com.duolingo.DuolingoMobile":
            return "Duolingo"
        case "com.brilliant.Brilliant":
            return "Brilliant"
        case "com.codecademy.CodecademyiOS":
            return "Codecademy"
        case "com.mathway.mathway":
            return "Mathway"
        default:
            return bundleID.components(separatedBy: ".").last?.capitalized ?? bundleID
        }
    }

    private func applyPresetValues() {
        pointsPerMinute = [
            "com.khanacademy.iphone": 3,
            "com.duolingo.DuolingoMobile": 4,
            "com.brilliant.Brilliant": 5,
            "com.codecademy.CodecademyiOS": 4,
            "com.mathway.mathway": 2,
            "com.apple.swift.playgrounds": 5,
            "com.scratchfoundation.scratchjr": 3
        ]
    }
}

struct QuickSetupCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.subheadline)
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
}

struct LearningAppConfigRow: View {
    let appName: String
    let bundleID: String
    @Binding var pointsPerMinute: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Text("\(pointsPerMinute) pts/min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)

                Stepper("", value: $pointsPerMinute, in: 1...10)
                    .labelsHidden()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct CustomAppAdditionView: View {
    @State private var bundleID = ""
    @State private var pointsPerMinute = 2
    @State private var showingAlert = false
    let onAddApp: (String, Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("App Bundle ID (e.g., com.company.app)", text: $bundleID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                HStack {
                    Text("\(pointsPerMinute) pts")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Stepper("", value: $pointsPerMinute, in: 1...10)
                        .labelsHidden()
                }
            }

            Button("Add Learning App") {
                if !bundleID.isEmpty && bundleID.contains(".") {
                    onAddApp(bundleID, pointsPerMinute)
                    bundleID = ""
                    pointsPerMinute = 2
                    showingAlert = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(bundleID.isEmpty || !bundleID.contains("."))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .alert("App Added", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text("The learning app has been added to your configuration.")
        }
    }
}

// MARK: - Reward Cost Configuration
struct RewardCostConfigurationView: View {
    @State private var rewardCosts: [String: Int] = [
        "Extra Screen Time": 50,
        "Movie Night": 100,
        "Late Bedtime": 75,
        "Ice Cream Treat": 25,
        "Special Toy": 200,
        "Friend Playdate": 150,
        "Choose Dinner": 80,
        "Stay Up Late": 120
    ]
    @State private var showingAddReward = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "gift.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("Reward Costs")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Set how many points each reward costs to redeem")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Setup")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        Button("Reset to Defaults") {
                            resetToDefaults()
                        }
                        .buttonStyle(.bordered)

                        Button("Add Custom Reward") {
                            showingAddReward = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // Rewards List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Rewards")
                        .font(.title2)
                        .fontWeight(.bold)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(rewardCosts.keys.sorted()), id: \.self) { rewardName in
                            RewardCostConfigRow(
                                rewardName: rewardName,
                                cost: Binding(
                                    get: { rewardCosts[rewardName] ?? 50 },
                                    set: { rewardCosts[rewardName] = $0 }
                                ),
                                onDelete: {
                                    rewardCosts.removeValue(forKey: rewardName)
                                }
                            )
                        }
                    }
                }

                // Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reward Guidelines")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        RewardGuidelineRow(
                            icon: "clock.fill",
                            text: "Small rewards (15-30 min activities): 25-75 points",
                            color: .green
                        )
                        RewardGuidelineRow(
                            icon: "star.fill",
                            text: "Medium rewards (1-2 hour activities): 100-150 points",
                            color: .orange
                        )
                        RewardGuidelineRow(
                            icon: "gift.fill",
                            text: "Large rewards (special treats/toys): 200+ points",
                            color: .red
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .padding()
        }
        .navigationTitle("Reward Costs")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddReward) {
            AddCustomRewardView { rewardName, cost in
                rewardCosts[rewardName] = cost
            }
        }
    }

    private func resetToDefaults() {
        rewardCosts = [
            "Extra Screen Time": 50,
            "Movie Night": 100,
            "Late Bedtime": 75,
            "Ice Cream Treat": 25,
            "Special Toy": 200,
            "Friend Playdate": 150,
            "Choose Dinner": 80,
            "Stay Up Late": 120
        ]
    }
}

struct RewardCostConfigRow: View {
    let rewardName: String
    @Binding var cost: Int
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rewardName)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(getCostDescription(cost: cost))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Text("\(cost) pts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Stepper("", value: $cost, in: 10...500, step: 5)
                    .labelsHidden()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    private func getCostDescription(cost: Int) -> String {
        switch cost {
        case 0..<50:
            return "Low cost reward"
        case 50..<100:
            return "Medium cost reward"
        case 100..<200:
            return "High cost reward"
        default:
            return "Premium reward"
        }
    }
}

struct RewardGuidelineRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

struct AddCustomRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rewardName = ""
    @State private var cost = 50
    let onAddReward: (String, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Reward Name", text: $rewardName)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cost: \(cost) points")
                        Slider(value: Binding(
                            get: { Double(cost) },
                            set: { cost = Int($0) }
                        ), in: 10...500, step: 5)
                    }
                }

                Section("Examples") {
                    Text("• Extra playtime")
                    Text("• Choose weekend activity")
                    Text("• Special dessert")
                    Text("• New book or toy")
                }
                .foregroundColor(.secondary)
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
                        onAddReward(rewardName, cost)
                        dismiss()
                    }
                    .disabled(rewardName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Onboarding
struct OnboardingView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        NavigationStack {
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
    @StateObject private var authService = ParentAuthorizationService()
    @State private var showingAuthError = false
    @State private var isAuthenticating = false

    var body: some View {
        NavigationStack {
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
                        switchToParentProfile()
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
        .alert("Authentication Error", isPresented: $showingAuthError) {
            Button("OK") {
                showingAuthError = false
            }
            if authService.authenticationError == .biometricNotEnrolled ||
               authService.authenticationError == .passcodeNotSet {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
        } message: {
            Text(authService.authenticationError?.errorDescription ?? "Unknown authentication error")
        }
    }

    private func switchToParentProfile() {
        // If already parent, just dismiss
        if userRole == "parent" {
            dismiss()
            return
        }

        // Require authentication to switch to parent profile
        isAuthenticating = true

        Task {
            do {
                try await authService.requestAuthentication()
                await MainActor.run {
                    userRole = "parent"
                    isAuthenticating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    showingAuthError = true
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
                                EducationalAppRow(app: app)
                            }
                        }

                        Section("Entertainment Apps") {
                            ForEach(apps.filter { !isEducationalApp($0) }, id: \.id) { app in
                                EntertainmentAppRow(app: app)
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

// MARK: - App Category Rows
struct EducationalAppRow: View {
    let app: AppMetadata
    @State private var pointsPerMinute: Int = 2

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(app.bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("Always Accessible", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(pointsPerMinute)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("pts/min")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Stepper("", value: $pointsPerMinute, in: 1...10)
                    .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
}

struct EntertainmentAppRow: View {
    let app: AppMetadata
    @State private var cost30Min: Int = 25
    @State private var cost60Min: Int = 45
    @State private var isEnabled: Bool = true
    @State private var showingCostConfig = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(app.bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("Blocked by Default", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()

                if isEnabled {
                    Button("Configure Cost") {
                        showingCostConfig = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                } else {
                    Text("Disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(isEnabled ? 1.0 : 0.6)
        .sheet(isPresented: $showingCostConfig) {
            EntertainmentAppCostConfigView(
                appName: app.displayName,
                bundleID: app.bundleID,
                cost30Min: $cost30Min,
                cost60Min: $cost60Min
            )
        }
    }
}

struct EntertainmentAppCostConfigView: View {
    let appName: String
    let bundleID: String
    @Binding var cost30Min: Int
    @Binding var cost60Min: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appName)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text(bundleID)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Unlock Costs") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("30 Minutes", systemImage: "clock")
                                .foregroundColor(.blue)
                            Spacer()
                            Text("\(cost30Min) points")
                                .fontWeight(.semibold)
                        }
                        Slider(value: Binding(
                            get: { Double(cost30Min) },
                            set: { cost30Min = Int($0) }
                        ), in: 10...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("60 Minutes", systemImage: "clock")
                                .foregroundColor(.blue)
                            Spacer()
                            Text("\(cost60Min) points")
                                .fontWeight(.semibold)
                        }
                        Slider(value: Binding(
                            get: { Double(cost60Min) },
                            set: { cost60Min = Int($0) }
                        ), in: 20...200, step: 5)
                    }
                }

                Section("Preview") {
                    VStack(spacing: 8) {
                        CostPreviewRow(duration: "15 min", cost: cost30Min / 2)
                        CostPreviewRow(duration: "30 min", cost: cost30Min)
                        CostPreviewRow(duration: "60 min", cost: cost60Min)
                        CostPreviewRow(duration: "90 min", cost: Int(Double(cost60Min) * 1.5))
                    }
                }

                Section("Guidelines") {
                    VStack(alignment: .leading, spacing: 8) {
                        GuidelineRow(
                            icon: "star.fill",
                            text: "Low cost: 10-30 points for 30min",
                            color: .green
                        )
                        GuidelineRow(
                            icon: "star.fill",
                            text: "Medium cost: 31-60 points for 30min",
                            color: .orange
                        )
                        GuidelineRow(
                            icon: "star.fill",
                            text: "High cost: 61+ points for 30min",
                            color: .red
                        )
                    }
                }
            }
            .navigationTitle("App Cost Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save the configuration
                        saveConfiguration()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveConfiguration() {
        // In a real app, this would save to UserDefaults or CloudKit
        let config = EntertainmentAppConfig(
            bundleID: bundleID,
            displayName: appName,
            pointsCostPer30Min: cost30Min,
            pointsCostPer60Min: cost60Min,
            isEnabled: true,
            parentConfiguredAt: Date()
        )

        // Save to UserDefaults for now
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "entertainment_app_\(bundleID)")
        }
    }
}

struct CostPreviewRow: View {
    let duration: String
    let cost: Int

    var body: some View {
        HStack {
            Text(duration)
                .font(.subheadline)
            Spacer()
            Text("\(cost) pts")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
}

struct GuidelineRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()
        }
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

// MARK: - Family Setup & Management
struct FamilySetupView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "house.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Family Setup")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Set up your family to use Screen Time Rewards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Setup Steps
                VStack(alignment: .leading, spacing: 20) {
                    Text("Setup Steps")
                        .font(.headline)
                        .fontWeight(.semibold)

                    SetupStepCard(
                        number: "1",
                        title: "Enable Family Sharing",
                        description: "Go to Settings > [Your Name] > Family Sharing and set up your family group",
                        icon: "person.2.fill",
                        isCompleted: false
                    )

                    SetupStepCard(
                        number: "2",
                        title: "Add Family Members",
                        description: "Invite family members to join your Family Sharing group",
                        icon: "person.badge.plus.fill",
                        isCompleted: false
                    )

                    SetupStepCard(
                        number: "3",
                        title: "Set Up Screen Time",
                        description: "Enable Screen Time for family members in Settings > Screen Time",
                        icon: "clock.fill",
                        isCompleted: false
                    )

                    SetupStepCard(
                        number: "4",
                        title: "Enable Family Controls",
                        description: "Return to this app and enable Family Controls in Settings",
                        icon: "shield.fill",
                        isCompleted: false
                    )
                }

                // Help Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Need Help?")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        HelpRow(
                            icon: "questionmark.circle.fill",
                            text: "Family Sharing allows you to share apps, subscriptions, and manage Screen Time"
                        )
                        HelpRow(
                            icon: "info.circle.fill",
                            text: "Children under 13 are automatically added to Family Sharing"
                        )
                        HelpRow(
                            icon: "exclamationmark.triangle.fill",
                            text: "Both parents and children need to use this app for the reward system to work"
                        )
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Family Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FamilyMembersView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if familyMemberService.isLoading {
                ProgressView("Loading family members...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if familyMemberService.familyMembers.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "person.2.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("No Family Members Found")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("To see family members here, you need to:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 8) {
                        ChecklistItem(text: "Set up Family Sharing in iOS Settings")
                        ChecklistItem(text: "Add family members to your group")
                        ChecklistItem(text: "Enable Screen Time for family members")
                        ChecklistItem(text: "Install this app on family devices")
                    }

                    NavigationLink(destination: FamilySetupView()) {
                        Text("Family Setup Guide")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                // Family Members List
                List {
                    ForEach(familyMemberService.familyMembers, id: \.id) { member in
                        RealFamilyMemberRow(member: member)
                    }
                }
                .refreshable {
                    loadFamilyMembers()
                }
            }
        }
        .navigationTitle("Family Members")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFamilyMembers()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct SetupStepCard: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Step Number
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.blue)
                    .frame(width: 40, height: 40)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.title3)
                } else {
                    Text(number)
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isCompleted ? .green : .blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct HelpRow: View {
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

struct ChecklistItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack {
            Image(systemName: member.isChild ? "person.fill" : "person.2.fill")
                .foregroundColor(member.isChild ? .blue : .green)
                .font(.title2)

            VStack(alignment: .leading) {
                Text(member.name)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(member.isChild ? "Child" : "Parent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if member.hasAppInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RealFamilyMemberRow: View {
    let member: FamilyMemberInfo

    var body: some View {
        HStack {
            Image(systemName: member.isChild ? "person.fill" : "person.2.fill")
                .foregroundColor(member.isChild ? .blue : .green)
                .font(.title2)

            VStack(alignment: .leading) {
                HStack {
                    Text(member.name)
                        .font(.headline)
                        .fontWeight(.medium)

                    if member.isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }

                Text(member.isChild ? "Child" : "Parent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if member.hasAppInstalled {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("App Installed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("App Needed")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Subscription View
@available(iOS 15.0, *)
struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var isLoading = false
    @State private var purchaseError: Error?
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var selectedProduct: SubscriptionProduct?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)

                    Text("Screen Time Rewards Premium")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Unlock advanced family controls and unlimited reward tracking")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Features
                VStack(spacing: 20) {
                    Text("Premium Features")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 16) {
                        FeatureRow(icon: "person.2.fill", title: "Multiple Children", description: "Manage up to 2 children with separate profiles and rewards")
                        FeatureRow(icon: "chart.bar.fill", title: "Advanced Analytics", description: "Detailed insights into screen time patterns and productivity")
                        FeatureRow(icon: "bell.fill", title: "Smart Notifications", description: "Customizable alerts for screen time goals and achievements")
                        FeatureRow(icon: "icloud.fill", title: "Cloud Sync", description: "Keep your family data synced across all devices")
                        FeatureRow(icon: "lock.shield.fill", title: "Enhanced Security", description: "Advanced parental controls and privacy protection")
                    }
                }
                .padding(.horizontal)

                // Subscription Plans
                if subscriptionService.isLoading {
                    ProgressView("Loading subscription plans...")
                        .frame(height: 200)
                } else if subscriptionService.availableProducts.isEmpty {
                    VStack(spacing: 16) {
                        Text("Unable to load subscription plans")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Button("Retry") {
                            Task {
                                await subscriptionService.fetchProducts()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(height: 200)
                } else {
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.title2)
                            .fontWeight(.semibold)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(subscriptionService.availableProducts) { product in
                                SubscriptionCard(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onSelect: {
                                        selectedProduct = product
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)

                        if let selectedProduct = selectedProduct {
                            Button(action: {
                                purchaseProduct(selectedProduct)
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Subscribe for \(selectedProduct.priceFormatted)")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                            .padding(.horizontal)
                        }
                    }
                }

                // Footer
                VStack(spacing: 12) {
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .foregroundColor(.blue)

                    Text("Cancel anytime from App Store settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscriptionService.fetchProducts()
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(purchaseError?.localizedDescription ?? "Unknown error occurred")
        }
        .alert("Purchase Successful", isPresented: $showingSuccess) {
            Button("OK") {
                showingSuccess = false
            }
        } message: {
            Text("Thank you for subscribing to Screen Time Rewards Premium!")
        }
    }

    private func purchaseProduct(_ product: SubscriptionProduct) {
        isLoading = true

        Task {
            do {
                _ = try await subscriptionService.purchase(product.id)

                await MainActor.run {
                    isLoading = false
                    // For now, just show success for any non-error result
                    // The purchase was successful if we reach here without throwing
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    purchaseError = error
                    showingError = true
                }
            }
        }
    }

    private func restorePurchases() {
        isLoading = true

        Task {
            do {
                try await subscriptionService.restorePurchases()
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    purchaseError = error
                    showingError = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct SubscriptionCard: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Text(planTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(product.priceFormatted)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text(billingPeriod)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if isPopular {
                    Text("MOST POPULAR")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var planTitle: String {
        if product.id.contains("1child") {
            return "1 Child"
        } else if product.id.contains("2child") {
            return "2 Children"
        } else {
            return product.displayName
        }
    }

    private var billingPeriod: String {
        switch product.subscriptionPeriod.unit {
        case .month:
            return "/month"
        case .year:
            return "/year"
        default:
            return "/\(product.subscriptionPeriod.displayName.lowercased())"
        }
    }

    private var isPopular: Bool {
        // Mark yearly plans as most popular
        return product.subscriptionPeriod.unit == .year
    }
}

// MARK: - Quick Action Views
struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var childName = ""
    @State private var childAge = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Child Information") {
                    TextField("Child's Name", text: $childName)
                    TextField("Age", text: $childAge)
                        .keyboardType(.numberPad)
                }

                Section("Setup") {
                    HStack {
                        Image(systemName: "iphone")
                        Text("Child's Device Setup")
                        Spacer()
                        Text("Required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                        Text("Family Sharing")
                        Spacer()
                        Text("Recommended")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Permissions") {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text("Screen Time Permission")
                        Spacer()
                        Text("Required")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save child logic
                        dismiss()
                    }
                    .disabled(childName.isEmpty)
                }
            }
        }
    }
}

struct TimeLimitsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weekdayLimit = 2.0 // hours
    @State private var weekendLimit = 4.0 // hours
    @State private var bedtimeEnabled = true
    @State private var bedtimeStart = Date()
    @State private var bedtimeEnd = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Time Limits") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weekdays: \(Int(weekdayLimit)) hours")
                        Slider(value: $weekdayLimit, in: 0...8, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weekends: \(Int(weekendLimit)) hours")
                        Slider(value: $weekendLimit, in: 0...12, step: 0.5)
                    }
                }

                Section("Bedtime") {
                    Toggle("Enable Bedtime Restrictions", isOn: $bedtimeEnabled)

                    if bedtimeEnabled {
                        DatePicker("Start Time", selection: $bedtimeStart, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $bedtimeEnd, displayedComponents: .hourAndMinute)
                    }
                }

                Section("App Categories") {
                    HStack {
                        Text("Educational Apps")
                        Spacer()
                        Text("Unlimited")
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Entertainment Apps")
                        Spacer()
                        Text("Limited")
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Social Media")
                        Spacer()
                        Text("Restricted")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Time Limits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save settings logic
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReportsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This Week's Summary")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 12) {
                            ReportStatCard(title: "Total Screen Time", value: "18h 32m", change: "-12%", isPositive: false)
                            ReportStatCard(title: "Educational Time", value: "6h 45m", change: "+23%", isPositive: true)
                            ReportStatCard(title: "Reward Points Earned", value: "145", change: "+8%", isPositive: true)
                        }
                    }

                    // Daily Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Breakdown")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 8) {
                            DailyReportRow(day: "Today", screenTime: "2h 15m", educational: "45m", points: 25)
                            DailyReportRow(day: "Yesterday", screenTime: "3h 22m", educational: "1h 12m", points: 35)
                            DailyReportRow(day: "Monday", screenTime: "2h 45m", educational: "52m", points: 28)
                            DailyReportRow(day: "Sunday", screenTime: "4h 18m", educational: "1h 35m", points: 42)
                        }
                    }

                    // App Usage
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Apps This Week")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 8) {
                            AppUsageRow(app: "Khan Academy Kids", time: "2h 15m", category: "Educational")
                            AppUsageRow(app: "Minecraft", time: "1h 48m", category: "Entertainment")
                            AppUsageRow(app: "Duolingo", time: "1h 22m", category: "Educational")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Reports")
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

struct ReportStatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text(change)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .green : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DailyReportRow: View {
    let day: String
    let screenTime: String
    let educational: String
    let points: Int

    var body: some View {
        HStack {
            Text(day)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)

            Text(screenTime)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(educational)
                .foregroundColor(.green)
                .frame(width: 60, alignment: .leading)

            Spacer()

            Text("\(points) pts")
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct AppUsageRow: View {
    let app: String
    let time: String
    let category: String

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)

            Text(app)
                .fontWeight(.medium)

            Spacer()

            VStack(alignment: .trailing) {
                Text(time)
                    .fontWeight(.medium)
                Text(category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Additional Settings Views
struct BedtimeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bedtimeEnabled = true
    @State private var weekdayBedtime = createDate(hour: 20, minute: 0)
    @State private var weekdayWakeup = createDate(hour: 7, minute: 0)
    @State private var weekendBedtime = createDate(hour: 21, minute: 0)
    @State private var weekendWakeup = createDate(hour: 8, minute: 0)
    @State private var blockAtBedtime = true
    @State private var allowEducationalApps = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Bedtime Schedule") {
                    Toggle("Enable Bedtime", isOn: $bedtimeEnabled)

                    if bedtimeEnabled {
                        Group {
                            DatePicker("Weekday Bedtime", selection: $weekdayBedtime, displayedComponents: .hourAndMinute)
                            DatePicker("Weekday Wake Up", selection: $weekdayWakeup, displayedComponents: .hourAndMinute)

                            DatePicker("Weekend Bedtime", selection: $weekendBedtime, displayedComponents: .hourAndMinute)
                            DatePicker("Weekend Wake Up", selection: $weekendWakeup, displayedComponents: .hourAndMinute)
                        }
                    }
                }

                if bedtimeEnabled {
                    Section("Bedtime Restrictions") {
                        Toggle("Block all apps during bedtime", isOn: $blockAtBedtime)

                        if !blockAtBedtime {
                            Toggle("Allow educational apps", isOn: $allowEducationalApps)
                        }
                    }

                    Section("Bedtime Features") {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.indigo)
                            VStack(alignment: .leading) {
                                Text("Wind Down")
                                Text("Dim screen 30 minutes before bedtime")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                        }

                        HStack {
                            Image(systemName: "bell.slash.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Do Not Disturb")
                                Text("Block notifications during bedtime")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                        }
                    }
                }
            }
            .navigationTitle("Bedtime Settings")
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

    private static func createDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }
}

struct UsageTrendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe = "Week"
    private let timeframes = ["Week", "Month", "3 Months", "Year"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time frame selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Text(timeframe).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Trends Charts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Screen Time Trends")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        // Mock chart area
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    Text("Screen Time Chart")
                                        .font(.headline)
                                    Text("Interactive chart showing usage patterns")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                            .padding(.horizontal)
                    }

                    // Key Insights
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            TrendInsightCard(
                                icon: "arrow.down.circle.fill",
                                title: "Screen Time Decreased",
                                subtitle: "15% reduction this week",
                                trend: .positive
                            )

                            TrendInsightCard(
                                icon: "book.fill",
                                title: "Educational Apps Up",
                                subtitle: "32% more learning time",
                                trend: .positive
                            )

                            TrendInsightCard(
                                icon: "gamecontroller.fill",
                                title: "Gaming Time",
                                subtitle: "Stayed within limits",
                                trend: .neutral
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Weekly Pattern
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weekly Pattern")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                                DayUsageRow(
                                    day: day,
                                    usage: generateMockUsage(for: day),
                                    isWeekend: day == "Saturday" || day == "Sunday"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Usage Trends")
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

    private func generateMockUsage(for day: String) -> String {
        let weekendDays = ["Saturday", "Sunday"]
        let baseHours = weekendDays.contains(day) ? 4 : 2
        let variation = Int.random(in: -30...60)
        let minutes = (baseHours * 60) + variation
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

struct TrendInsightCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let trend: TrendType

    enum TrendType {
        case positive, negative, neutral

        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .orange
            }
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(trend.color)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: trend == .positive ? "arrow.up.right" : trend == .negative ? "arrow.down.right" : "minus")
                .foregroundColor(trend.color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DayUsageRow: View {
    let day: String
    let usage: String
    let isWeekend: Bool

    var body: some View {
        HStack {
            Text(day)
                .fontWeight(.medium)
                .foregroundColor(isWeekend ? .orange : .primary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            Text(usage)
                .fontWeight(.medium)
                .foregroundColor(.blue)

            // Usage bar representation
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: CGFloat.random(in: 20...100), height: 4)
                .cornerRadius(2)
        }
        .padding(.vertical, 4)
    }
}


struct FamilyMember {
    let id = UUID()
    let name: String
    let isChild: Bool
    let hasAppInstalled: Bool
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
