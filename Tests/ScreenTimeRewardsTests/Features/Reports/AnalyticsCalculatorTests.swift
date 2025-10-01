import XCTest
@testable import ScreenTimeRewards
import SharedModels

final class AnalyticsCalculatorTests: XCTestCase {

    // MARK: - Report Summary Tests

    func testCalculateReportSummaryBasic() {
        let sessions = createTestSessions()
        let transactions = createTestTransactions()

        let summary = AnalyticsCalculator.calculateReportSummary(
            sessions: sessions,
            transactions: transactions
        )

        XCTAssertEqual(summary.totalTimeMinutes, 90) // 3 sessions of 30 minutes each
        XCTAssertEqual(summary.totalPointsEarned, 150) // Sum of positive transactions
        XCTAssertEqual(summary.learningTimeMinutes, 60) // 2 learning sessions
        XCTAssertEqual(summary.rewardTimeMinutes, 30) // 1 reward session
        XCTAssertEqual(summary.totalSessions, 3)
        XCTAssertEqual(summary.averageSessionMinutes, 30) // 90 / 3
        XCTAssertEqual(summary.pointsPerMinute, 150.0 / 90.0, accuracy: 0.01)
    }

    func testCalculateReportSummaryEmptyData() {
        let summary = AnalyticsCalculator.calculateReportSummary(
            sessions: [],
            transactions: []
        )

        XCTAssertEqual(summary.totalTimeMinutes, 0)
        XCTAssertEqual(summary.totalPointsEarned, 0)
        XCTAssertEqual(summary.learningTimeMinutes, 0)
        XCTAssertEqual(summary.rewardTimeMinutes, 0)
        XCTAssertEqual(summary.totalSessions, 0)
        XCTAssertEqual(summary.averageSessionMinutes, 0)
        XCTAssertEqual(summary.pointsPerMinute, 0.0)
    }

    func testCalculateReportSummaryNegativeTransactions() {
        let sessions = createTestSessions()
        let transactions = [
            PointTransaction(id: "1", childProfileID: "child1", points: 100, reason: "earned", timestamp: Date()),
            PointTransaction(id: "2", childProfileID: "child1", points: -50, reason: "spent", timestamp: Date()),
            PointTransaction(id: "3", childProfileID: "child1", points: 75, reason: "earned", timestamp: Date())
        ]

        let summary = AnalyticsCalculator.calculateReportSummary(
            sessions: sessions,
            transactions: transactions
        )

        // Should only count positive transactions for earned points
        XCTAssertEqual(summary.totalPointsEarned, 175) // 100 + 75, ignoring -50
    }

    // MARK: - Category Breakdown Tests

    func testCalculateCategoryBreakdown() {
        let sessions = createTestSessions()
        let transactions = createTestTransactions()
        let categorizations = createTestCategorizations()

        let breakdown = AnalyticsCalculator.calculateCategoryBreakdown(
            sessions: sessions,
            transactions: transactions,
            categorizations: categorizations
        )

        XCTAssertEqual(breakdown.learningApps.count, 2) // Books and Duolingo
        XCTAssertEqual(breakdown.rewardApps.count, 1) // Game
        XCTAssertEqual(breakdown.learningPercentage, 66.67, accuracy: 0.01) // 60 / 90 * 100
        XCTAssertEqual(breakdown.rewardPercentage, 33.33, accuracy: 0.01) // 30 / 90 * 100

        // Check that apps are sorted by total time
        XCTAssertGreaterThanOrEqual(breakdown.learningApps[0].totalMinutes, breakdown.learningApps[1].totalMinutes)
    }

    func testCalculateCategoryBreakdownEmptyData() {
        let breakdown = AnalyticsCalculator.calculateCategoryBreakdown(
            sessions: [],
            transactions: [],
            categorizations: []
        )

        XCTAssertEqual(breakdown.learningApps.count, 0)
        XCTAssertEqual(breakdown.rewardApps.count, 0)
        XCTAssertEqual(breakdown.learningPercentage, 0)
        XCTAssertEqual(breakdown.rewardPercentage, 0)
    }

    // MARK: - Trend Analysis Tests

    func testCalculateTrendAnalysis() {
        let sessions = createTestSessionsOverMultipleDays()
        let transactions = createTestTransactionsOverMultipleDays()
        let dateRange = DateRange(
            start: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            end: Date()
        )

        let trends = AnalyticsCalculator.calculateTrendAnalysis(
            sessions: sessions,
            transactions: transactions,
            dateRange: dateRange
        )

        XCTAssertEqual(trends.dailyUsage.count, 7) // 7 days
        XCTAssertNotNil(trends.weeklyComparison)
        XCTAssertNotNil(trends.streakData)
        XCTAssertFalse(trends.peakUsageHours.isEmpty)
    }

    func testCalculateDailyUsage() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let sessions = [
            UsageSession(
                id: "1",
                childProfileID: "child1",
                appBundleID: "com.test.app1",
                category: .learning,
                startTime: today.addingTimeInterval(3600), // 1 hour into today
                endTime: today.addingTimeInterval(5400), // 30 minutes later
                duration: 1800
            ),
            UsageSession(
                id: "2",
                childProfileID: "child1",
                appBundleID: "com.test.app2",
                category: .reward,
                startTime: yesterday.addingTimeInterval(3600),
                endTime: yesterday.addingTimeInterval(5400),
                duration: 1800
            )
        ]

        let transactions = [
            PointTransaction(id: "1", childProfileID: "child1", points: 60, reason: "learning", timestamp: today.addingTimeInterval(4000)),
            PointTransaction(id: "2", childProfileID: "child1", points: 0, reason: "reward", timestamp: yesterday.addingTimeInterval(4000))
        ]

        let dateRange = DateRange(start: yesterday, end: today.addingTimeInterval(24 * 60 * 60))

        let trends = AnalyticsCalculator.calculateTrendAnalysis(
            sessions: sessions,
            transactions: transactions,
            dateRange: dateRange
        )

        XCTAssertEqual(trends.dailyUsage.count, 2)

        // Check yesterday's data
        let yesterdayData = trends.dailyUsage.first { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }
        XCTAssertNotNil(yesterdayData)
        XCTAssertEqual(yesterdayData?.totalMinutes, 30)
        XCTAssertEqual(yesterdayData?.learningMinutes, 0)
        XCTAssertEqual(yesterdayData?.rewardMinutes, 30)

        // Check today's data
        let todayData = trends.dailyUsage.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        XCTAssertNotNil(todayData)
        XCTAssertEqual(todayData?.totalMinutes, 30)
        XCTAssertEqual(todayData?.learningMinutes, 30)
        XCTAssertEqual(todayData?.rewardMinutes, 0)
        XCTAssertEqual(todayData?.pointsEarned, 60)
    }

    func testCalculateWeeklyComparison() {
        let sessions = createTestSessionsForWeeklyComparison()

        let trends = AnalyticsCalculator.calculateTrendAnalysis(
            sessions: sessions,
            transactions: [],
            dateRange: DateRange(start: Date().addingTimeInterval(-14 * 24 * 60 * 60), end: Date())
        )

        let comparison = trends.weeklyComparison
        XCTAssertGreaterThan(comparison.currentWeekMinutes, 0)
        XCTAssertGreaterThan(comparison.previousWeekMinutes, 0)

        // Test trend direction logic
        if comparison.currentWeekMinutes > comparison.previousWeekMinutes {
            let expectedChange = Double(comparison.currentWeekMinutes - comparison.previousWeekMinutes) / Double(comparison.previousWeekMinutes) * 100
            XCTAssertEqual(comparison.percentageChange, expectedChange, accuracy: 0.01)

            if comparison.percentageChange > 5 {
                XCTAssertEqual(comparison.trendDirection, .up)
            } else {
                XCTAssertEqual(comparison.trendDirection, .stable)
            }
        }
    }

    func testCalculateStreakData() {
        let sessions = createTestSessionsForStreakCalculation()

        let trends = AnalyticsCalculator.calculateTrendAnalysis(
            sessions: sessions,
            transactions: [],
            dateRange: DateRange(start: Date().addingTimeInterval(-30 * 24 * 60 * 60), end: Date())
        )

        let streakData = trends.streakData
        XCTAssertGreaterThanOrEqual(streakData.currentLearningStreak, 0)
        XCTAssertGreaterThanOrEqual(streakData.longestLearningStreak, streakData.currentLearningStreak)
        XCTAssertGreaterThanOrEqual(streakData.currentBalancedStreak, 0)
        XCTAssertGreaterThanOrEqual(streakData.longestBalancedStreak, streakData.currentBalancedStreak)
    }

    func testCalculatePeakUsageHours() {
        let sessions = createTestSessionsWithVariedTimes()

        let trends = AnalyticsCalculator.calculateTrendAnalysis(
            sessions: sessions,
            transactions: [],
            dateRange: DateRange(start: Date().addingTimeInterval(-7 * 24 * 60 * 60), end: Date())
        )

        let peakHours = trends.peakUsageHours
        XCTAssertLessThanOrEqual(peakHours.count, 3) // Should return top 3 peak hours
        XCTAssertTrue(peakHours.allSatisfy { $0 >= 0 && $0 <= 23 }) // Valid hour range

        // Verify hours are sorted
        if peakHours.count > 1 {
            XCTAssertEqual(peakHours, peakHours.sorted())
        }
    }

    // MARK: - App Usage Details Tests

    func testCalculateAppUsageDetails() {
        let sessions = createTestSessions()
        let transactions = createTestTransactions()
        let categorizations = createTestCategorizations()

        let appDetails = AnalyticsCalculator.calculateAppUsageDetails(
            sessions: sessions,
            transactions: transactions,
            categorizations: categorizations
        )

        XCTAssertEqual(appDetails.count, 3) // 3 different apps
        XCTAssertTrue(appDetails.allSatisfy { $0.totalMinutes > 0 })
        XCTAssertTrue(appDetails.allSatisfy { $0.totalSessions > 0 })

        // Verify sorting by total time (descending)
        for i in 0..<(appDetails.count - 1) {
            XCTAssertGreaterThanOrEqual(appDetails[i].totalMinutes, appDetails[i + 1].totalMinutes)
        }

        // Check specific app data
        let booksApp = appDetails.first { $0.appBundleID == "com.apple.books" }
        XCTAssertNotNil(booksApp)
        XCTAssertEqual(booksApp?.category, .learning)
        XCTAssertGreaterThan(booksApp?.totalMinutes ?? 0, 0)
    }

    func testCalculateAppUsageDetailsEmptyData() {
        let appDetails = AnalyticsCalculator.calculateAppUsageDetails(
            sessions: [],
            transactions: [],
            categorizations: []
        )

        XCTAssertEqual(appDetails.count, 0)
    }

    // MARK: - Date Range Utilities Tests

    func testCreateCustomDateRange() {
        let start = Date()
        let end = Date().addingTimeInterval(24 * 60 * 60) // 1 day later

        let dateRange = AnalyticsCalculator.createCustomDateRange(start: start, end: end)

        let calendar = Calendar.current
        let expectedStart = calendar.startOfDay(for: start)
        let expectedEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end))!

        XCTAssertEqual(dateRange.start, expectedStart)
        XCTAssertEqual(dateRange.end, expectedEnd)
    }

    func testIsDateInRange() {
        let start = Date()
        let end = Date().addingTimeInterval(24 * 60 * 60)
        let range = DateRange(start: start, end: end)

        let dateInRange = Date().addingTimeInterval(12 * 60 * 60) // 12 hours later
        let dateBeforeRange = Date().addingTimeInterval(-12 * 60 * 60) // 12 hours before
        let dateAfterRange = Date().addingTimeInterval(36 * 60 * 60) // 36 hours later

        XCTAssertTrue(AnalyticsCalculator.isDateInRange(dateInRange, range: range))
        XCTAssertFalse(AnalyticsCalculator.isDateInRange(dateBeforeRange, range: range))
        XCTAssertFalse(AnalyticsCalculator.isDateInRange(dateAfterRange, range: range))
    }

    // MARK: - Edge Cases Tests

    func testEdgeCaseEmptyTransactions() {
        let sessions = createTestSessions()

        let summary = AnalyticsCalculator.calculateReportSummary(
            sessions: sessions,
            transactions: []
        )

        XCTAssertEqual(summary.totalPointsEarned, 0)
        XCTAssertEqual(summary.pointsPerMinute, 0.0)
    }

    func testEdgeCaseSingleSessionSingleDay() {
        let session = UsageSession(
            id: "1",
            childProfileID: "child1",
            appBundleID: "com.test.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800
        )

        let trends = AnalyticsCalculator.calculateTrendAnalysis(
            sessions: [session],
            transactions: [],
            dateRange: DateRange(start: Date().addingTimeInterval(-24 * 60 * 60), end: Date().addingTimeInterval(24 * 60 * 60))
        )

        XCTAssertGreaterThan(trends.dailyUsage.count, 0)
        XCTAssertEqual(trends.peakUsageHours.count, 1)
    }

    func testEdgeCaseDateBoundaryCalculations() {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())

        // Session that crosses midnight
        let session = UsageSession(
            id: "1",
            childProfileID: "child1",
            appBundleID: "com.test.app",
            category: .learning,
            startTime: midnight.addingTimeInterval(-1800), // 30 minutes before midnight
            endTime: midnight.addingTimeInterval(1800), // 30 minutes after midnight
            duration: 3600
        )

        let dateRange = DateRange(
            start: midnight.addingTimeInterval(-24 * 60 * 60),
            end: midnight.addingTimeInterval(24 * 60 * 60)
        )

        let trends = AnalyticsCalculator.calculateTrendAnalysis(
            sessions: [session],
            transactions: [],
            dateRange: dateRange
        )

        // Session should be counted in the day it started
        let sessionDay = trends.dailyUsage.first {
            calendar.isDate($0.date, inSameDayAs: session.startTime)
        }
        XCTAssertNotNil(sessionDay)
        XCTAssertGreaterThan(sessionDay?.totalMinutes ?? 0, 0)
    }

    // MARK: - Helper Methods

    private func createTestSessions() -> [UsageSession] {
        let now = Date()
        return [
            UsageSession(
                id: "1",
                childProfileID: "child1",
                appBundleID: "com.apple.books",
                category: .learning,
                startTime: now.addingTimeInterval(-3600),
                endTime: now.addingTimeInterval(-1800),
                duration: 1800 // 30 minutes
            ),
            UsageSession(
                id: "2",
                childProfileID: "child1",
                appBundleID: "com.duolingo.app",
                category: .learning,
                startTime: now.addingTimeInterval(-7200),
                endTime: now.addingTimeInterval(-5400),
                duration: 1800 // 30 minutes
            ),
            UsageSession(
                id: "3",
                childProfileID: "child1",
                appBundleID: "com.game.app",
                category: .reward,
                startTime: now.addingTimeInterval(-10800),
                endTime: now.addingTimeInterval(-9000),
                duration: 1800 // 30 minutes
            )
        ]
    }

    private func createTestTransactions() -> [PointTransaction] {
        let now = Date()
        return [
            PointTransaction(
                id: "1",
                childProfileID: "child1",
                points: 60,
                reason: "Learning session",
                timestamp: now.addingTimeInterval(-3000)
            ),
            PointTransaction(
                id: "2",
                childProfileID: "child1",
                points: 90,
                reason: "Learning session",
                timestamp: now.addingTimeInterval(-6600)
            )
        ]
    }

    private func createTestCategorizations() -> [AppCategorization] {
        return [
            AppCategorization(
                id: "1",
                appBundleID: "com.apple.books",
                category: .learning,
                childProfileID: "child1",
                pointsPerHour: 120
            ),
            AppCategorization(
                id: "2",
                appBundleID: "com.duolingo.app",
                category: .learning,
                childProfileID: "child1",
                pointsPerHour: 180
            ),
            AppCategorization(
                id: "3",
                appBundleID: "com.game.app",
                category: .reward,
                childProfileID: "child1",
                pointsPerHour: 0
            )
        ]
    }

    private func createTestSessionsOverMultipleDays() -> [UsageSession] {
        var sessions: [UsageSession] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: -i, to: today)!
            sessions.append(
                UsageSession(
                    id: "session_\(i)",
                    childProfileID: "child1",
                    appBundleID: "com.test.app",
                    category: i % 2 == 0 ? .learning : .reward,
                    startTime: dayStart.addingTimeInterval(3600 * TimeInterval(i + 10)), // Different hours
                    endTime: dayStart.addingTimeInterval(3600 * TimeInterval(i + 10) + 1800),
                    duration: 1800
                )
            )
        }

        return sessions
    }

    private func createTestTransactionsOverMultipleDays() -> [PointTransaction] {
        var transactions: [PointTransaction] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: -i, to: today)!
            transactions.append(
                PointTransaction(
                    id: "transaction_\(i)",
                    childProfileID: "child1",
                    points: 30 + (i * 10),
                    reason: "Daily points",
                    timestamp: dayStart.addingTimeInterval(3600 * TimeInterval(i + 10))
                )
            )
        }

        return transactions
    }

    private func createTestSessionsForWeeklyComparison() -> [UsageSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!

        return [
            // Current week sessions
            UsageSession(
                id: "current1",
                childProfileID: "child1",
                appBundleID: "com.test.app",
                category: .learning,
                startTime: currentWeekStart.addingTimeInterval(3600),
                endTime: currentWeekStart.addingTimeInterval(5400),
                duration: 1800
            ),
            UsageSession(
                id: "current2",
                childProfileID: "child1",
                appBundleID: "com.test.app",
                category: .learning,
                startTime: currentWeekStart.addingTimeInterval(24 * 3600),
                endTime: currentWeekStart.addingTimeInterval(24 * 3600 + 1800),
                duration: 1800
            ),
            // Previous week sessions
            UsageSession(
                id: "previous1",
                childProfileID: "child1",
                appBundleID: "com.test.app",
                category: .learning,
                startTime: previousWeekStart.addingTimeInterval(3600),
                endTime: previousWeekStart.addingTimeInterval(5400),
                duration: 1800
            )
        ]
    }

    private func createTestSessionsForStreakCalculation() -> [UsageSession] {
        var sessions: [UsageSession] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create sessions for consecutive days
        for i in 0..<5 {
            let dayStart = calendar.date(byAdding: .day, value: -i, to: today)!

            // Learning session
            sessions.append(
                UsageSession(
                    id: "learning_\(i)",
                    childProfileID: "child1",
                    appBundleID: "com.learning.app",
                    category: .learning,
                    startTime: dayStart.addingTimeInterval(3600),
                    endTime: dayStart.addingTimeInterval(5400),
                    duration: 1800
                )
            )

            // Reward session (for balanced streak) on alternating days
            if i % 2 == 0 {
                sessions.append(
                    UsageSession(
                        id: "reward_\(i)",
                        childProfileID: "child1",
                        appBundleID: "com.game.app",
                        category: .reward,
                        startTime: dayStart.addingTimeInterval(7200),
                        endTime: dayStart.addingTimeInterval(9000),
                        duration: 1800
                    )
                )
            }
        }

        return sessions
    }

    private func createTestSessionsWithVariedTimes() -> [UsageSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return [
            // 9 AM session (should be peak)
            UsageSession(
                id: "morning1",
                childProfileID: "child1",
                appBundleID: "com.test.app",
                category: .learning,
                startTime: today.addingTimeInterval(9 * 3600),
                endTime: today.addingTimeInterval(9 * 3600 + 3600),
                duration: 3600
            ),
            // Another 9 AM session different day
            UsageSession(
                id: "morning2",
                childProfileID: "child1",
                appBundleID: "com.test.app",
                category: .learning,
                startTime: today.addingTimeInterval(-24 * 3600 + 9 * 3600),
                endTime: today.addingTimeInterval(-24 * 3600 + 9 * 3600 + 3600),
                duration: 3600
            ),
            // 3 PM session (should be peak)
            UsageSession(
                id: "afternoon",
                childProfileID: "child1",
                appBundleID: "com.test.app",
                category: .reward,
                startTime: today.addingTimeInterval(15 * 3600),
                endTime: today.addingTimeInterval(15 * 3600 + 1800),
                duration: 1800
            ),
            // 11 PM session (less usage)
            UsageSession(
                id: "evening",
                childProfileID: "child1",
                appBundleID: "com.test.app",
                category: .learning,
                startTime: today.addingTimeInterval(23 * 3600),
                endTime: today.addingTimeInterval(23 * 3600 + 900),
                duration: 900
            )
        ]
    }
}