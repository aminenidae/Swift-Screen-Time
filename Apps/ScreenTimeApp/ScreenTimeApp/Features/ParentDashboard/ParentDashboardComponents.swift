import SwiftUI
import Charts
import SharedModels

// MARK: - Parent Dashboard Components

/// Statistics card for family overview display
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

/// Progress card showing individual child's learning progress
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

/// Quick action button for common parent tasks
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

/// Parent activity monitoring view showing detailed analytics and reports
struct ActivityView: View {
    @State private var selectedTimeRange: ActivityTimeRange = .week
    @State private var selectedChild: String = "All Children"
    @State private var showingAnalyticsDetail = false

    // Sample data - in real app this would come from analytics service
    @State private var children = ["Alex", "Emma", "Sam"]
    @State private var weeklyData: [DailyUsage] = [
        DailyUsage(date: Date().addingTimeInterval(-518400), educational: 45, entertainment: 30, points: 45),
        DailyUsage(date: Date().addingTimeInterval(-432000), educational: 60, entertainment: 20, points: 60),
        DailyUsage(date: Date().addingTimeInterval(-345600), educational: 30, entertainment: 45, points: 30),
        DailyUsage(date: Date().addingTimeInterval(-259200), educational: 75, entertainment: 15, points: 75),
        DailyUsage(date: Date().addingTimeInterval(-172800), educational: 55, entertainment: 25, points: 55),
        DailyUsage(date: Date().addingTimeInterval(-86400), educational: 40, entertainment: 35, points: 40),
        DailyUsage(date: Date(), educational: 65, entertainment: 20, points: 65)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Filter Controls
                    VStack(spacing: 12) {
                        // Time Range Picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            Text("Today").tag(ActivityTimeRange.day)
                            Text("This Week").tag(ActivityTimeRange.week)
                            Text("This Month").tag(ActivityTimeRange.month)
                        }
                        .pickerStyle(.segmented)

                        // Child Filter
                        HStack {
                            Text("Child:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Picker("Child", selection: $selectedChild) {
                                Text("All Children").tag("All Children")
                                ForEach(children, id: \.self) { child in
                                    Text(child).tag(child)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(.horizontal)

                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        SummaryCard(
                            title: "Learning Time",
                            value: "\(totalEducationalTime) min",
                            subtitle: "Today",
                            color: .green,
                            icon: "book.fill"
                        )

                        SummaryCard(
                            title: "Points Earned",
                            value: "\(totalPointsEarned)",
                            subtitle: "Today",
                            color: .blue,
                            icon: "star.fill"
                        )

                        SummaryCard(
                            title: "Screen Time",
                            value: "\(totalScreenTime) min",
                            subtitle: "Today",
                            color: .orange,
                            icon: "iphone"
                        )

                        SummaryCard(
                            title: "Daily Goal",
                            value: "\(goalProgress)%",
                            subtitle: "Achieved",
                            color: .purple,
                            icon: "target"
                        )
                    }
                    .padding(.horizontal)

                    // Recent Activity List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(spacing: 8) {
                            ActivityRow(
                                childName: "Alex",
                                appName: "Khan Academy",
                                duration: "25 min",
                                pointsEarned: 25,
                                timeAgo: "2 hours ago",
                                isEducational: true
                            )

                            ActivityRow(
                                childName: "Emma",
                                appName: "Duolingo",
                                duration: "15 min",
                                pointsEarned: 15,
                                timeAgo: "3 hours ago",
                                isEducational: true
                            )

                            ActivityRow(
                                childName: "Alex",
                                appName: "YouTube",
                                duration: "30 min",
                                pointsEarned: 0,
                                timeAgo: "4 hours ago",
                                isEducational: false
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Family Activity")
            .refreshable {
                // Refresh activity data
            }
            .sheet(isPresented: $showingAnalyticsDetail) {
                AnalyticsDashboardView()
            }
        }
    }

    // MARK: - Computed Properties

    private var totalEducationalTime: Int {
        weeklyData.last?.educational ?? 0
    }

    private var totalPointsEarned: Int {
        weeklyData.last?.points ?? 0
    }

    private var totalScreenTime: Int {
        let today = weeklyData.last
        return (today?.educational ?? 0) + (today?.entertainment ?? 0)
    }

    private var goalProgress: Int {
        let dailyGoal = 60 // minutes
        return min(Int((Double(totalEducationalTime) / Double(dailyGoal)) * 100), 100)
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
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

struct ActivityRow: View {
    let childName: String
    let appName: String
    let duration: String
    let pointsEarned: Int
    let timeAgo: String
    let isEducational: Bool

    var body: some View {
        HStack(spacing: 12) {
            // App Category Icon
            Image(systemName: isEducational ? "book.fill" : "tv.fill")
                .foregroundColor(isEducational ? .green : .orange)
                .font(.title3)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(childName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(appName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text("\(duration) • \(timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if pointsEarned > 0 {
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Supporting Models

enum ActivityTimeRange: CaseIterable {
    case day, week, month

    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
}

struct DailyUsage: Identifiable {
    let id = UUID()
    let date: Date
    let educational: Int // minutes
    let entertainment: Int // minutes
    let points: Int
}