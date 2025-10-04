import SwiftUI
import Foundation
import FamilyControlsKit

// Simplified model definitions for now
struct EntertainmentAppConfig: Codable, Identifiable {
    let id = UUID()
    let bundleID: String
    let displayName: String
    let pointsCostPer30Min: Int
    let pointsCostPer60Min: Int
    let isEnabled: Bool
    let parentConfiguredAt: Date
    
    func pointsCost(for durationMinutes: Int) -> Int {
        if durationMinutes <= 30 {
            return pointsCostPer30Min
        } else {
            return pointsCostPer60Min
        }
    }
}

struct AppUnlockInfo: Codable, Identifiable {
    let id = UUID()
    let bundleID: String
    let appName: String
    let unlockedAt: Date
    let expiresAt: Date
    let pointsCost: Int
    let childID: String
    
    var isActive: Bool {
        Date() < expiresAt
    }
    
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }
}


/// Enhanced rewards view with improved UI/UX
struct EnhancedRewardsView: View {
    @State private var currentPoints: Int = 125
    @State private var entertainmentApps: [EntertainmentAppConfig] = []
    @State private var unlockedApps: [AppUnlockInfo] = []
    @State private var redeemedRewards: [RedeemedReward] = []
    @State private var showingRedemptionAlert = false
    @State private var selectedReward: String = ""
    @State private var showingPointsHelp = false
    @StateObject private var familyControlsService = FamilyControlsService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced Points Balance Header
                    PointsBalanceHeader(
                        points: currentPoints,
                        onHelpTap: {
                            showingPointsHelp = true
                        }
                    )
                    
                    // Points Earning Tips
                    PointsEarningTips()
                    
                    // Available Entertainment Apps with enhanced design
                    AvailableAppsSection(
                        apps: entertainmentApps,
                        currentPoints: currentPoints,
                        unlockedApps: unlockedApps,
                        onUnlock: { app, duration in
                            unlockApp(app, durationMinutes: duration)
                        }
                    )
                    
                    // Special Rewards Section
                    SpecialRewardsSection(
                        currentPoints: currentPoints,
                        onRedeem: { rewardName, cost in
                            redeemReward(rewardName, cost: cost)
                        }
                    )
                    
                    // Recent Redemptions with enhanced styling
                    if !redeemedRewards.isEmpty {
                        RecentRedemptionsSection(rewards: Array(redeemedRewards.prefix(3)))
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Rewards")
            .refreshable {
                loadRewardsConfiguration()
            }
            .onAppear {
                loadRewardsConfiguration()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPointsHelp = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .alert("Reward Redeemed!", isPresented: $showingRedemptionAlert) {
            Button("Awesome!") { }
        } message: {
            Text("Your \(selectedReward) reward has been redeemed! Ask your parent to approve it.")
        }
        .sheet(isPresented: $showingPointsHelp) {
            PointsHelpView()
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
        // Mock data for now
        unlockedApps = [
            AppUnlockInfo(
                bundleID: "com.youtube.youtube",
                appName: "YouTube",
                unlockedAt: Date().addingTimeInterval(-3600),
                expiresAt: Date().addingTimeInterval(3600),
                pointsCost: 20,
                childID: "default"
            )
        ]
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
        
        // Deduct points
        currentPoints -= pointsCost
        
        // Add to unlocked apps
        let unlockInfo = AppUnlockInfo(
            bundleID: app.bundleID,
            appName: app.displayName,
            unlockedAt: Date(),
            expiresAt: Date().addingTimeInterval(Double(durationMinutes * 60)),
            pointsCost: pointsCost,
            childID: "default"
        )
        unlockedApps.append(unlockInfo)
        
        // Show success
        selectedReward = "\(app.displayName) (\(durationMinutes) min)"
        showingRedemptionAlert = true
    }
    
    private func redeemReward(_ rewardName: String, cost: Int) {
        guard currentPoints >= cost else { return }
        
        // Deduct points
        currentPoints -= cost
        
        // Add to redeemed rewards
        let redemption = RedeemedReward(
            name: rewardName,
            cost: cost
        )
        redeemedRewards.insert(redemption, at: 0)
        
        // Show success alert
        selectedReward = rewardName
        showingRedemptionAlert = true
    }
}

/// Enhanced points balance header with better design
struct PointsBalanceHeader: View {
    let points: Int
    let onHelpTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                
                Button(action: onHelpTap) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 4) {
                Text("\(points)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Available Points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress towards next reward
            VStack(spacing: 8) {
                Text("50 points until your next reward!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: Double(points % 100), total: 100.0)
                    .progressViewStyle(.linear)
                    .tint(.yellow)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Points earning tips section
struct PointsEarningTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Earn More Points")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PointsTipRow(
                    icon: "graduationcap.fill",
                    title: "Use Learning Apps",
                    description: "Earn 1 point per minute in educational apps"
                )
                
                PointsTipRow(
                    icon: "chart.bar.fill",
                    title: "Maintain Streaks",
                    description: "Keep your learning streak for bonus points"
                )
                
                PointsTipRow(
                    icon: "trophy.fill",
                    title: "Achieve Goals",
                    description: "Complete daily goals for extra rewards"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

/// Points tip row component
struct PointsTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
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

/// Available apps section with enhanced design
struct AvailableAppsSection: View {
    let apps: [EntertainmentAppConfig]
    let currentPoints: Int
    let unlockedApps: [AppUnlockInfo]
    let onUnlock: (EntertainmentAppConfig, Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Entertainment Apps")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 16) {
                ForEach(apps, id: \.bundleID) { app in
                    EnhancedEntertainmentAppCard(
                        app: app,
                        currentPoints: currentPoints,
                        isUnlocked: unlockedApps.contains { $0.bundleID == app.bundleID && $0.isActive },
                        onUnlock: { duration in
                            onUnlock(app, duration)
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Enhanced entertainment app card with better design
struct EnhancedEntertainmentAppCard: View {
    let app: EntertainmentAppConfig
    let currentPoints: Int
    let isUnlocked: Bool
    let onUnlock: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Entertainment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Unlocked")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            if !isUnlocked {
                HStack(spacing: 16) {
                    UnlockOptionButton(
                        duration: 30,
                        points: app.pointsCostPer30Min,
                        currentPoints: currentPoints,
                        onTap: { onUnlock(30) }
                    )
                    
                    UnlockOptionButton(
                        duration: 60,
                        points: app.pointsCostPer60Min,
                        currentPoints: currentPoints,
                        onTap: { onUnlock(60) }
                    )
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

/// Unlock option button component
struct UnlockOptionButton: View {
    let duration: Int
    let points: Int
    let currentPoints: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(duration) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(points)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(canAfford ? Color.blue : Color(.systemGray4))
            )
            .foregroundColor(.white)
        }
        .disabled(!canAfford)
        .opacity(canAfford ? 1.0 : 0.6)
    }
    
    private var canAfford: Bool {
        currentPoints >= points
    }
}

/// Special rewards section
struct SpecialRewardsSection: View {
    let currentPoints: Int
    let onRedeem: (String, Int) -> Void
    
    // Sample special rewards
    private let specialRewards = [
        ("Extra Screen Time", 50),
        ("Movie Night", 75),
        ("Ice Cream Treat", 30),
        ("Stay Up Late", 100)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Special Rewards")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(specialRewards, id: \.0) { reward in
                    SpecialRewardCard(
                        title: reward.0,
                        cost: reward.1,
                        currentPoints: currentPoints,
                        onRedeem: {
                            onRedeem(reward.0, reward.1)
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Special reward card component
struct SpecialRewardCard: View {
    let title: String
    let cost: Int
    let currentPoints: Int
    let onRedeem: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(cost) points")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            Button("Redeem") {
                onRedeem()
            }
            .buttonStyle(.borderedProminent)
            .disabled(currentPoints < cost)
            .opacity(currentPoints >= cost ? 1.0 : 0.6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

/// Recent redemptions section with enhanced styling
struct RecentRedemptionsSection: View {
    let rewards: [RedeemedReward]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Redemptions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(rewards, id: \.id) { reward in
                    EnhancedRecentRedemptionRow(reward: reward)
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Enhanced recent redemption row with better styling
struct EnhancedRecentRedemptionRow: View {
    let reward: RedeemedReward
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(reward.redeemedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("\(reward.cost)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Points help view for explaining the reward system
struct PointsHelpView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView()
                    
                    HowItWorksSection()
                    
                    EarningPointsSection()
                    
                    RedeemingPointsSection()
                    
                    TipsSection()
                }
                .padding()
            }
            .navigationTitle("Points Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Header view for points help
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("ScreenTime Rewards Points")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Earn points for learning, spend them for fun!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom)
    }
}

/// How it works section
struct HowItWorksSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                HowItWorksStep(
                    number: 1,
                    title: "Earn Points",
                    description: "Use educational apps to earn points - 1 point per minute of learning!"
                )
                
                HowItWorksStep(
                    number: 2,
                    title: "Track Progress",
                    description: "See your points grow and maintain streaks for bonus rewards"
                )
                
                HowItWorksStep(
                    number: 3,
                    title: "Redeem Rewards",
                    description: "Spend your points on entertainment apps or special treats"
                )
            }
        }
    }
}

/// How it works step component
struct HowItWorksStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.blue))
            
            VStack(alignment: .leading, spacing: 4) {
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

/// Earning points section
struct EarningPointsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earning Points")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                EarningTip(
                    icon: "graduationcap.fill",
                    title: "Learning Apps",
                    description: "Earn 1 point for every minute spent in educational apps like Khan Academy, Duolingo, or Brilliant"
                )
                
                EarningTip(
                    icon: "flame.fill",
                    title: "Streak Bonuses",
                    description: "Maintain daily learning streaks for extra points - the longer your streak, the bigger the bonus!"
                )
                
                EarningTip(
                    icon: "target",
                    title: "Goal Completion",
                    description: "Complete daily learning goals for additional point rewards"
                )
            }
        }
    }
}

/// Redeeming points section
struct RedeemingPointsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Redeeming Points")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                RedeemingTip(
                    icon: "tv.fill",
                    title: "Entertainment Apps",
                    description: "Unlock entertainment apps like YouTube, TikTok, or Netflix for 15-60 minutes"
                )
                
                RedeemingTip(
                    icon: "gift.fill",
                    title: "Special Rewards",
                    description: "Redeem points for real-world treats like ice cream, movie nights, or staying up late"
                )
            }
        }
    }
}

/// Tips section
struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pro Tips")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TipRow(
                    icon: "bolt.fill",
                    title: "Start Small",
                    description: "Begin with shorter learning sessions and gradually increase your time"
                )
                
                TipRow(
                    icon: "calendar",
                    title: "Be Consistent",
                    description: "Try to learn a little bit every day to build your streak"
                )
                
                TipRow(
                    icon: "heart.fill",
                    title: "Have Fun",
                    description: "Choose learning apps you enjoy to make earning points more fun"
                )
            }
        }
    }
}

/// Earning tip component
struct EarningTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Redeeming tip component
struct RedeemingTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Tip row component
struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
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

#Preview {
    EnhancedRewardsView()
}