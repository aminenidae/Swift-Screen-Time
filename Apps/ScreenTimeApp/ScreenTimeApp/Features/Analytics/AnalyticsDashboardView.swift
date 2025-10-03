import SwiftUI
import RewardCore
import SharedModels
import Charts

/// Main analytics dashboard for parents to view detailed usage insights
@available(iOS 16.0, *)
struct AnalyticsDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService(
        consentService: AnalyticsConsentService(),
        anonymizationService: DataAnonymizationService(),
        aggregationService: AnalyticsAggregationService()
    )

    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedChild: String = "all"
    @State private var isLoading = false
    @State private var analyticsData: AnalyticsData?
    @State private var showExportSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range and Filter Controls
                    VStack(spacing: 16) {
                        TimeRangeSelector(selectedRange: $selectedTimeRange) {
                            loadAnalyticsData()
                        }

                        ChildFilterPicker(selectedChild: $selectedChild) {
                            loadAnalyticsData()
                        }
                    }
                    .padding(.horizontal)

                    if isLoading {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let data = analyticsData {
                        // Key Metrics Overview
                        KeyMetricsSection(data: data)

                        // Usage Trends Chart
                        UsageTrendsSection(data: data, timeRange: selectedTimeRange)

                        // App Category Breakdown
                        AppCategorySection(data: data)

                        // Learning Progress
                        LearningProgressSection(data: data)

                        // Screen Time Goals
                        ScreenTimeGoalsSection(data: data)

                        // Reward Statistics
                        RewardStatisticsSection(data: data)
                    } else {
                        EmptyAnalyticsView {
                            loadAnalyticsData()
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Data") {
                            showExportSheet = true
                        }

                        Button("Refresh") {
                            loadAnalyticsData()
                        }

                        NavigationLink("Settings") {
                            AnalyticsSettingsView()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await loadAnalyticsData()
            }
        }
        .task {
            await loadAnalyticsData()
        }
        .sheet(isPresented: $showExportSheet) {
            AnalyticsExportView(data: analyticsData)
        }
    }

    private func loadAnalyticsData() {
        Task {
            await loadAnalyticsData()
        }
    }

    @MainActor
    private func loadAnalyticsData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Generate mock analytics data for now
            // In a real implementation, this would fetch from AnalyticsService
            analyticsData = generateMockAnalyticsData()
        } catch {
            print("Failed to load analytics data: \(error)")
        }
    }

    private func generateMockAnalyticsData() -> AnalyticsData {
        AnalyticsData(
            timeRange: selectedTimeRange,
            childFilter: selectedChild,
            keyMetrics: KeyMetrics(
                totalScreenTime: 420, // 7 hours in minutes
                learningTime: 180,    // 3 hours
                entertainmentTime: 240, // 4 hours
                pointsEarned: 450,
                pointsSpent: 320,
                dailyGoalAchievement: 0.85
            ),
            usageTrends: generateMockUsageTrends(),
            appCategories: generateMockAppCategories(),
            learningProgress: generateMockLearningProgress(),
            screenTimeGoals: generateMockScreenTimeGoals(),
            rewardStatistics: generateMockRewardStatistics()
        )
    }

    private func generateMockUsageTrends() -> [UsageDataPoint] {
        (0..<7).map { day in
            UsageDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -day, to: Date()) ?? Date(),
                screenTime: Double.random(in: 30...120),
                learningTime: Double.random(in: 10...60),
                pointsEarned: Int.random(in: 20...100)
            )
        }.reversed()
    }

    private func generateMockAppCategories() -> [AppCategoryData] {
        [
            AppCategoryData(category: "Educational", timeSpent: 180, pointsEarned: 360),
            AppCategoryData(category: "Entertainment", timeSpent: 120, pointsEarned: 0),
            AppCategoryData(category: "Social", timeSpent: 60, pointsEarned: 0),
            AppCategoryData(category: "Games", timeSpent: 90, pointsEarned: 0)
        ]
    }

    private func generateMockLearningProgress() -> [LearningProgress] {
        [
            LearningProgress(subject: "Math", timeSpent: 45, progress: 0.75),
            LearningProgress(subject: "Reading", timeSpent: 60, progress: 0.90),
            LearningProgress(subject: "Science", timeSpent: 30, progress: 0.60),
            LearningProgress(subject: "History", timeSpent: 25, progress: 0.45)
        ]
    }

    private func generateMockScreenTimeGoals() -> [ScreenTimeGoal] {
        [
            ScreenTimeGoal(day: "Monday", goal: 60, actual: 45),
            ScreenTimeGoal(day: "Tuesday", goal: 60, actual: 75),
            ScreenTimeGoal(day: "Wednesday", goal: 60, actual: 50),
            ScreenTimeGoal(day: "Thursday", goal: 60, actual: 65),
            ScreenTimeGoal(day: "Friday", goal: 90, actual: 80),
            ScreenTimeGoal(day: "Saturday", goal: 120, actual: 110),
            ScreenTimeGoal(day: "Sunday", goal: 90, actual: 95)
        ]
    }

    private func generateMockRewardStatistics() -> RewardStatistics {
        RewardStatistics(
            totalPointsEarned: 450,
            totalPointsSpent: 320,
            averagePointsPerDay: 64,
            mostRedeemed: "Netflix (60 min)",
            streakDays: 5,
            goalAchievementRate: 0.85
        )
    }
}

// MARK: - Time Range Selector

enum TimeRange: String, CaseIterable {
    case day = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    let onSelectionChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Period")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedRange) { _ in
                onSelectionChanged()
            }
        }
    }
}

// MARK: - Child Filter Picker

struct ChildFilterPicker: View {
    @Binding var selectedChild: String
    let onSelectionChanged: () -> Void

    private let mockChildren = ["all", "Alex", "Sam", "Emma"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Child")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Child", selection: $selectedChild) {
                Text("All Children").tag("all")
                ForEach(mockChildren.dropFirst(), id: \.self) { child in
                    Text(child).tag(child)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedChild) { _ in
                onSelectionChanged()
            }
        }
    }
}

// MARK: - Data Models

struct AnalyticsData {
    let timeRange: TimeRange
    let childFilter: String
    let keyMetrics: KeyMetrics
    let usageTrends: [UsageDataPoint]
    let appCategories: [AppCategoryData]
    let learningProgress: [LearningProgress]
    let screenTimeGoals: [ScreenTimeGoal]
    let rewardStatistics: RewardStatistics
}

struct KeyMetrics {
    let totalScreenTime: Int // minutes
    let learningTime: Int
    let entertainmentTime: Int
    let pointsEarned: Int
    let pointsSpent: Int
    let dailyGoalAchievement: Double // percentage
}

struct UsageDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let screenTime: Double
    let learningTime: Double
    let pointsEarned: Int
}

struct AppCategoryData: Identifiable {
    let id = UUID()
    let category: String
    let timeSpent: Int // minutes
    let pointsEarned: Int
}

struct LearningProgress: Identifiable {
    let id = UUID()
    let subject: String
    let timeSpent: Int // minutes
    let progress: Double // percentage
}

struct ScreenTimeGoal: Identifiable {
    let id = UUID()
    let day: String
    let goal: Int // minutes
    let actual: Int // minutes
}

struct RewardStatistics {
    let totalPointsEarned: Int
    let totalPointsSpent: Int
    let averagePointsPerDay: Int
    let mostRedeemed: String
    let streakDays: Int
    let goalAchievementRate: Double
}

// MARK: - Empty State

struct EmptyAnalyticsView: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Analytics Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Start using the app to see detailed insights about screen time and learning progress.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Refresh") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct AnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsDashboardView()
    }
}
#endif