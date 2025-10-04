import SwiftUI
import FamilyControlsKit
import SharedModels
import Foundation
import SubscriptionService

/// Main rewards view where children can redeem points for entertainment apps and other rewards
struct RewardsView: View {
    @State private var currentPoints: Int = 125
    @State private var entertainmentApps: [FamilyControlsKit.EntertainmentAppConfig] = []
    @State private var unlockedApps: [FamilyControlsKit.AppUnlockInfo] = []
    @State private var redeemedRewards: [RedeemedReward] = []
    @State private var showingRedemptionAlert = false
    @State private var selectedReward: String = ""
    @StateObject private var familyControlsService = FamilyControlsService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Subscription Status Indicator
                    SubscriptionStatusIndicator()

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
        var apps: [FamilyControlsKit.EntertainmentAppConfig] = []

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
               let saved = try? JSONDecoder().decode(FamilyControlsKit.EntertainmentAppConfig.self, from: data) {
                apps.append(saved)
            } else {
                // Use default configuration
                let config = FamilyControlsKit.EntertainmentAppConfig(
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

    private func unlockApp(_ app: FamilyControlsKit.EntertainmentAppConfig, durationMinutes: Int) {
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

/// Card component for displaying traditional rewards (non-app rewards)
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

#if DEBUG
struct RewardsView_Previews: PreviewProvider {
    static var previews: some View {
        RewardsView()
    }
}
#endif