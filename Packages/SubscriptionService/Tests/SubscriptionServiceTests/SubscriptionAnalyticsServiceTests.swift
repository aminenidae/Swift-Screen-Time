import XCTest
import SharedModels
import RewardCore
@testable import SubscriptionService

final class SubscriptionAnalyticsServiceTests: XCTestCase {
    private var service: SubscriptionAnalyticsService!
    private var mockRepository: SubscriptionAnalyticsMockAnalyticsRepository!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = SubscriptionAnalyticsMockAnalyticsRepository()
        service = SubscriptionAnalyticsService(
            analyticsRepository: mockRepository
        )
    }

    override func tearDown() {
        service = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Conversion Funnel Tests

    func testTrackPaywallImpression() async {
        // Given
        let paywallID = "main_paywall"
        let trigger = "feature_gate"
        let familyID = "test_family"
        let sessionID = "test_session"

        // When
        await service.trackPaywallImpression(
            paywallID: paywallID,
            trigger: trigger,
            familyID: familyID,
            sessionID: sessionID
        )

        // Then
        let savedEvents = await mockRepository.getSavedEvents()
        XCTAssertEqual(savedEvents.count, 1)

        let event = savedEvents.first!
        if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
            XCTAssertEqual(eventType, .paywallImpression)
            XCTAssertEqual(metadata["paywall_id"], paywallID)
            XCTAssertEqual(metadata["trigger"], trigger)
            XCTAssertEqual(metadata["family_id"], familyID)
        } else {
            XCTFail("Expected subscription event")
        }

        XCTAssertEqual(event.sessionID, sessionID)
    }

    func testTrackTrialStart() async {
        // Given
        let familyID = "test_family"
        let sessionID = "test_session"
        let tier = "family_plus"
        let acquisitionChannel = "referral"

        // When
        await service.trackTrialStart(
            familyID: familyID,
            sessionID: sessionID,
            tier: tier,
            acquisitionChannel: acquisitionChannel
        )

        // Then
        let savedEvents = await mockRepository.getSavedEvents()
        XCTAssertEqual(savedEvents.count, 1)

        let event = savedEvents.first!
        if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
            XCTAssertEqual(eventType, .trialStart)
            XCTAssertEqual(metadata["tier"], tier)
            XCTAssertEqual(metadata["acquisition_channel"], acquisitionChannel)
        } else {
            XCTFail("Expected subscription event")
        }
    }

    func testTrackPurchase() async {
        // Given
        let familyID = "test_family"
        let sessionID = "test_session"
        let productID = "family_plus_monthly"
        let price = Decimal(9.99)
        let currency = "USD"
        let tier = "family_plus"
        let wasInTrial = true
        let timeToConversion: TimeInterval = 300.0

        // When
        await service.trackPurchase(
            familyID: familyID,
            sessionID: sessionID,
            productID: productID,
            price: price,
            currency: currency,
            tier: tier,
            wasInTrial: wasInTrial,
            timeToConversion: timeToConversion
        )

        // Then
        let savedEvents = await mockRepository.getSavedEvents()
        XCTAssertEqual(savedEvents.count, 1)

        let event = savedEvents.first!
        if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
            XCTAssertEqual(eventType, .purchase)
            XCTAssertEqual(metadata["product_id"], productID)
            XCTAssertEqual(metadata["price"], price.description)
            XCTAssertEqual(metadata["currency"], currency)
            XCTAssertEqual(metadata["tier"], tier)
            XCTAssertEqual(metadata["was_in_trial"], "true")
            XCTAssertEqual(metadata["time_to_conversion"], String(timeToConversion))
        } else {
            XCTFail("Expected subscription event")
        }
    }

    func testCalculateConversionRates() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockSubscriptionEvents()

        // When
        let conversionRates = try await service.calculateConversionRates(dateRange: dateRange)

        // Then
        XCTAssertTrue(conversionRates.keys.contains("impression_to_trial"))
        XCTAssertTrue(conversionRates.keys.contains("trial_to_purchase"))
        XCTAssertTrue(conversionRates.keys.contains("impression_to_purchase"))

        // Verify rates are reasonable (based on mock data)
        if let impressionToTrial = conversionRates["impression_to_trial"] {
            XCTAssertGreaterThan(impressionToTrial, 0.0)
            XCTAssertLessThanOrEqual(impressionToTrial, 1.0)
        }
    }

    // MARK: - Key Metrics Tests

    func testCalculateTrialToPaidConversion() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockSubscriptionEvents()

        // When
        let conversion = try await service.calculateTrialToPaidConversion(dateRange: dateRange)

        // Then
        XCTAssertGreaterThanOrEqual(conversion, 0.0)
        XCTAssertLessThanOrEqual(conversion, 1.0)
    }

    func testCalculateMRR() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockSubscriptionEvents()

        // When
        let mrr = try await service.calculateMRR(dateRange: dateRange)

        // Then
        XCTAssertGreaterThanOrEqual(mrr, 0.0)
    }

    func testCalculateARR() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockSubscriptionEvents()

        // When
        let arr = try await service.calculateARR(dateRange: dateRange)

        // Then
        let mrr = try await service.calculateMRR(dateRange: dateRange)
        XCTAssertEqual(arr, mrr * 12, accuracy: 0.01)
    }

    func testCalculateChurnRate() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockSubscriptionEvents()

        // When
        let churnRate = try await service.calculateChurnRate(dateRange: dateRange)

        // Then
        XCTAssertGreaterThanOrEqual(churnRate, 0.0)
        XCTAssertLessThanOrEqual(churnRate, 1.0)
    }

    func testCalculateARPU() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockSubscriptionEvents()

        // When
        let arpu = try await service.calculateARPU(dateRange: dateRange)

        // Then
        XCTAssertGreaterThanOrEqual(arpu, 0.0)
    }

    func testGenerateSubscriptionMetrics() async throws {
        // Given
        let dateRange = DateRange.last30Days()
        await mockRepository.addMockSubscriptionEvents()

        // When
        let metrics = try await service.generateSubscriptionMetrics(dateRange: dateRange)

        // Then
        XCTAssertGreaterThanOrEqual(metrics.monthlyRecurringRevenue, 0.0)
        XCTAssertEqual(metrics.annualRecurringRevenue, metrics.monthlyRecurringRevenue * 12, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(metrics.trialToPaidConversion, 0.0)
        XCTAssertLessThanOrEqual(metrics.trialToPaidConversion, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.churnRate, 0.0)
        XCTAssertLessThanOrEqual(metrics.churnRate, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.averageRevenuePerUser, 0.0)
    }

    // MARK: - Error Handling Tests

    func testCalculateConversionRatesWithNoRepository() async throws {
        // Given
        let serviceWithoutRepo = SubscriptionAnalyticsService(
            analyticsRepository: nil
        )
        let dateRange = DateRange.last30Days()

        // When
        let conversionRates = try await serviceWithoutRepo.calculateConversionRates(dateRange: dateRange)

        // Then
        XCTAssertTrue(conversionRates.isEmpty)
    }

    func testCalculateMRRWithNoRepository() async throws {
        // Given
        let serviceWithoutRepo = SubscriptionAnalyticsService(
            analyticsRepository: nil
        )
        let dateRange = DateRange.last30Days()

        // When
        let mrr = try await serviceWithoutRepo.calculateMRR(dateRange: dateRange)

        // Then
        XCTAssertEqual(mrr, 0.0)
    }
}

// MARK: - Mock Analytics Repository

@MainActor
class SubscriptionAnalyticsMockAnalyticsRepository: AnalyticsRepository {
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

}

// MARK: - Test Helper Methods

extension SubscriptionAnalyticsMockAnalyticsRepository {
    func getSavedEvents() async -> [AnalyticsEvent] {
        return events
    }

    func addMockSubscriptionEvents() async {
        let now = Date()
        let calendar = Calendar.current

        // Add paywall impressions
        for i in 0..<100 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let event = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .paywallImpression,
                    metadata: [
                        "paywall_id": "main_paywall",
                        "trigger": "feature_gate",
                        "family_id": "family_\(i % 20)"
                    ]
                ),
                timestamp: date,
                anonymizedUserID: "anon_user_\(i % 20)",
                sessionID: "session_\(i)",
                appVersion: "1.0.0",
                osVersion: "iOS 15.0",
                deviceModel: "iPhone"
            )
            events.append(event)
        }

        // Add trial starts (20% conversion)
        for i in 0..<20 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let event = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .trialStart,
                    metadata: [
                        "tier": "family_plus",
                        "family_id": "family_\(i)",
                        "acquisition_channel": i % 3 == 0 ? "organic" : "referral"
                    ]
                ),
                timestamp: date,
                anonymizedUserID: "anon_user_\(i)",
                sessionID: "session_\(i)",
                appVersion: "1.0.0",
                osVersion: "iOS 15.0",
                deviceModel: "iPhone"
            )
            events.append(event)
        }

        // Add purchases (30% of trials convert)
        for i in 0..<6 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let event = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .purchase,
                    metadata: [
                        "product_id": "family_plus_monthly",
                        "price": "9.99",
                        "currency": "USD",
                        "tier": "family_plus",
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
            events.append(event)
        }

        // Add some renewals
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let event = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .renewal,
                    metadata: [
                        "product_id": "family_plus_monthly",
                        "price": "9.99",
                        "currency": "USD",
                        "tier": "family_plus",
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
            events.append(event)
        }

        // Add some cancellations
        for i in 0..<2 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let event = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .cancellation,
                    metadata: [
                        "tier": "family_plus",
                        "reason": "cost",
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
            events.append(event)
        }
    }

    func clearEvents() {
        events.removeAll()
    }
}