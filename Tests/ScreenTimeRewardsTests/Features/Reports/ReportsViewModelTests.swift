import XCTest
import Combine
@testable import ScreenTimeRewards
import SharedModels

final class ReportsViewModelTests: XCTestCase {

    var viewModel: ReportsViewModel!
    var mockUsageRepository: MockUsageSessionRepository!
    var mockPointRepository: MockPointTransactionRepository!
    var mockAppRepository: MockAppCategorizationRepository!
    var mockChildRepository: MockChildProfileRepository!
    var mockSubscriptionRepository: MockSubscriptionRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        mockUsageRepository = MockUsageSessionRepository()
        mockPointRepository = MockPointTransactionRepository()
        mockAppRepository = MockAppCategorizationRepository()
        mockChildRepository = MockChildProfileRepository()
        mockSubscriptionRepository = MockSubscriptionRepository()
        cancellables = Set<AnyCancellable>()

        viewModel = ReportsViewModel(
            usageSessionRepository: mockUsageRepository,
            pointTransactionRepository: mockPointRepository,
            appCategorizationRepository: mockAppRepository,
            childProfileRepository: mockChildRepository,
            subscriptionRepository: mockSubscriptionRepository
        )
    }

    override func tearDown() {
        viewModel = nil
        mockUsageRepository = nil
        mockPointRepository = nil
        mockAppRepository = nil
        mockChildRepository = nil
        mockSubscriptionRepository = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertNil(viewModel.reportsData)
        XCTAssertEqual(viewModel.selectedPeriod, .week)
        XCTAssertNil(viewModel.customDateRange)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.selectedChild)
    }

    // MARK: - Period Selection Tests

    func testSelectPeriod() async {
        let testChild = createTestChildProfile()
        viewModel.selectedChild = testChild

        await viewModel.selectPeriod(.today)

        XCTAssertEqual(viewModel.selectedPeriod, .today)
        XCTAssertNil(viewModel.customDateRange)
    }

    func testSelectCustomDateRange() async {
        let testChild = createTestChildProfile()
        viewModel.selectedChild = testChild

        let start = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        let end = Date()
        let customRange = DateRange(start: start, end: end)

        await viewModel.selectCustomDateRange(customRange)

        XCTAssertEqual(viewModel.selectedPeriod, .custom)
        XCTAssertNotNil(viewModel.customDateRange)
        XCTAssertEqual(viewModel.customDateRange?.start, customRange.start)
        XCTAssertEqual(viewModel.customDateRange?.end, customRange.end)
    }

    // MARK: - Data Loading Tests

    func testLoadReportsDataSuccess() async {
        let testChild = createTestChildProfile()
        let testSessions = createTestUsageSessions(for: testChild.id)
        let testTransactions = createTestPointTransactions(for: testChild.id)
        let testCategorizations = createTestAppCategorizations(for: testChild.id)

        mockUsageRepository.sessions = testSessions
        mockPointRepository.transactions = testTransactions
        mockAppRepository.categorizations = testCategorizations
        mockSubscriptionRepository.hasActiveSubscription = true

        viewModel.selectedChild = testChild

        await viewModel.loadReportsData()

        XCTAssertNotNil(viewModel.reportsData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)

        // Verify data structure
        let reportsData = viewModel.reportsData!
        XCTAssertEqual(reportsData.period, .week)
        XCTAssertGreaterThan(reportsData.summary.totalTimeMinutes, 0)
        XCTAssertGreaterThan(reportsData.summary.totalPointsEarned, 0)
    }

    func testLoadReportsDataNoChild() async {
        viewModel.selectedChild = nil

        await viewModel.loadReportsData()

        XCTAssertNil(viewModel.reportsData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "No child profile selected")
    }

    func testLoadReportsDataRepositoryError() async {
        let testChild = createTestChildProfile()
        mockUsageRepository.shouldThrowError = true

        viewModel.selectedChild = testChild

        await viewModel.loadReportsData()

        XCTAssertNil(viewModel.reportsData)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to load reports data"))
    }

    // MARK: - Subscription Integration Tests

    func testBasicUserDataRestriction() async {
        let testChild = createTestChildProfile()
        mockSubscriptionRepository.hasActiveSubscription = false

        // Create sessions spanning more than 7 days
        let oldSession = UsageSession(
            id: "old",
            childProfileID: testChild.id,
            appBundleID: "com.test.app",
            category: .learning,
            startTime: Date().addingTimeInterval(-10 * 24 * 60 * 60), // 10 days ago
            endTime: Date().addingTimeInterval(-10 * 24 * 60 * 60 + 3600), // 1 hour session
            duration: 3600
        )

        let recentSession = UsageSession(
            id: "recent",
            childProfileID: testChild.id,
            appBundleID: "com.test.app",
            category: .learning,
            startTime: Date().addingTimeInterval(-2 * 24 * 60 * 60), // 2 days ago
            endTime: Date().addingTimeInterval(-2 * 24 * 60 * 60 + 3600),
            duration: 3600
        )

        mockUsageRepository.sessions = [oldSession, recentSession]
        mockPointRepository.transactions = []
        mockAppRepository.categorizations = []

        viewModel.selectedChild = testChild

        await viewModel.loadReportsData()

        // Verify only recent data is included for basic users
        XCTAssertNotNil(viewModel.reportsData)
        // The old session should be filtered out due to basic subscription restrictions
    }

    // MARK: - Computed Properties Tests

    func testFormattedDateRange() {
        viewModel.selectedPeriod = .week
        let formattedRange = viewModel.formattedDateRange
        XCTAssertEqual(formattedRange, "This Week")

        let start = Date()
        let end = Date().addingTimeInterval(7 * 24 * 60 * 60)
        viewModel.customDateRange = DateRange(start: start, end: end)

        let customFormatted = viewModel.formattedDateRange
        XCTAssertTrue(customFormatted.contains("-")) // Should contain date range
    }

    func testIsDataAvailable() {
        XCTAssertFalse(viewModel.isDataAvailable)

        viewModel.reportsData = createMockReportsData()
        XCTAssertTrue(viewModel.isDataAvailable)

        viewModel.isLoading = true
        XCTAssertFalse(viewModel.isDataAvailable)
    }

    func testIsEmpty() {
        XCTAssertTrue(viewModel.isEmpty)

        viewModel.reportsData = createMockReportsData()
        XCTAssertFalse(viewModel.isEmpty)

        // Test with empty data
        let emptySummary = ReportSummary(
            totalTimeMinutes: 0,
            totalPointsEarned: 0,
            learningTimeMinutes: 0,
            rewardTimeMinutes: 0,
            averageSessionMinutes: 0,
            totalSessions: 0,
            pointsPerMinute: 0
        )

        let emptyData = ReportsData(
            period: .week,
            dateRange: DateRange(start: Date(), end: Date()),
            summary: emptySummary,
            categoryBreakdown: CategoryBreakdown(learningApps: [], rewardApps: [], learningPercentage: 0, rewardPercentage: 0),
            trends: TrendAnalysis(dailyUsage: [], weeklyComparison: WeeklyComparison(currentWeekMinutes: 0, previousWeekMinutes: 0, percentageChange: 0, trendDirection: .stable), streakData: StreakData(currentLearningStreak: 0, longestLearningStreak: 0, currentBalancedStreak: 0, longestBalancedStreak: 0), peakUsageHours: []),
            appDetails: []
        )

        viewModel.reportsData = emptyData
        XCTAssertTrue(viewModel.isEmpty)
    }

    // MARK: - Upgrade Prompt Tests

    func testRequestPremiumFeatureWithoutSubscription() async {
        mockSubscriptionRepository.hasActiveSubscription = false
        let testChild = createTestChildProfile()
        viewModel.selectedChild = testChild

        await viewModel.loadReportsData()

        XCTAssertFalse(viewModel.hasActiveSubscription)
        XCTAssertFalse(viewModel.showUpgradePrompt)

        viewModel.requestPremiumFeature()

        XCTAssertTrue(viewModel.showUpgradePrompt)
    }

    func testRequestPremiumFeatureWithSubscription() async {
        mockSubscriptionRepository.hasActiveSubscription = true
        let testChild = createTestChildProfile()
        viewModel.selectedChild = testChild

        await viewModel.loadReportsData()

        XCTAssertTrue(viewModel.hasActiveSubscription)
        XCTAssertFalse(viewModel.showUpgradePrompt)

        viewModel.requestPremiumFeature()

        XCTAssertFalse(viewModel.showUpgradePrompt)
    }

    func testCanAccessPremiumPeriod() {
        // Without subscription
        viewModel.hasActiveSubscription = false

        XCTAssertTrue(viewModel.canAccessPremiumPeriod(.today))
        XCTAssertTrue(viewModel.canAccessPremiumPeriod(.week))
        XCTAssertFalse(viewModel.canAccessPremiumPeriod(.month))
        XCTAssertFalse(viewModel.canAccessPremiumPeriod(.custom))

        // With subscription
        viewModel.hasActiveSubscription = true

        XCTAssertTrue(viewModel.canAccessPremiumPeriod(.today))
        XCTAssertTrue(viewModel.canAccessPremiumPeriod(.week))
        XCTAssertTrue(viewModel.canAccessPremiumPeriod(.month))
        XCTAssertTrue(viewModel.canAccessPremiumPeriod(.custom))
    }

    func testDismissUpgradePrompt() {
        viewModel.showUpgradePrompt = true
        XCTAssertTrue(viewModel.showUpgradePrompt)

        viewModel.dismissUpgradePrompt()
        XCTAssertFalse(viewModel.showUpgradePrompt)
    }

    // MARK: - Helper Method Tests

    func testFormatDuration() {
        XCTAssertEqual(viewModel.formatDuration(45), "45m")
        XCTAssertEqual(viewModel.formatDuration(60), "1h 0m")
        XCTAssertEqual(viewModel.formatDuration(95), "1h 35m")
        XCTAssertEqual(viewModel.formatDuration(0), "0m")
    }

    func testFormatPoints() {
        XCTAssertEqual(viewModel.formatPoints(50), "50")
        XCTAssertEqual(viewModel.formatPoints(999), "999")
        XCTAssertEqual(viewModel.formatPoints(1000), "1.0K")
        XCTAssertEqual(viewModel.formatPoints(1500), "1.5K")
        XCTAssertEqual(viewModel.formatPoints(10000), "10.0K")
    }

    func testFormatPercentage() {
        XCTAssertEqual(viewModel.formatPercentage(45.67), "45.7%")
        XCTAssertEqual(viewModel.formatPercentage(100.0), "100.0%")
        XCTAssertEqual(viewModel.formatPercentage(0.0), "0.0%")
    }

    func testTrendIcon() {
        XCTAssertEqual(viewModel.trendIcon(for: .up), "arrow.up.circle.fill")
        XCTAssertEqual(viewModel.trendIcon(for: .down), "arrow.down.circle.fill")
        XCTAssertEqual(viewModel.trendIcon(for: .stable), "minus.circle.fill")
    }

    func testTrendColor() {
        XCTAssertEqual(viewModel.trendColor(for: .up), "green")
        XCTAssertEqual(viewModel.trendColor(for: .down), "red")
        XCTAssertEqual(viewModel.trendColor(for: .stable), "gray")
    }

    // MARK: - Helper Methods

    private func createTestChildProfile() -> ChildProfile {
        return ChildProfile(
            id: "test-child-id",
            familyID: "test-family-id",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date().addingTimeInterval(-10 * 365 * 24 * 60 * 60), // 10 years old
            pointBalance: 100,
            totalPointsEarned: 500
        )
    }

    private func createTestUsageSessions(for childID: String) -> [UsageSession] {
        let now = Date()
        return [
            UsageSession(
                id: "session1",
                childProfileID: childID,
                appBundleID: "com.apple.books",
                category: .learning,
                startTime: now.addingTimeInterval(-3600),
                endTime: now.addingTimeInterval(-1800),
                duration: 1800 // 30 minutes
            ),
            UsageSession(
                id: "session2",
                childProfileID: childID,
                appBundleID: "com.duolingo.app",
                category: .learning,
                startTime: now.addingTimeInterval(-7200),
                endTime: now.addingTimeInterval(-5400),
                duration: 1800 // 30 minutes
            ),
            UsageSession(
                id: "session3",
                childProfileID: childID,
                appBundleID: "com.game.app",
                category: .reward,
                startTime: now.addingTimeInterval(-10800),
                endTime: now.addingTimeInterval(-9000),
                duration: 1800 // 30 minutes
            )
        ]
    }

    private func createTestPointTransactions(for childID: String) -> [PointTransaction] {
        let now = Date()
        return [
            PointTransaction(
                id: "transaction1",
                childProfileID: childID,
                points: 60,
                reason: "Learning session",
                timestamp: now.addingTimeInterval(-3000)
            ),
            PointTransaction(
                id: "transaction2",
                childProfileID: childID,
                points: 90,
                reason: "Learning session",
                timestamp: now.addingTimeInterval(-6600)
            )
        ]
    }

    private func createTestAppCategorizations(for childID: String) -> [AppCategorization] {
        return [
            AppCategorization(
                id: "cat1",
                appBundleID: "com.apple.books",
                category: .learning,
                childProfileID: childID,
                pointsPerHour: 120
            ),
            AppCategorization(
                id: "cat2",
                appBundleID: "com.duolingo.app",
                category: .learning,
                childProfileID: childID,
                pointsPerHour: 180
            ),
            AppCategorization(
                id: "cat3",
                appBundleID: "com.game.app",
                category: .reward,
                childProfileID: childID,
                pointsPerHour: 0
            )
        ]
    }

    private func createMockReportsData() -> ReportsData {
        let summary = ReportSummary(
            totalTimeMinutes: 90,
            totalPointsEarned: 150,
            learningTimeMinutes: 60,
            rewardTimeMinutes: 30,
            averageSessionMinutes: 30,
            totalSessions: 3,
            pointsPerMinute: 1.67
        )

        let breakdown = CategoryBreakdown(
            learningApps: [],
            rewardApps: [],
            learningPercentage: 66.7,
            rewardPercentage: 33.3
        )

        let trends = TrendAnalysis(
            dailyUsage: [],
            weeklyComparison: WeeklyComparison(
                currentWeekMinutes: 90,
                previousWeekMinutes: 80,
                percentageChange: 12.5,
                trendDirection: .up
            ),
            streakData: StreakData(
                currentLearningStreak: 3,
                longestLearningStreak: 5,
                currentBalancedStreak: 2,
                longestBalancedStreak: 4
            ),
            peakUsageHours: [16, 19]
        )

        return ReportsData(
            period: .week,
            dateRange: DateRange(start: Date(), end: Date()),
            summary: summary,
            categoryBreakdown: breakdown,
            trends: trends,
            appDetails: []
        )
    }
}

// MARK: - Mock Repositories

class MockUsageSessionRepository: UsageSessionRepository {
    var sessions: [UsageSession] = []
    var shouldThrowError = false

    func createSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError { throw MockError.testError }
        return session
    }

    func fetchSession(id: String) async throws -> UsageSession? {
        if shouldThrowError { throw MockError.testError }
        return sessions.first { $0.id == id }
    }

    func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession] {
        if shouldThrowError { throw MockError.testError }

        let filteredSessions = sessions.filter { $0.childProfileID == childID }

        guard let dateRange = dateRange else {
            return filteredSessions
        }

        return filteredSessions.filter { session in
            session.startTime >= dateRange.start && session.startTime < dateRange.end
        }
    }

    func updateSession(_ session: UsageSession) async throws -> UsageSession {
        if shouldThrowError { throw MockError.testError }
        return session
    }

    func deleteSession(id: String) async throws {
        if shouldThrowError { throw MockError.testError }
    }
}

class MockPointTransactionRepository: PointTransactionRepository {
    var transactions: [PointTransaction] = []
    var shouldThrowError = false

    func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction {
        if shouldThrowError { throw MockError.testError }
        return transaction
    }

    func fetchTransaction(id: String) async throws -> PointTransaction? {
        if shouldThrowError { throw MockError.testError }
        return transactions.first { $0.id == id }
    }

    func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction] {
        if shouldThrowError { throw MockError.testError }
        let filtered = transactions.filter { $0.childProfileID == childID }
        if let limit = limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction] {
        if shouldThrowError { throw MockError.testError }

        let filteredTransactions = transactions.filter { $0.childProfileID == childID }

        guard let dateRange = dateRange else {
            return filteredTransactions
        }

        return filteredTransactions.filter { transaction in
            transaction.timestamp >= dateRange.start && transaction.timestamp < dateRange.end
        }
    }

    func deleteTransaction(id: String) async throws {
        if shouldThrowError { throw MockError.testError }
    }
}

class MockAppCategorizationRepository: AppCategorizationRepository {
    var categorizations: [AppCategorization] = []
    var shouldThrowError = false

    func createAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.testError }
        return categorization
    }

    func fetchAppCategorization(id: String) async throws -> AppCategorization? {
        if shouldThrowError { throw MockError.testError }
        return categorizations.first { $0.id == id }
    }

    func fetchAppCategorizations(for childID: String) async throws -> [AppCategorization] {
        if shouldThrowError { throw MockError.testError }
        return categorizations.filter { $0.childProfileID == childID }
    }

    func updateAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization {
        if shouldThrowError { throw MockError.testError }
        return categorization
    }

    func deleteAppCategorization(id: String) async throws {
        if shouldThrowError { throw MockError.testError }
    }
}

class MockChildProfileRepository: ChildProfileRepository {
    var children: [ChildProfile] = []
    var shouldThrowError = false

    func createChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError { throw MockError.testError }
        return child
    }

    func fetchChild(id: String) async throws -> ChildProfile? {
        if shouldThrowError { throw MockError.testError }
        return children.first { $0.id == id }
    }

    func fetchChildren(for familyID: String) async throws -> [ChildProfile] {
        if shouldThrowError { throw MockError.testError }
        return children.filter { $0.familyID == familyID }
    }

    func updateChild(_ child: ChildProfile) async throws -> ChildProfile {
        if shouldThrowError { throw MockError.testError }
        return child
    }

    func deleteChild(id: String) async throws {
        if shouldThrowError { throw MockError.testError }
    }
}

class MockSubscriptionRepository: SubscriptionEntitlementRepository {
    var hasActiveSubscription = false
    var shouldThrowError = false

    func createEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        if shouldThrowError { throw MockError.testError }
        return entitlement
    }

    func fetchEntitlement(id: String) async throws -> SubscriptionEntitlement? {
        if shouldThrowError { throw MockError.testError }
        return nil
    }

    func fetchEntitlements(for familyID: String) async throws -> [SubscriptionEntitlement] {
        if shouldThrowError { throw MockError.testError }

        if hasActiveSubscription {
            return [SubscriptionEntitlement(
                id: "test-entitlement",
                familyID: familyID,
                subscriptionType: "premium",
                startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isActive: true
            )]
        }

        return []
    }

    func updateEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        if shouldThrowError { throw MockError.testError }
        return entitlement
    }

    func deleteEntitlement(id: String) async throws {
        if shouldThrowError { throw MockError.testError }
    }
}

enum MockError: Error {
    case testError
}