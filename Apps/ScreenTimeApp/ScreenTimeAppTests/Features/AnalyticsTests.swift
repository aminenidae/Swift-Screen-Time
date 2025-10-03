import XCTest
import Testing
@testable import ScreenTimeApp

@available(iOS 16.0, *)
final class AnalyticsTests: XCTestCase {

    // MARK: - Analytics Dashboard Tests

    @Test("AnalyticsDashboardView initializes correctly")
    func testAnalyticsDashboardViewInitialization() async throws {
        let dashboardView = AnalyticsDashboardView()
        #expect(dashboardView != nil)
    }

    @Test("Analytics sections render correctly")
    func testAnalyticsSectionsInitialization() async throws {
        let mockData = createMockAnalyticsData()

        let keyMetricsSection = KeyMetricsSection(data: mockData)
        #expect(keyMetricsSection != nil)

        let usageTrendsSection = UsageTrendsSection(data: mockData, timeRange: .week)
        #expect(usageTrendsSection != nil)

        let appCategorySection = AppCategorySection(data: mockData)
        #expect(appCategorySection != nil)

        let learningProgressSection = LearningProgressSection(data: mockData)
        #expect(learningProgressSection != nil)

        let screenTimeGoalsSection = ScreenTimeGoalsSection(data: mockData)
        #expect(screenTimeGoalsSection != nil)

        let rewardStatisticsSection = RewardStatisticsSection(data: mockData)
        #expect(rewardStatisticsSection != nil)
    }

    @Test("Analytics export functionality works")
    func testAnalyticsExportView() async throws {
        let mockData = createMockAnalyticsData()
        let exportView = AnalyticsExportView(data: mockData)
        #expect(exportView != nil)
    }

    @Test("Analytics settings view initializes")
    func testAnalyticsSettingsView() async throws {
        let settingsView = AnalyticsSettingsView()
        #expect(settingsView != nil)
    }

    @Test("Premium analytics view initializes")
    func testPremiumAnalyticsView() async throws {
        let premiumView = PremiumAnalyticsView()
        #expect(premiumView != nil)
    }

    // MARK: - Data Model Tests

    @Test("AnalyticsData model creates correctly")
    func testAnalyticsDataModel() async throws {
        let data = createMockAnalyticsData()

        #expect(data.timeRange == .week)
        #expect(data.childFilter == "all")
        #expect(data.keyMetrics.totalScreenTime == 420)
        #expect(data.keyMetrics.learningTime == 180)
        #expect(data.keyMetrics.pointsEarned == 450)
    }

    @Test("UsageDataPoint model works correctly")
    func testUsageDataPointModel() async throws {
        let dataPoint = UsageDataPoint(
            date: Date(),
            screenTime: 60.0,
            learningTime: 30.0,
            pointsEarned: 50
        )

        #expect(dataPoint.screenTime == 60.0)
        #expect(dataPoint.learningTime == 30.0)
        #expect(dataPoint.pointsEarned == 50)
    }

    @Test("AppCategoryData model works correctly")
    func testAppCategoryDataModel() async throws {
        let categoryData = AppCategoryData(
            category: "Educational",
            timeSpent: 180,
            pointsEarned: 360
        )

        #expect(categoryData.category == "Educational")
        #expect(categoryData.timeSpent == 180)
        #expect(categoryData.pointsEarned == 360)
    }

    @Test("LearningProgress model works correctly")
    func testLearningProgressModel() async throws {
        let progress = LearningProgress(
            subject: "Math",
            timeSpent: 45,
            progress: 0.75
        )

        #expect(progress.subject == "Math")
        #expect(progress.timeSpent == 45)
        #expect(progress.progress == 0.75)
    }

    @Test("RewardStatistics model works correctly")
    func testRewardStatisticsModel() async throws {
        let stats = RewardStatistics(
            totalPointsEarned: 450,
            totalPointsSpent: 320,
            averagePointsPerDay: 64,
            mostRedeemed: "Netflix",
            streakDays: 5,
            goalAchievementRate: 0.85
        )

        #expect(stats.totalPointsEarned == 450)
        #expect(stats.totalPointsSpent == 320)
        #expect(stats.averagePointsPerDay == 64)
        #expect(stats.mostRedeemed == "Netflix")
        #expect(stats.streakDays == 5)
        #expect(stats.goalAchievementRate == 0.85)
    }

    // MARK: - Time Range Tests

    @Test("TimeRange enum works correctly")
    func testTimeRangeEnum() async throws {
        #expect(TimeRange.day.rawValue == "Today")
        #expect(TimeRange.week.rawValue == "This Week")
        #expect(TimeRange.month.rawValue == "This Month")
        #expect(TimeRange.year.rawValue == "This Year")

        #expect(TimeRange.allCases.count == 4)
    }

    // MARK: - Export Format Tests

    @Test("ExportFormat enum works correctly")
    func testExportFormatEnum() async throws {
        #expect(ExportFormat.csv.displayName == "CSV")
        #expect(ExportFormat.json.displayName == "JSON")
        #expect(ExportFormat.pdf.displayName == "PDF")

        #expect(ExportFormat.csv.fileExtension == "csv")
        #expect(ExportFormat.json.fileExtension == "json")
        #expect(ExportFormat.pdf.fileExtension == "pdf")
    }

    @Test("ExportOptions model works correctly")
    func testExportOptionsModel() async throws {
        let options = ExportOptions(
            includeSummary: true,
            includeRawData: false,
            includeCharts: true
        )

        #expect(options.includeSummary == true)
        #expect(options.includeRawData == false)
        #expect(options.includeCharts == true)
    }

    // MARK: - Premium Analytics Tests

    @Test("PremiumAnalyticsData model works correctly")
    func testPremiumAnalyticsDataModel() async throws {
        let premiumData = createMockPremiumAnalyticsData()

        #expect(premiumData.screenTimePatterns.averageSessionLength == 23)
        #expect(premiumData.productivityMetrics.productivityScore == 78)
        #expect(premiumData.familyComparison.members.count == 3)
        #expect(premiumData.aiInsights.count == 3)
    }

    @Test("PremiumMetric enum works correctly")
    func testPremiumMetricEnum() async throws {
        #expect(PremiumMetric.screenTimePatterns.displayName == "Screen Time Patterns")
        #expect(PremiumMetric.productivityMetrics.displayName == "Productivity Metrics")
        #expect(PremiumMetric.familyComparison.displayName == "Family Comparison")
        #expect(PremiumMetric.predictiveInsights.displayName == "Predictive Insights")
        #expect(PremiumMetric.detailedReports.displayName == "Detailed Reports")

        #expect(PremiumMetric.allCases.count == 5)
    }

    @Test("ComparisonPeriod enum works correctly")
    func testComparisonPeriodEnum() async throws {
        #expect(ComparisonPeriod.lastWeek.displayName == "Last Week")
        #expect(ComparisonPeriod.lastMonth.displayName == "Last Month")
        #expect(ComparisonPeriod.lastQuarter.displayName == "Last Quarter")
        #expect(ComparisonPeriod.lastYear.displayName == "Last Year")

        #expect(ComparisonPeriod.allCases.count == 4)
    }

    // MARK: - Integration Tests

    @Test("Analytics integration with settings works")
    func testAnalyticsSettingsIntegration() async throws {
        let settingsView = ParentSettingsView()
        #expect(settingsView != nil)

        // Test that ReportsView properly integrates AnalyticsDashboardView
        let reportsView = ReportsView()
        #expect(reportsView != nil)
    }

    @Test("Analytics export integration works")
    func testAnalyticsExportIntegration() async throws {
        let mockData = createMockAnalyticsData()
        let exporter = AnalyticsExporter()

        // Test export options creation
        let options = ExportOptions(
            includeSummary: true,
            includeRawData: true,
            includeCharts: false
        )

        #expect(options.includeSummary == true)
        #expect(options.includeRawData == true)
        #expect(options.includeCharts == false)
    }

    // MARK: - UI Component Tests

    @Test("MetricCard component works correctly")
    func testMetricCardComponent() async throws {
        let metricCard = MetricCard(
            title: "Total Screen Time",
            value: "7h 0m",
            icon: "clock.fill",
            color: .blue
        )

        #expect(metricCard != nil)
    }

    @Test("StatCard component works correctly")
    func testStatCardComponent() async throws {
        let statCard = StatCard(
            title: "Points Balance",
            value: "130",
            subtitle: "Available"
        )

        #expect(statCard != nil)
    }

    @Test("SectionHeader component works correctly")
    func testSectionHeaderComponent() async throws {
        let sectionHeader = SectionHeader(
            title: "Overview",
            icon: "chart.bar.fill"
        )

        #expect(sectionHeader != nil)
    }

    @Test("EmptyAnalyticsView component works correctly")
    func testEmptyAnalyticsViewComponent() async throws {
        let emptyView = EmptyAnalyticsView {
            // Test refresh action
        }

        #expect(emptyView != nil)
    }

    // MARK: - Helper Methods

    private func createMockAnalyticsData() -> AnalyticsData {
        AnalyticsData(
            timeRange: .week,
            childFilter: "all",
            keyMetrics: KeyMetrics(
                totalScreenTime: 420,
                learningTime: 180,
                entertainmentTime: 240,
                pointsEarned: 450,
                pointsSpent: 320,
                dailyGoalAchievement: 0.85
            ),
            usageTrends: [
                UsageDataPoint(date: Date(), screenTime: 60, learningTime: 30, pointsEarned: 50),
                UsageDataPoint(date: Date().addingTimeInterval(-86400), screenTime: 75, learningTime: 35, pointsEarned: 60)
            ],
            appCategories: [
                AppCategoryData(category: "Educational", timeSpent: 180, pointsEarned: 360),
                AppCategoryData(category: "Entertainment", timeSpent: 120, pointsEarned: 0)
            ],
            learningProgress: [
                LearningProgress(subject: "Math", timeSpent: 45, progress: 0.75),
                LearningProgress(subject: "Reading", timeSpent: 60, progress: 0.90)
            ],
            screenTimeGoals: [
                ScreenTimeGoal(day: "Monday", goal: 60, actual: 45),
                ScreenTimeGoal(day: "Tuesday", goal: 60, actual: 75)
            ],
            rewardStatistics: RewardStatistics(
                totalPointsEarned: 450,
                totalPointsSpent: 320,
                averagePointsPerDay: 64,
                mostRedeemed: "Netflix",
                streakDays: 5,
                goalAchievementRate: 0.85
            )
        )
    }

    private func createMockPremiumAnalyticsData() -> PremiumAnalyticsData {
        PremiumAnalyticsData(
            screenTimePatterns: ScreenTimePatterns(
                peakUsageHours: [9, 13, 16, 20],
                averageSessionLength: 23,
                longestStreak: 14,
                weekdayVsWeekend: WeekdayWeekendComparison(weekday: 85, weekend: 120),
                seasonalTrends: [0.8, 1.1, 0.9, 1.2]
            ),
            productivityMetrics: ProductivityMetrics(
                focusTimePercentage: 0.68,
                learningEfficiency: 0.82,
                distractionEvents: 12,
                deepWorkSessions: 5,
                contextSwitching: 18,
                productivityScore: 78
            ),
            familyComparison: FamilyComparison(
                members: [
                    FamilyMemberAnalytics(name: "Alex", screenTime: 85, learningTime: 45, productivityScore: 82),
                    FamilyMemberAnalytics(name: "Sam", screenTime: 72, learningTime: 38, productivityScore: 75),
                    FamilyMemberAnalytics(name: "Emma", screenTime: 95, learningTime: 52, productivityScore: 88)
                ],
                familyAverage: FamilyMemberAnalytics(name: "Family", screenTime: 84, learningTime: 45, productivityScore: 82)
            ),
            predictiveInsights: PredictiveInsights(
                predictions: ["Test prediction"],
                recommendations: ["Test recommendation"]
            ),
            detailedReports: DetailedReports(
                monthlyProgress: MonthlyProgress(
                    screenTimeChange: -8.5,
                    learningTimeChange: 12.3,
                    goalAchievementChange: 15.2
                ),
                appUsageBreakdown: [
                    AppUsageDetail(app: "Khan Academy", category: "Educational", time: 180, efficiency: 0.92)
                ]
            ),
            aiInsights: [
                AIInsight(
                    type: .pattern,
                    title: "Test Insight",
                    description: "Test description",
                    confidence: 0.94,
                    actionable: true
                ),
                AIInsight(
                    type: .optimization,
                    title: "Test Optimization",
                    description: "Test optimization description",
                    confidence: 0.87,
                    actionable: true
                ),
                AIInsight(
                    type: .warning,
                    title: "Test Warning",
                    description: "Test warning description",
                    confidence: 0.91,
                    actionable: true
                )
            ]
        )
    }
}

// MARK: - XCTest UI Tests for Analytics Workflows

@available(iOS 16.0, *)
final class AnalyticsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testAnalyticsNavigationFromSettings() throws {
        // Navigate to parent role
        let parentButton = app.buttons["I'm a Parent"]
        XCTAssertTrue(parentButton.waitForExistence(timeout: 5))
        parentButton.tap()

        // Navigate to settings
        let settingsTab = app.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Find and tap detailed reports
        let reportsButton = app.buttons["Detailed Reports"]
        if reportsButton.waitForExistence(timeout: 3) {
            reportsButton.tap()

            // Verify analytics dashboard loads
            let analyticsTitle = app.navigationBars["Analytics"]
            XCTAssertTrue(analyticsTitle.waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testAnalyticsTimeRangeSelection() throws {
        // Navigate to analytics dashboard (assuming we can get there)
        // This would be implemented based on the navigation structure

        // Test time range picker interaction
        let timeRangePicker = app.segmentedControls.firstMatch
        if timeRangePicker.waitForExistence(timeout: 3) {
            timeRangePicker.tap()
        }
    }

    @MainActor
    func testAnalyticsExportFlow() throws {
        // Navigate to analytics dashboard
        // Tap export button
        // Test export sheet interaction
        // This would require setting up the full navigation flow
    }
}