import SwiftUI
import Charts
import SubscriptionService
import SharedModels

/// Premium analytics features available to subscribers
@available(iOS 16.0, *)
struct PremiumAnalyticsView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var featureGateService = FeatureGateService.shared

    @State private var selectedMetric: PremiumMetric = .screenTimePatterns
    @State private var comparisonPeriod: ComparisonPeriod = .lastMonth
    @State private var isLoading = false
    @State private var premiumData: PremiumAnalyticsData?
    @State private var showUpgradePrompt = false

    var body: some View {
        NavigationStack {
            Group {
                // Check if the feature is available
                // For now, we'll show the gate since we don't have the proper method
                premiumAnalyticsGate
            }
            .navigationTitle("Advanced Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(PremiumMetric.allCases, id: \.self) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }

                        Picker("Compare to", selection: $comparisonPeriod) {
                            ForEach(ComparisonPeriod.allCases, id: \.self) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
        .task {
            await loadPremiumData()
        }
        .sheet(isPresented: $showUpgradePrompt) {
            PaywallView()
        }
    }

    @ViewBuilder
    private var premiumAnalyticsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Premium Feature Badge
                PremiumBadge()

                // For now, we'll just show a placeholder instead of the missing components
                Text("Premium Analytics Content")
                    .font(.title2)
                    .foregroundColor(.secondary)

                if isLoading {
                    ProgressView("Loading advanced analytics...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if premiumData != nil {
                    // Show some basic data instead of the missing sections
                    Text("Analytics data loaded")
                        .font(.headline)
                } else {
                    EmptyPremiumAnalyticsView {
                        loadPremiumData()
                    }
                }
            }
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var premiumAnalyticsGate: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text("Advanced Analytics")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Unlock powerful insights with premium analytics features")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                PremiumFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Screen Time Patterns",
                    description: "Detailed analysis of daily and weekly usage patterns"
                )

                PremiumFeatureRow(
                    icon: "speedometer",
                    title: "Productivity Metrics",
                    description: "Advanced metrics for learning efficiency and focus time"
                )

                PremiumFeatureRow(
                    icon: "person.2.fill",
                    title: "Family Comparisons",
                    description: "Compare usage patterns across family members"
                )

                PremiumFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Insights",
                    description: "Smart recommendations based on usage patterns"
                )

                PremiumFeatureRow(
                    icon: "doc.text.fill",
                    title: "Detailed Reports",
                    description: "Comprehensive reports with export capabilities"
                )
            }

            Button("Upgrade to Premium") {
                showUpgradePrompt = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private func loadPremiumData() {
        Task {
            await loadPremiumData()
        }
    }

    @MainActor
    private func loadPremiumData() async {
        isLoading = true
        defer { isLoading = false }

        // Generate mock premium analytics data
        premiumData = generateMockPremiumData()
    }

    private func generateMockPremiumData() -> PremiumAnalyticsData {
        PremiumAnalyticsData(
            screenTimePatterns: generateScreenTimePatterns(),
            productivityMetrics: generateProductivityMetrics(),
            familyComparison: generateFamilyComparison(),
            predictiveInsights: generatePredictiveInsights(),
            detailedReports: generateDetailedReports(),
            aiInsights: generateAIInsights()
        )
    }

    private func generateScreenTimePatterns() -> ScreenTimePatterns {
        ScreenTimePatterns(
            peakUsageHours: [9, 13, 16, 20],
            averageSessionLength: 23,
            longestStreak: 14,
            weekdayVsWeekend: WeekdayWeekendComparison(weekday: 85, weekend: 120),
            seasonalTrends: [0.8, 1.1, 0.9, 1.2, 1.0, 0.7, 0.8, 0.9, 1.1, 1.0, 0.9, 1.3]
        )
    }

    private func generateProductivityMetrics() -> ProductivityMetrics {
        ProductivityMetrics(
            focusTimePercentage: 0.68,
            learningEfficiency: 0.82,
            distractionEvents: 12,
            deepWorkSessions: 5,
            contextSwitching: 18,
            productivityScore: 78
        )
    }

    private func generateFamilyComparison() -> FamilyComparison {
        FamilyComparison(
            members: [
                FamilyMemberAnalytics(name: "Alex", screenTime: 85, learningTime: 45, productivityScore: 82),
                FamilyMemberAnalytics(name: "Sam", screenTime: 72, learningTime: 38, productivityScore: 75),
                FamilyMemberAnalytics(name: "Emma", screenTime: 95, learningTime: 52, productivityScore: 88)
            ],
            familyAverage: FamilyMemberAnalytics(name: "Family", screenTime: 84, learningTime: 45, productivityScore: 82)
        )
    }

    private func generatePredictiveInsights() -> PredictiveInsights {
        PredictiveInsights(
            predictions: [
                "Based on current trends, Alex is likely to exceed screen time goals by 15% this week",
                "Sam shows increased learning focus on Tuesdays - consider scheduling challenging activities then",
                "Weekend screen time typically increases by 40% - plan engaging offline activities"
            ],
            recommendations: [
                "Implement 'Focus Mode' during 2-4 PM when distractions are highest",
                "Consider reducing entertainment app access 1 hour before bedtime",
                "Schedule family activities during peak usage hours to reduce screen time naturally"
            ]
        )
    }

    private func generateDetailedReports() -> DetailedReports {
        DetailedReports(
            monthlyProgress: MonthlyProgress(
                screenTimeChange: -8.5,
                learningTimeChange: 12.3,
                goalAchievementChange: 15.2
            ),
            appUsageBreakdown: [
                AppUsageDetail(app: "Khan Academy", category: "Educational", time: 180, efficiency: 0.92),
                AppUsageDetail(app: "Netflix", category: "Entertainment", time: 120, efficiency: 0.0),
                AppUsageDetail(app: "Safari", category: "Productivity", time: 45, efficiency: 0.65)
            ]
        )
    }

    private func generateAIInsights() -> [AIInsight] {
        [
            AIInsight(
                type: .pattern,
                title: "Consistent Learning Routine",
                description: "Alex shows excellent consistency in morning learning sessions (9-11 AM)",
                confidence: 0.94,
                actionable: true
            ),
            AIInsight(
                type: .optimization,
                title: "Focus Time Opportunity",
                description: "Consider blocking social apps during 2-4 PM when focus drops significantly",
                confidence: 0.87,
                actionable: true
            ),
            AIInsight(
                type: .warning,
                title: "Weekend Screen Time Spike",
                description: "Weekend usage is 40% higher than weekdays - may impact Monday motivation",
                confidence: 0.91,
                actionable: true
            )
        ]
    }
}

// MARK: - Premium Data Models

struct PremiumAnalyticsData {
    let screenTimePatterns: ScreenTimePatterns
    let productivityMetrics: ProductivityMetrics
    let familyComparison: FamilyComparison
    let predictiveInsights: PredictiveInsights
    let detailedReports: DetailedReports
    let aiInsights: [AIInsight]
}

struct ScreenTimePatterns {
    let peakUsageHours: [Int]
    let averageSessionLength: Int
    let longestStreak: Int
    let weekdayVsWeekend: WeekdayWeekendComparison
    let seasonalTrends: [Double]
}

struct WeekdayWeekendComparison {
    let weekday: Int
    let weekend: Int
}

struct ProductivityMetrics {
    let focusTimePercentage: Double
    let learningEfficiency: Double
    let distractionEvents: Int
    let deepWorkSessions: Int
    let contextSwitching: Int
    let productivityScore: Int
}

struct FamilyComparison {
    let members: [FamilyMemberAnalytics]
    let familyAverage: FamilyMemberAnalytics
}

struct FamilyMemberAnalytics {
    let name: String
    let screenTime: Int
    let learningTime: Int
    let productivityScore: Int
}

struct PredictiveInsights {
    let predictions: [String]
    let recommendations: [String]
}

struct DetailedReports {
    let monthlyProgress: MonthlyProgress
    let appUsageBreakdown: [AppUsageDetail]
}

struct MonthlyProgress {
    let screenTimeChange: Double
    let learningTimeChange: Double
    let goalAchievementChange: Double
}

struct AppUsageDetail {
    let app: String
    let category: String
    let time: Int
    let efficiency: Double
}

struct AIInsight {
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let actionable: Bool

    enum InsightType {
        case pattern, optimization, warning, achievement
    }
}

enum PremiumMetric: String, CaseIterable {
    case screenTimePatterns = "patterns"
    case productivityMetrics = "productivity"
    case familyComparison = "family"
    case predictiveInsights = "insights"
    case detailedReports = "reports"

    var displayName: String {
        switch self {
        case .screenTimePatterns: return "Screen Time Patterns"
        case .productivityMetrics: return "Productivity Metrics"
        case .familyComparison: return "Family Comparison"
        case .predictiveInsights: return "Predictive Insights"
        case .detailedReports: return "Detailed Reports"
        }
    }
}

enum ComparisonPeriod: String, CaseIterable {
    case lastWeek = "week"
    case lastMonth = "month"
    case lastQuarter = "quarter"
    case lastYear = "year"

    var displayName: String {
        switch self {
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastQuarter: return "Last Quarter"
        case .lastYear: return "Last Year"
        }
    }
}

// MARK: - Premium Sections

struct PremiumBadge: View {
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("Premium Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct EmptyPremiumAnalyticsView: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Premium Data Available")
                .font(.title2)
                .fontWeight(.semibold)

            Button("Refresh") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct PremiumAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumAnalyticsView()
    }
}
#endif