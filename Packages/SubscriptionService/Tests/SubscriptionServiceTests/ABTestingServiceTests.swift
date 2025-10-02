import XCTest
import SharedModels
@testable import SubscriptionService

/// Mock implementation of AnalyticsRepository for testing
final class MockAnalyticsRepository: AnalyticsRepository {
    private var savedEvents: [AnalyticsEvent] = []
    private var aggregations: [AnalyticsAggregation] = []
    private var consents: [String: AnalyticsConsent] = [:]
    
    func saveEvent(_ event: AnalyticsEvent) async throws {
        savedEvents.append(event)
    }
    
    func fetchEvents(for familyID: String, dateRange: DateRange?) async throws -> [AnalyticsEvent] {
        if let dateRange = dateRange {
            // Use a traditional for loop to avoid Predicate issues
            var filteredEvents: [AnalyticsEvent] = []
            for event in savedEvents {
                if event.timestamp >= dateRange.start && event.timestamp <= dateRange.end {
                    filteredEvents.append(event)
                }
            }
            return filteredEvents
        }
        return savedEvents
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
    
    // Helper method to access saved events for testing
    var allSavedEvents: [AnalyticsEvent] {
        return savedEvents
    }

    func getSavedEvents() async -> [AnalyticsEvent] {
        return savedEvents
    }
    
    // Helper method to clear saved events
    func clearSavedEvents() {
        savedEvents.removeAll()
        aggregations.removeAll()
        consents.removeAll()
    }
}

final class ABTestingServiceTests: XCTestCase {
    private var service: ABTestingService!
    private var mockRepository: MockAnalyticsRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockAnalyticsRepository()
        service = ABTestingService(analyticsRepository: mockRepository)
    }

    override func tearDown() {
        service = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Test Management Tests

    func testCreateTest() async throws {
        // Given
        let testName = "pricing_test"
        let variants = [
            ABTestVariant(
                testName: testName,
                variantName: "control",
                configuration: ["price": "9.99"],
                isActive: true,
                trafficAllocation: 0.5
            ),
            ABTestVariant(
                testName: testName,
                variantName: "treatment",
                configuration: ["price": "7.99"],
                isActive: true,
                trafficAllocation: 0.5
            )
        ]

        // When
        try await service.createTest(
            testName: testName,
            variants: variants,
            trafficAllocation: 1.0
        )

        // Then - No exception should be thrown
        XCTAssertTrue(true)
    }

    func testCreateTestWithInvalidTrafficAllocation() async {
        // Given
        let testName = "invalid_test"
        let variants = [
            ABTestVariant(
                testName: testName,
                variantName: "control",
                configuration: [:],
                isActive: true,
                trafficAllocation: 0.5
            )
        ]

        // When & Then
        do {
            try await service.createTest(
                testName: testName,
                variants: variants,
                trafficAllocation: 1.5 // Invalid - greater than 1.0
            )
            XCTFail("Expected error for invalid traffic allocation")
        } catch ABTestingError.invalidTrafficAllocation {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateTestWithInvalidVariantAllocation() async {
        // Given
        let testName = "invalid_variant_test"
        let variants = [
            ABTestVariant(
                testName: testName,
                variantName: "control",
                configuration: [:],
                isActive: true,
                trafficAllocation: 0.6
            ),
            ABTestVariant(
                testName: testName,
                variantName: "treatment",
                configuration: [:],
                isActive: true,
                trafficAllocation: 0.6 // Total = 1.2, exceeds 1.0
            )
        ]

        // When & Then
        do {
            try await service.createTest(
                testName: testName,
                variants: variants,
                trafficAllocation: 1.0
            )
            XCTFail("Expected error for invalid variant allocation")
        } catch ABTestingError.invalidVariantAllocation {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetVariantForActiveTest() async throws {
        // Given
        let testName = "active_test"
        let variants = [
            ABTestVariant(
                testName: testName,
                variantName: "control",
                configuration: ["price": "9.99"],
                isActive: true,
                trafficAllocation: 0.5
            ),
            ABTestVariant(
                testName: testName,
                variantName: "treatment",
                configuration: ["price": "7.99"],
                isActive: true,
                trafficAllocation: 0.5
            )
        ]

        try await service.createTest(
            testName: testName,
            variants: variants,
            trafficAllocation: 1.0
        )

        // When
        let variant = await service.getVariant(testName: testName, userID: "test_user")

        // Then
        XCTAssertNotNil(variant)
        XCTAssertTrue(variants.contains { $0.variantName == variant?.variantName })
    }

    func testGetVariantForInactiveTest() async throws {
        // Given
        let testName = "inactive_test"

        // When
        let variant = await service.getVariant(testName: testName, userID: "test_user")

        // Then
        XCTAssertNil(variant)
    }

    func testGetVariantConsistentHashing() async throws {
        // Given
        let testName = "consistent_test"
        let variants = [
            ABTestVariant(
                testName: testName,
                variantName: "control",
                configuration: [:],
                isActive: true,
                trafficAllocation: 1.0
            )
        ]

        try await service.createTest(
            testName: testName,
            variants: variants,
            trafficAllocation: 1.0
        )

        let userID = "consistent_user"

        // When
        let variant1 = await service.getVariant(testName: testName, userID: userID)
        let variant2 = await service.getVariant(testName: testName, userID: userID)

        // Then
        XCTAssertEqual(variant1?.variantName, variant2?.variantName)
    }

    // MARK: - Event Tracking Tests

    func testTrackExposure() async {
        // Given
        let testName = "exposure_test"
        let variantName = "control"
        let userID = "test_user"
        let sessionID = "test_session"

        // When
        await service.trackExposure(
            testName: testName,
            variantName: variantName,
            userID: userID,
            sessionID: sessionID
        )

        // Then
        let savedEvents = await mockRepository.getSavedEvents()
        XCTAssertEqual(savedEvents.count, 1)

        let event = savedEvents.first!
        if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
            XCTAssertEqual(eventType, .featureGateEncounter)
            XCTAssertEqual(metadata["test_name"], testName)
            XCTAssertEqual(metadata["variant"], variantName)
        } else {
            XCTFail("Expected subscription event")
        }
    }

    func testTrackConversion() async {
        // Given
        let testName = "conversion_test"
        let variantName = "treatment"
        let userID = "test_user"
        let sessionID = "test_session"
        let conversionType = "trial_start"

        // When
        await service.trackConversion(
            testName: testName,
            variantName: variantName,
            userID: userID,
            sessionID: sessionID,
            conversionType: conversionType
        )

        // Then
        let savedEvents = await mockRepository.getSavedEvents()
        XCTAssertEqual(savedEvents.count, 1)

        let event = savedEvents.first!
        if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
            XCTAssertEqual(eventType, .purchase)
            XCTAssertEqual(metadata["test_name"], testName)
            XCTAssertEqual(metadata["variant"], variantName)
        } else {
            XCTFail("Expected subscription event")
        }
    }

    // MARK: - Paywall Design Tests

    func testCreatePaywallTest() async throws {
        // Given
        let testName = "paywall_design_test"
        let designs = [
            PaywallDesign(
                name: "control",
                configuration: ["layout": "vertical", "color": "blue"],
                trafficAllocation: 0.5
            ),
            PaywallDesign(
                name: "treatment",
                configuration: ["layout": "horizontal", "color": "green"],
                trafficAllocation: 0.5
            )
        ]

        // When
        try await service.createPaywallTest(testName: testName, designs: designs)

        // Then - No exception should be thrown
        XCTAssertTrue(true)
    }

    func testGetPaywallDesign() async throws {
        // Given
        let testName = "paywall_get_test"
        let designs = [
            PaywallDesign(
                name: "control",
                configuration: ["layout": "vertical"],
                trafficAllocation: 1.0
            )
        ]

        try await service.createPaywallTest(testName: testName, designs: designs)

        // When
        let design = await service.getPaywallDesign(testName: testName, userID: "test_user")

        // Then
        XCTAssertNotNil(design)
        XCTAssertEqual(design?.name, "control")
        XCTAssertEqual(design?.configuration["layout"], "vertical")
    }

    // MARK: - Pricing Experiment Tests

    func testCreatePricingExperiment() async throws {
        // Given
        let testName = "pricing_experiment"
        let pricePoints = [
            PricePoint(
                price: Decimal(9.99),
                currency: "USD",
                tier: "family_plus",
                trafficAllocation: 0.5
            ),
            PricePoint(
                price: Decimal(7.99),
                currency: "USD",
                tier: "family_plus",
                trafficAllocation: 0.5
            )
        ]

        // When
        try await service.createPricingExperiment(testName: testName, pricePoints: pricePoints)

        // Then - No exception should be thrown
        XCTAssertTrue(true)
    }

    func testGetPricePoint() async throws {
        // Given
        let testName = "price_point_test"
        let pricePoints = [
            PricePoint(
                price: Decimal(9.99),
                currency: "USD",
                tier: "family_plus",
                trafficAllocation: 1.0
            )
        ]

        try await service.createPricingExperiment(testName: testName, pricePoints: pricePoints)

        // When
        let pricePoint = await service.getPricePoint(testName: testName, userID: "test_user")

        // Then
        XCTAssertNotNil(pricePoint)
        XCTAssertEqual(pricePoint?.price, Decimal(9.99))
        XCTAssertEqual(pricePoint?.currency, "USD")
        XCTAssertEqual(pricePoint?.tier, "family_plus")
    }

    // MARK: - Feature Gate Experiment Tests

    func testCreateFeatureGateExperiment() async throws {
        // Given
        let testName = "feature_gate_test"
        let configurations = [
            FeatureGateConfiguration(
                name: "aggressive",
                settings: ["threshold": "1", "message": "Unlock now!"],
                trafficAllocation: 0.5
            ),
            FeatureGateConfiguration(
                name: "gentle",
                settings: ["threshold": "3", "message": "Consider upgrading"],
                trafficAllocation: 0.5
            )
        ]

        // When
        try await service.createFeatureGateExperiment(
            testName: testName,
            gateConfigurations: configurations
        )

        // Then - No exception should be thrown
        XCTAssertTrue(true)
    }

    func testGetFeatureGateConfiguration() async throws {
        // Given
        let testName = "feature_gate_config_test"
        let configurations = [
            FeatureGateConfiguration(
                name: "aggressive",
                settings: ["threshold": "1"],
                trafficAllocation: 1.0
            )
        ]

        try await service.createFeatureGateExperiment(
            testName: testName,
            gateConfigurations: configurations
        )

        // When
        let config = await service.getFeatureGateConfiguration(
            testName: testName,
            userID: "test_user"
        )

        // Then
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.name, "aggressive")
        XCTAssertEqual(config?.settings["threshold"], "1")
    }

    // MARK: - Test Analysis Tests

    func testAnalyzeTestResults() async throws {
        // Given
        let testName = "analysis_test"
        let dateRange = DateRange.last30Days()

        // Add mock test events
        await mockRepository.addMockTestEvents(testName: testName)

        // When
        let results = try await service.analyzeTestResults(
            testName: testName,
            dateRange: dateRange
        )

        // Then
        XCTAssertEqual(results.testName, testName)
        XCTAssertFalse(results.variantStats.isEmpty)

        for stat in results.variantStats {
            XCTAssertGreaterThan(stat.exposures, 0)
            XCTAssertGreaterThanOrEqual(stat.conversions, 0)
            XCTAssertGreaterThanOrEqual(stat.conversionRate, 0.0)
            XCTAssertLessThanOrEqual(stat.conversionRate, 1.0)
        }
    }

    func testAnalyzeTestResultsWithNoRepository() async {
        // Given
        let serviceWithoutRepo = ABTestingService(analyticsRepository: nil)
        let testName = "no_repo_test"
        let dateRange = DateRange.last30Days()

        // When & Then
        do {
            _ = try await serviceWithoutRepo.analyzeTestResults(
                testName: testName,
                dateRange: dateRange
            )
            XCTFail("Expected repository not available error")
        } catch ABTestingError.repositoryNotAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Statistical Significance Tests

    func testStatisticalSignificanceWithInsufficientData() async throws {
        // Given
        let testName = "small_sample_test"
        let dateRange = DateRange.last30Days()

        // Add minimal test events (below significance threshold)
        await mockRepository.addMockTestEvents(testName: testName, eventCount: 10)

        // When
        let results = try await service.analyzeTestResults(
            testName: testName,
            dateRange: dateRange
        )

        // Then
        XCTAssertFalse(results.isStatisticallySignificant)
    }

    func testStatisticalSignificanceWithSufficientData() async throws {
        // Given
        let testName = "large_sample_test"
        let dateRange = DateRange.last30Days()

        // Add sufficient test events (above significance threshold)
        await mockRepository.addMockTestEvents(testName: testName, eventCount: 200)

        // When
        let results = try await service.analyzeTestResults(
            testName: testName,
            dateRange: dateRange
        )

        // Then
        XCTAssertTrue(results.isStatisticallySignificant)
    }
}

// MARK: - Mock Analytics Repository Extension

extension MockAnalyticsRepository {
    func addMockTestEvents(testName: String, eventCount: Int = 100) async {
        let now = Date()
        let calendar = Calendar.current

        let variants = ["control", "treatment"]

        for i in 0..<eventCount {
            let date = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
            let variant = variants[i % variants.count]
            let userID = "user_\(i % 20)"

            // Add exposure event
            let exposureEvent = AnalyticsEvent(
                eventType: .subscriptionEvent(
                    eventType: .featureGateEncounter,
                    metadata: [
                        "test_name": testName,
                        "variant": variant,
                        "event_type": "exposure"
                    ]
                ),
                timestamp: date,
                anonymizedUserID: userID,
                sessionID: "session_\(i)",
                appVersion: "1.0.0",
                osVersion: "iOS 15.0",
                deviceModel: "iPhone"
            )

            try? await saveEvent(exposureEvent)

            // Add conversion event for some users (simulate 20% conversion rate)
            if i % 5 == 0 {
                let conversionEvent = AnalyticsEvent(
                    eventType: .subscriptionEvent(
                        eventType: .purchase,
                        metadata: [
                            "test_name": testName,
                            "variant": variant,
                            "conversion_type": "trial_start",
                            "event_type": "conversion"
                        ]
                    ),
                    timestamp: calendar.date(byAdding: .minute, value: 30, to: date) ?? date,
                    anonymizedUserID: userID,
                    sessionID: "session_\(i)",
                    appVersion: "1.0.0",
                    osVersion: "iOS 15.0",
                    deviceModel: "iPhone"
                )

                try? await saveEvent(conversionEvent)
            }
        }
    }
}