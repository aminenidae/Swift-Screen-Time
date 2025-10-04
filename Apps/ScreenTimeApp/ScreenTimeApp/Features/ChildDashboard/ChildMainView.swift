import SwiftUI
import FamilyControlsKit
import RewardCore
import DesignSystem
import SharedModels
import Combine


/// Main dashboard view for children to see their progress and recent activity
struct ChildMainView: View {
    @State private var currentPoints: Int = 125
    @State private var dailyGoal: Int = 200
    @State private var todayStreak: Int = 3
    @State private var longestStreak: Int = 7
    @State private var pointsEarnedToday: Int = 0
    @State private var showPointsAnimation = false
    @State private var lastEarnedPoints: Int = 0
    @State private var showMilestone = false
    @State private var hasReachedDailyGoal = false

    // Point tracking integration
    @StateObject private var pointTrackingService = PointTrackingService.shared
    @StateObject private var streakTrackingService = StreakTrackingService.shared
    @State private var childProfileID = "child_123" // TODO: Get from actual child profile
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Subscription Status Indicator
                        SubscriptionStatusIndicator()

                        // Progress Section
                        ProgressDashboard(
                            dailyPoints: currentPoints,
                            dailyGoal: dailyGoal,
                            weeklyPoints: currentPoints * 5, // Simulate weekly data
                            weeklyGoal: dailyGoal * 7,
                            currentStreak: todayStreak,
                            longestStreak: longestStreak,
                            learningMinutes: pointsEarnedToday,
                            learningGoal: 60
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
        .onAppear {
            setupPointTracking()
        }
        .onReceive(pointTrackingService.$pointsEarned) { transaction in
            if let transaction = transaction {
                handlePointsEarned(transaction)
            }
        }
        .overlay(
            // Enhanced points earned animation
            VStack {
                if lastEarnedPoints >= 50 {
                    // Big burst for major rewards
                    PointsBurstAnimation(
                        points: lastEarnedPoints,
                        show: showPointsAnimation
                    )
                } else if showPointsAnimation {
                    // Regular floating notification
                    FloatingPointsNotification(
                        points: lastEarnedPoints,
                        show: showPointsAnimation,
                        onComplete: {
                            showPointsAnimation = false
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false),
            alignment: .center
        )
        .overlay(
            // Milestone celebration
            MilestoneCelebration(
                title: "Daily Goal Achieved!",
                subtitle: "You earned \(dailyGoal) points today!",
                icon: "trophy.fill",
                show: showMilestone
            )
            .opacity(showMilestone ? 1 : 0)
        )
    }

    // MARK: - Point Tracking Methods

    private func setupPointTracking() {
        Task {
            do {
                try await pointTrackingService.startTracking(for: childProfileID)
                print("✅ Started point tracking for child: \(childProfileID)")
            } catch {
                print("❌ Failed to start point tracking: \(error)")
            }
        }
    }

    private func handlePointsEarned(_ transaction: PointTransaction) {
        let previousPoints = currentPoints

        // Update current points
        currentPoints += transaction.points
        pointsEarnedToday += transaction.points
        lastEarnedPoints = transaction.points

        // Record activity for streak tracking
        streakTrackingService.recordActivity(
            for: childProfileID,
            pointsEarned: transaction.points
        )

        // Check for daily goal achievement
        if !hasReachedDailyGoal && currentPoints >= dailyGoal {
            hasReachedDailyGoal = true

            // Show milestone celebration after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showMilestone = true
                }

                // Auto-hide milestone after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showMilestone = false
                    }
                }
            }
        }

        // Show points earned animation
        withAnimation {
            showPointsAnimation = true
        }

        // Auto-hide points animation for floating notification
        if lastEarnedPoints < 50 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if showPointsAnimation {
                    withAnimation {
                        showPointsAnimation = false
                    }
                }
            }
        }

        print("🎉 Child earned \(transaction.points) points! Total: \(currentPoints)")

        // Log milestone achievement
        if hasReachedDailyGoal && previousPoints < dailyGoal {
            print("🏆 Daily goal achieved! Streak: \(todayStreak)")
        }
    }
}

/// Row displaying learning activity information
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


#if DEBUG
struct ChildMainView_Previews: PreviewProvider {
    static var previews: some View {
        ChildMainView()
    }
}
#endif