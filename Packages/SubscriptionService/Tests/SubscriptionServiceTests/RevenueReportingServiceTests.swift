import XCTest
import SharedModels
import RewardCore
@testable import SubscriptionService

// MARK: - Mock Analytics Repository

@MainActor
class RevenueReportingMockAnalyticsRepository: AnalyticsRepository {
    private var events: [AnalyticsEvent] = []
    private var aggregations: [AnalyticsAggregation] = []
    private var consents: [String: AnalyticsConsent] = [:]

    func saveEvent(_ event: AnalyticsEvent) async throws {
        events.append(event)
    }

    func fetchEvents(for familyID: String, dateRange: DateRange?) async throws -> [AnalyticsEvent] {
        if let dateRange = dateRange {
            // Use a traditional for loop to avoid Predicate issues
            var filteredEvents: [AnalyticsEvent] = []
            for event in events {
                if event.timestamp >= dateRange.start && event.timestamp <= dateRange.end {
                    filteredEvents.append(event)
                }
            }
            return filteredEvents
        }
        return events
    }

    func saveAggregation(_ aggregation: AnalyticsAggregation) async throws {
        aggregations.append(aggregation)
    }

    func fetchAggregations(for aggregationType: AggregationType, dateRange: DateRange?) async throws -> [AnalyticsAggregation] {
        return aggregations.filter { $0.aggregationType == aggregationType }
    }

    func saveConsent(_ consent: AnalyticsConsent) async throws {
        consents[consent.familyID] = consent
    }

    func fetchConsent(for familyID: String) async throws -> AnalyticsConsent? {
        return consents[familyID]
    }

    // Test helper methods
    func getSavedEvents() async -> [AnalyticsEvent] {
        return events
    }

    func addMockRevenueEvents() async {
        let now = Date()
        let calendar = Calendar.current

        // Add purchase events
        for i in 0..<50 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let tier = i % 3 == 0 ? "family_plus" : "family_basic"
            let price = tier == "family_plus" ? "9.99" : "4.99"

            let purchaseEvent = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .purchase,
                    metadata: [
                        "product_id": "\(tier)_monthly",
                        "price": price,
                        "currency": "USD",
                        "tier": tier,
                        "was_in_trial": "true",
                        "family_id": "family_\(i)"
                    ]
                ),
                timestamp: date,
                anonymizedUserID: "anon_user_\(i)",
                sessionID: "session_\(i)",
                appVersion: "1.0.0",
                osVersion: "iOS 15.0",
                deviceModel: "iPhone"
            )

            try? await saveEvent(purchaseEvent)
        }

        // Add renewal events
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let tier = i % 2 == 0 ? "family_plus" : "family_basic"
            let price = tier == "family_plus" ? "9.99" : "4.99"

            let renewalEvent = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .renewal,
                    metadata: [
                        "product_id": "\(tier)_monthly",
                        "price": price,
                        "currency": "USD",
                        "tier": tier,
                        "family_id": "family_\(i + 100)"
                    ]
                ),
                timestamp: date,
                anonymizedUserID: "anon_user_\(i + 100)",
                sessionID: "session_\(i + 100)",
                appVersion: "1.0.0",
                osVersion: "iOS 15.0",
                deviceModel: "iPhone"
            )

            try? await saveEvent(renewalEvent)
        }

        // Add some refund events
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now

            let refundEvent = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .cancellation,
                    metadata: [
                        "refund_amount": "9.99",
                        "currency": "USD",
                        "tier": "family_plus",
                        "reason": "user_request",
                        "family_id": "family_\(i + 200)"
                    ]
                ),
                timestamp: date,
                anonymizedUserID: "anon_user_\(i + 200)",
                sessionID: "session_\(i + 200)",
                appVersion: "1.0.0",
                osVersion: "iOS 15.0",
                deviceModel: "iPhone"
            )

            try? await saveEvent(refundEvent)
        }
    }

    func clearEvents() {
        events.removeAll()
    }
}

final class RevenueReportingServiceTests: XCTestCase {
    private var service: RevenueReportingService!
    private var mockRepository: RevenueReportingMockAnalyticsRepository!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = RevenueReportingMockAnalyticsRepository()
        service = RevenueReportingService(analyticsRepository: mockRepository)
    }

    override func tearDown() {
        service = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Revenue Report Generation Tests

    func testGenerateDailyReport() async throws {
        // Given
        let testDate = Date()
        await mockRepository.addMockRevenueEvents()

        // When
        let report = try await service.generateDailyReport(for: testDate)

        // Then
        XCTAssertEqual(report.reportType, .daily)
        XCTAssertGreaterThanOrEqual(report.totalRevenue, 0.0)
        XCTAssertGreaterThanOrEqual(report.netRevenue, 0.0)
        XCTAssertLessThanOrEqual(report.netRevenue, report.totalRevenue)
        XCTAssertFalse(report.revenueByTier.isEmpty)
    }

    func testGenerateWeeklyReport() async throws {
        // Given
        let weekStartDate = Calendar.current.startOfDay(for: Date())
        await mockRepository.addMockRevenueEvents()

        // When
        let report = try await service.generateWeeklyReport(for: weekStartDate)

        // Then
        XCTAssertEqual(report.reportType, .weekly)
        XCTAssertGreaterThanOrEqual(report.totalRevenue, 0.0)
        XCTAssertGreaterThanOrEqual(report.netRevenue, 0.0)

        // Verify date range is correct (7 days)
        let daysDifference = Calendar.current.dateComponents(
            [.day],
            from: report.startDate,
            to: report.endDate
        ).day!
        XCTAssertEqual(daysDifference, 6) // Start day + 6 more days = 7 days total
    }

    func testGenerateMonthlyReport() async throws {
        // Given
        let month = 12
        let year = 2023
        await mockRepository.addMockRevenueEvents()

        // When
        let report = try await service.generateMonthlyReport(for: month, year: year)

        // Then
        XCTAssertEqual(report.reportType, .monthly)
        XCTAssertGreaterThanOrEqual(report.totalRevenue, 0.0)
        XCTAssertGreaterThanOrEqual(report.netRevenue, 0.0)

        // Verify the report is for the correct month/year
        let calendar = Calendar.current
        let startMonth = calendar.component(.month, from: report.startDate)
        let startYear = calendar.component(.year, from: report.startDate)
        XCTAssertEqual(startMonth, month)
        XCTAssertEqual(startYear, year)
    }

    // MARK: - Revenue by Tier Tests

    func testCalculateRevenueByTier() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockRevenueEvents()

        // When
        let revenueByTier = try await service.calculateRevenueByTier(dateRange: dateRange)

        // Then
        XCTAssertFalse(revenueByTier.isEmpty)

        // Verify all values are non-negative
        for (_, revenue) in revenueByTier {
            XCTAssertGreaterThanOrEqual(revenue, 0.0)
        }

        // Should include common tiers from mock data
        XCTAssertTrue(revenueByTier.keys.contains("family_plus"))
    }

    // MARK: - Refund Tracking Tests

    func testTrackRefund() async {
        // Given
        let familyID = "test_family"
        let productID = "family_plus_monthly"
        let refundAmount = Decimal(9.99)
        let currency = "USD"
        let tier = "family_plus"
        let reason = RefundReason.userRequest

        // When
        await service.trackRefund(
            familyID: familyID,
            productID: productID,
            refundAmount: refundAmount,
            currency: currency,
            tier: tier,
            reason: reason
        )

        // Then
        let savedEvents = await mockRepository.getSavedEvents()
        XCTAssertEqual(savedEvents.count, 1)

        let event = savedEvents.first!
        if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
            XCTAssertEqual(eventType, .cancellation)
            XCTAssertEqual(metadata["product_id"], productID)
            XCTAssertEqual(metadata["refund_amount"], refundAmount.description)
            XCTAssertEqual(metadata["currency"], currency)
            XCTAssertEqual(metadata["tier"], tier)
            XCTAssertEqual(metadata["reason"], reason.rawValue)
        } else {
            XCTFail("Expected subscription event")
        }
    }

    // MARK: - Net Revenue Calculation Tests

    func testCalculateTotalRevenue() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockRevenueEvents()

        // When
        let totalRevenue = try await service.calculateTotalRevenue(dateRange: dateRange)

        // Then
        XCTAssertGreaterThan(totalRevenue, 0.0)
    }

    func testCalculateTotalRefunds() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockRevenueEvents()

        // When
        let totalRefunds = try await service.calculateTotalRefunds(dateRange: dateRange)

        // Then
        XCTAssertGreaterThanOrEqual(totalRefunds, 0.0)
    }

    func testCalculateNetRevenue() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockRevenueEvents()

        // When
        let netRevenue = try await service.calculateNetRevenue(dateRange: dateRange)
        let totalRevenue = try await service.calculateTotalRevenue(dateRange: dateRange)
        let totalRefunds = try await service.calculateTotalRefunds(dateRange: dateRange)

        // Then
        XCTAssertEqual(netRevenue, totalRevenue - totalRefunds, accuracy: 0.01)
        XCTAssertLessThanOrEqual(netRevenue, totalRevenue)
    }

    func testCalculateChargebacks() async throws {
        // Given
        let dateRange = DateRange.last30Days()

        // When
        let chargebacks = try await service.calculateChargebacks(dateRange: dateRange)

        // Then
        // Currently returns 0 as mock implementation
        XCTAssertEqual(chargebacks, 0.0)
    }

    // MARK: - Revenue Trends Tests

    func testCalculateRevenueGrowthRate() async throws {
        // Given
        let calendar = Calendar.current
        let now = Date()

        let currentPeriodStart = calendar.date(byAdding: .day, value: -30, to: now)!
        let currentPeriod = DateRange(start: currentPeriodStart, end: now)

        let previousPeriodStart = calendar.date(byAdding: .day, value: -60, to: now)!
        let previousPeriodEnd = calendar.date(byAdding: .day, value: -31, to: now)!
        let previousPeriod = DateRange(start: previousPeriodStart, end: previousPeriodEnd)

        await mockRepository.addMockRevenueEvents()

        // When
        let growthRate = try await service.calculateRevenueGrowthRate(
            currentPeriod: currentPeriod,
            previousPeriod: previousPeriod
        )

        // Then
        // Growth rate should be a percentage (could be positive, negative, or zero)
        XCTAssertTrue(growthRate >= -100.0) // Can't shrink more than 100%
    }

    func testGenerateRevenueTrends() async throws {
        // Given
        let calendar = Calendar.current
        let now = Date()

        let periods: [SharedModels.DateRange] = [
            SharedModels.DateRange(start: calendar.date(byAdding: .day, value: -2, to: now)!, end: calendar.date(byAdding: .day, value: -1, to: now)!),
            SharedModels.DateRange(start: calendar.date(byAdding: .day, value: -1, to: now)!, end: now),
            SharedModels.DateRange(start: now, end: now.addingTimeInterval(24*60*60))
        ]

        await mockRepository.addMockRevenueEvents()

        // When
        let trends = try await service.generateRevenueTrends(periods: periods)

        // Then
        XCTAssertEqual(trends.trends.count, 3)

        for trend in trends.trends {
            XCTAssertGreaterThanOrEqual(trend.totalRevenue, 0.0)
            XCTAssertGreaterThanOrEqual(trend.netRevenue, 0.0)
            XCTAssertLessThanOrEqual(trend.netRevenue, trend.totalRevenue)
        }
    }

    // MARK: - Revenue Forecasting Tests

    func testGenerateRevenueForecast() async throws {
        // Given
        let calendar = Calendar.current
        let now = Date()

        let historicalPeriods: [SharedModels.DateRange] = [
            SharedModels.DateRange(start: calendar.date(byAdding: .day, value: -5, to: now)!, end: calendar.date(byAdding: .day, value: -4, to: now)!),
            SharedModels.DateRange(start: calendar.date(byAdding: .day, value: -4, to: now)!, end: calendar.date(byAdding: .day, value: -3, to: now)!),
            SharedModels.DateRange(start: calendar.date(byAdding: .day, value: -3, to: now)!, end: calendar.date(byAdding: .day, value: -2, to: now)!),
            SharedModels.DateRange(start: calendar.date(byAdding: .day, value: -2, to: now)!, end: calendar.date(byAdding: .day, value: -1, to: now)!),
            SharedModels.DateRange(start: calendar.date(byAdding: .day, value: -1, to: now)!, end: now)
        ]

        await mockRepository.addMockRevenueEvents()

        // When
        let forecast = try await service.generateRevenueForecast(
            historicalPeriods: historicalPeriods,
            forecastPeriods: 3
        )

        // Then
        XCTAssertEqual(forecast.forecastPoints.count, 3)
        XCTAssertEqual(forecast.methodology, "Linear trend with average growth rate")

        for (index, point) in forecast.forecastPoints.enumerated() {
            XCTAssertEqual(point.periodIndex, index + 1)
            XCTAssertGreaterThanOrEqual(point.forecastRevenue, 0.0)
            XCTAssertGreaterThan(point.confidence, 0.0)
            XCTAssertLessThanOrEqual(point.confidence, 1.0)

            // Confidence should decrease with distance
            if index > 0 {
                let previousPoint = forecast.forecastPoints[index - 1]
                XCTAssertLessThanOrEqual(point.confidence, previousPoint.confidence)
            }
        }
    }

    // MARK: - Error Handling Tests

    func testCalculateRevenueWithNoRepository() async throws {
        // Given
        let serviceWithoutRepo = RevenueReportingService(analyticsRepository: nil)
        let dateRange = DateRange.last30Days()

        // When & Then
        do {
            _ = try await serviceWithoutRepo.calculateTotalRevenue(dateRange: dateRange)
            XCTFail("Expected repository not available error")
        } catch RevenueReportingError.repositoryNotAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateReportWithNoRepository() async throws {
        // Given
        let serviceWithoutRepo = RevenueReportingService(analyticsRepository: nil)

        // When & Then
        do {
            _ = try await serviceWithoutRepo.generateDailyReport(for: Date())
            XCTFail("Expected repository not available error")
        } catch RevenueReportingError.repositoryNotAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}