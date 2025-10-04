import SwiftUI
import Combine

// Import local models and services
struct PointTransaction: Codable, Identifiable {
    let id: UUID
    let childID: String
    let points: Int
    let source: PointSource
    let timestamp: Date
    let description: String
    
    init(id: UUID = UUID(), childID: String, points: Int, source: PointSource, timestamp: Date = Date(), description: String) {
        self.id = id
        self.childID = childID
        self.points = points
        self.source = source
        self.timestamp = timestamp
        self.description = description
    }
}

enum PointSource: String, Codable {
    case learningApp
    case streakBonus
    case goalCompletion
    case manualAdjustment
}

class PointTrackingService: ObservableObject {
    static let shared = PointTrackingService()
    
    @Published var pointsEarned: PointTransaction? = nil
    
    private init() {}
    
    func startTracking(for childID: String) async throws {
        // In a real implementation, this would start monitoring Screen Time
        // For now, we'll just simulate
        print("Started tracking points for child: \(childID)")
    }
    
    func recordPoints(for childID: String, points: Int, source: PointSource, description: String) {
        let transaction = PointTransaction(
            childID: childID,
            points: points,
            source: source,
            description: description
        )
        
        DispatchQueue.main.async {
            self.pointsEarned = transaction
        }
    }
}

class StreakTrackingService: ObservableObject {
    static let shared = StreakTrackingService()
    
    private init() {}
    
    func recordActivity(for childID: String, pointsEarned: Int) {
        // In a real implementation, this would update streak data
        // For now, we'll just simulate
        print("Recorded activity for child: \(childID), points: \(pointsEarned)")
    }
}

/// Enhanced main dashboard view for children with improved UI/UX
struct EnhancedChildMainView: View {
    @State private var currentPoints: Int = 125
    @State private var dailyGoal: Int = 200
    @State private var weeklyGoal: Int = 1400
    @State private var todayStreak: Int = 3
    @State private var longestStreak: Int = 7
    @State private var pointsEarnedToday: Int = 85
    @State private var learningGoal: Int = 60
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
            // Enhanced Dashboard Tab
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Subscription Status Indicator
                        SubscriptionStatusIndicator()
                        
                        // Enhanced Progress Section
                        EnhancedProgressDashboard(
                            dailyPoints: currentPoints,
                            dailyGoal: dailyGoal,
                            weeklyPoints: currentPoints * 5, // Simulate weekly data
                            weeklyGoal: weeklyGoal,
                            currentStreak: todayStreak,
                            longestStreak: longestStreak,
                            learningMinutes: pointsEarnedToday,
                            learningGoal: learningGoal
                        )
                        
                        // Achievement Badges Section
                        AchievementBadgesSection()
                        
                        // Recent Activity with enhanced styling
                        RecentLearningSection()
                        
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
            
            // Enhanced Rewards Tab
            EnhancedRewardsView()
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Rewards")
                }
            
            // Enhanced Profile Tab
            EnhancedChildProfileView()
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
            // Enhanced milestone celebration
            EnhancedMilestoneCelebration(
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

/// Enhanced progress dashboard with improved visual design
struct EnhancedProgressDashboard: View {
    let dailyPoints: Int
    let dailyGoal: Int
    let weeklyPoints: Int
    let weeklyGoal: Int
    let currentStreak: Int
    let longestStreak: Int
    let learningMinutes: Int
    let learningGoal: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // Daily Progress Ring
            VStack(spacing: 8) {
                Text("Today's Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(
                            Color(.systemGray4),
                            lineWidth: 10
                        )
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0.0, to: min(Double(dailyPoints) / Double(dailyGoal), 1.0))
                        .stroke(
                            Color.yellow,
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: dailyPoints)
                    
                    // Points display
                    VStack(spacing: 4) {
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(dailyPoints)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("/\(dailyGoal)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 120, height: 120)
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Streak",
                    value: "\(currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Weekly",
                    value: "\(weeklyPoints)/\(weeklyGoal)",
                    icon: "calendar",
                    color: .blue
                )
                
                StatCard(
                    title: "Learning",
                    value: "\(learningMinutes)/\(learningGoal) min",
                    icon: "book.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Stat card for displaying metrics
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

/// Achievement badges section
struct AchievementBadgesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AchievementBadge(
                    title: "Streak Master",
                    icon: "flame.fill",
                    color: .orange,
                    isUnlocked: true
                )
                
                AchievementBadge(
                    title: "Bookworm",
                    icon: "book.fill",
                    color: .green,
                    isUnlocked: true
                )
                
                AchievementBadge(
                    title: "Point Collector",
                    icon: "star.fill",
                    color: .yellow,
                    isUnlocked: false
                )
            }
        }
    }
}

/// Achievement badge component
struct AchievementBadge: View {
    let title: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.2) : Color(.systemGray4).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? color : Color(.systemGray4))
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

/// Recent learning section with enhanced styling
struct RecentLearningSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Learning")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                EnhancedLearningActivityRow(
                    appName: "Khan Academy",
                    duration: "25 min",
                    pointsEarned: 25,
                    timeAgo: "2 hours ago"
                )
                
                EnhancedLearningActivityRow(
                    appName: "Duolingo",
                    duration: "15 min",
                    pointsEarned: 15,
                    timeAgo: "Yesterday"
                )
                
                EnhancedLearningActivityRow(
                    appName: "Brilliant",
                    duration: "30 min",
                    pointsEarned: 30,
                    timeAgo: "2 days ago"
                )
            }
        }
    }
}

/// Enhanced learning activity row with better styling
struct EnhancedLearningActivityRow: View {
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Enhanced milestone celebration with better animation
struct EnhancedMilestoneCelebration: View {
    let title: String
    let subtitle: String
    let icon: String
    let show: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(show ? 0.7 : 0)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Dismiss on tap outside
                }
            
            if show {
                VStack(spacing: 20) {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button("Awesome!") {
                        // Dismiss action
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                )
                .padding(.horizontal)
                .transition(.scale)
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: show)
    }
}

#Preview {
    EnhancedChildMainView()
}