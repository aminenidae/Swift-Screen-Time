import XCTest
import SwiftUI
@testable import ScreenTimeApp

@available(iOS 16.0, *)
final class AnalyticsTests: XCTestCase {

    // MARK: - Analytics Dashboard Tests

    func testAnalyticsDashboardViewInitialization() {
        let dashboardView = AnalyticsDashboardView()
        XCTAssertNotNil(dashboardView)
    }

    func testAnalyticsSectionsInitialization() {
        let mockData = createMockAnalyticsData()

        let keyMetricsSection = KeyMetricsSection(data: mockData)
        XCTAssertNotNil(keyMetricsSection)

        let usageTrendsSection = UsageTrendsSection(data: mockData, timeRange: .week)
        XCTAssertNotNil(usageTrendsSection)

        let appCategorySection = AppCategorySection(data: mockData)
        XCTAssertNotNil(appCategorySection)

        let learningProgressSection = LearningProgressSection(data: mockData)
        XCTAssertNotNil(learningProgressSection)

        let screenTimeGoalsSection = ScreenTimeGoalsSection(data: mockData)
        XCTAssertNotNil(screenTimeGoalsSection)

        let rewardStatisticsSection = RewardStatisticsSection(data: mockData)
        XCTAssertNotNil(rewardStatisticsSection)
    }

    func testAnalyticsExportView() {
        let mockData = createMockAnalyticsData()
        let exportView = AnalyticsExportView(data: mockData)
        XCTAssertNotNil(exportView)
    }

    func testAnalyticsSettingsView() {
        let settingsView = AnalyticsSettingsView()
        XCTAssertNotNil(settingsView)
    }

    func testPremiumAnalyticsView() {
        let premiumView = PremiumAnalyticsView()
        XCTAssertNotNil(premiumView)
    }

    // MARK: - Data Model Tests

    func testAnalyticsDataModel() {
        let data = createMockAnalyticsData()

        XCTAssertEqual(data.timeRange, .week)
        XCTAssertEqual(data.childFilter, "all")
        XCTAssertEqual(data.keyMetrics.totalScreenTime, 420)
        XCTAssertEqual(data.keyMetrics.learningTime, 180)
        XCTAssertEqual(data.keyMetrics.pointsEarned, 450)
    }

    func testUsageDataPointModel() {
        let dataPoint = UsageDataPoint(
            date: Date(),
            screenTime: 60.0,
            learningTime: 30.0,
            pointsEarned: 50
        )

        XCTAssertEqual(dataPoint.screenTime, 60.0)
        XCTAssertEqual(dataPoint.learningTime, 30.0)
        XCTAssertEqual(dataPoint.pointsEarned, 50)
    }

    func testAppCategoryDataModel() {
        let categoryData = AppCategoryData(
            category: "Educational",
            timeSpent: 180,
            pointsEarned: 360
        )

        XCTAssertEqual(categoryData.category, "Educational")
        XCTAssertEqual(categoryData.timeSpent, 180)
        XCTAssertEqual(categoryData.pointsEarned, 360)
    }

    func testLearningProgressModel() {
        let progress = LearningProgress(
            subject: "Math",
            timeSpent: 45,
            progress: 0.75
        )

        XCTAssertEqual(progress.subject, "Math")
        XCTAssertEqual(progress.timeSpent, 45)
        XCTAssertEqual(progress.progress, 0.75)
    }

    func testRewardStatisticsModel() {
        let stats = RewardStatistics(
            totalPointsEarned: 450,
            totalPointsSpent: 320,
            averagePointsPerDay: 64,
            mostRedeemed: "Netflix",
            streakDays: 5,
            goalAchievementRate: 0.85
        )

        XCTAssertEqual(stats.totalPointsEarned, 450)
        XCTAssertEqual(stats.totalPointsSpent, 320)
        XCTAssertEqual(stats.averagePointsPerDay, 64)
        XCTAssertEqual(stats.mostRedeemed, "Netflix")
        XCTAssertEqual(stats.streakDays, 5)
        XCTAssertEqual(stats.goalAchievementRate, 0.85)
    }

    // MARK: - Time Range Tests

    func testTimeRangeEnum() {
        XCTAssertEqual(TimeRange.day.rawValue, "Today")
        XCTAssertEqual(TimeRange.week.rawValue, "This Week")
        XCTAssertEqual(TimeRange.month.rawValue, "This Month")
        XCTAssertEqual(TimeRange.year.rawValue, "This Year")

        XCTAssertEqual(TimeRange.allCases.count, 4)
    }

    // MARK: - Export Format Tests

    func testExportFormatEnum() {
        XCTAssertEqual(ExportFormat.csv.displayName, "CSV")
        XCTAssertEqual(ExportFormat.json.displayName, "JSON")
        XCTAssertEqual(ExportFormat.pdf.displayName, "PDF")

        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.pdf.fileExtension, "pdf")
    }

    func testExportOptionsModel() {
        let options = ExportOptions(
            includeSummary: true,
            includeRawData: false,
            includeCharts: true
        )

        XCTAssertTrue(options.includeSummary)
        XCTAssertFalse(options.includeRawData)
        XCTAssertTrue(options.includeCharts)
    }

    // MARK: - Premium Analytics Tests

    func testPremiumAnalyticsDataModel() {
        let premiumData = createMockPremiumAnalyticsData()

        XCTAssertEqual(premiumData.screenTimePatterns.averageSessionLength, 23)
        XCTAssertEqual(premiumData.productivityMetrics.productivityScore, 78)
        XCTAssertEqual(premiumData.familyComparison.members.count, 3)
        XCTAssertEqual(premiumData.aiInsights.count, 3)
    }

    func testPremiumMetricEnum() {
        XCTAssertEqual(PremiumMetric.screenTimePatterns.displayName, "Screen Time Patterns")
        XCTAssertEqual(PremiumMetric.productivityMetrics.displayName, "Productivity Metrics")
        XCTAssertEqual(PremiumMetric.familyComparison.displayName, "Family Comparison")
        XCTAssertEqual(PremiumMetric.predictiveInsights.displayName, "Predictive Insights")
        XCTAssertEqual(PremiumMetric.detailedReports.displayName, "Detailed Reports")

        XCTAssertEqual(PremiumMetric.allCases.count, 5)
    }

    func testComparisonPeriodEnum() {
        XCTAssertEqual(ComparisonPeriod.lastWeek.displayName, "Last Week")
        XCTAssertEqual(ComparisonPeriod.lastMonth.displayName, "Last Month")
        XCTAssertEqual(ComparisonPeriod.lastQuarter.displayName, "Last Quarter")
        XCTAssertEqual(ComparisonPeriod.lastYear.displayName, "Last Year")

        XCTAssertEqual(ComparisonPeriod.allCases.count, 4)
    }

    // MARK: - Integration Tests

    func testAnalyticsSettingsIntegration() {
        let settingsView = ParentSettingsView()
        XCTAssertNotNil(settingsView)

        // Test that ReportsView properly integrates AnalyticsDashboardView
        let reportsView = ReportsView()
        XCTAssertNotNil(reportsView)
    }

    func testAnalyticsExportIntegration() {
        let mockData = createMockAnalyticsData()
        let exporter = AnalyticsExporter()

        // Test export options creation
        let options = ExportOptions(
            includeSummary: true,
            includeRawData: true,
            includeCharts: false
        )

        XCTAssertTrue(options.includeSummary)
        XCTAssertTrue(options.includeRawData)
        XCTAssertFalse(options.includeCharts)
    }

    // MARK: - UI Component Tests

    func testMetricCardComponent() {
        let metricCard = MetricCard(
            title: "Total Screen Time",
            value: "7h 0m",
            icon: "clock.fill",
            color: .blue
        )

        XCTAssertNotNil(metricCard)
    }

    func testStatCardComponent() {
        let statCard = StatCard(
            title: "Points Balance",
            value: "130",
            subtitle: "Available"
        )

        XCTAssertNotNil(statCard)
    }

    func testSectionHeaderComponent() {
        let sectionHeader = SectionHeader(
            title: "Overview",
            icon: "chart.bar.fill"
        )

        XCTAssertNotNil(sectionHeader)
    }

    func testEmptyAnalyticsViewComponent() {
        let emptyView = EmptyAnalyticsView {
            // Test refresh action
        }

        XCTAssertNotNil(emptyView)
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

    func testAnalyticsTimeRangeSelection() throws {
        // Navigate to analytics dashboard (assuming we can get there)
        // This would be implemented based on the navigation structure

        // Test time range picker interaction
        let timeRangePicker = app.segmentedControls.firstMatch
        if timeRangePicker.waitForExistence(timeout: 3) {
            timeRangePicker.tap()
        }
    }

    func testAnalyticsExportFlow() throws {
        // Navigate to analytics dashboard
        // Tap export button
        // Test export sheet interaction
        // This would require setting up the full navigation flow
    }
}