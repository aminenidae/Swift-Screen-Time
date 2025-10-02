import XCTest
@testable import RewardCore
@testable import SharedModels

final class AnalyticsServiceTests: XCTestCase {
    var analyticsService: AnalyticsService!
    var mockConsentService: MockAnalyticsConsentService!
    var mockAnonymizationService: MockDataAnonymizationService!
    var mockAggregationService: MockAnalyticsAggregationService!
    var mockRepository: MockAnalyticsRepository!
    
    override func setUp() {
        super.setUp()
        mockConsentService = MockAnalyticsConsentService()
        mockAnonymizationService = MockDataAnonymizationService()
        mockAggregationService = MockAnalyticsAggregationService()
        mockRepository = MockAnalyticsRepository()
        
        analyticsService = AnalyticsService(
            consentService: mockConsentService,
            anonymizationService: mockAnonymizationService,
            aggregationService: mockAggregationService,
            repository: mockRepository
        )
    }
    
    override func tearDown() {
        analyticsService = nil
        mockConsentService = nil
        mockAnonymizationService = nil
        mockAggregationService = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Event Tracking Tests
    
    func testTrackEvent_WhenCollectionAllowed_SavesEvent() async {
        // Given
        mockConsentService.collectionAllowed = true
        let event = createTestEvent()
        
        // When
        await analyticsService.trackEvent(event)
        
        // Then
        XCTAssertTrue(mockRepository.saveEventCalled)
        XCTAssertNotNil(mockRepository.savedEvent)
    }
    
    func testTrackEvent_WhenCollectionNotAllowed_DoesNotSaveEvent() async {
        // Given
        mockConsentService.collectionAllowed = false
        let event = createTestEvent()
        
        // When
        await analyticsService.trackEvent(event)
        
        // Then
        XCTAssertFalse(mockRepository.saveEventCalled)
        XCTAssertNil(mockRepository.savedEvent)
    }
    
    func testTrackFeatureUsage_CreatesAndTracksEvent() async {
        // Given
        mockConsentService.collectionAllowed = true
        let feature = "testFeature"
        let metadata = ["key": "value"]
        
        // When
        await analyticsService.trackFeatureUsage(feature: feature, metadata: metadata)
        
        // Then
        XCTAssertTrue(mockRepository.saveEventCalled)
        XCTAssertNotNil(mockRepository.savedEvent)
        
        if case .featureUsage(let trackedFeature) = mockRepository.savedEvent?.eventType {
            XCTAssertEqual(trackedFeature, feature)
        } else {
            XCTFail("Expected featureUsage event type")
        }
    }
    
    func testTrackUserFlow_CreatesAndTracksEvent() async {
        // Given
        mockConsentService.collectionAllowed = true
        let flow = "testFlow"
        let step = "testStep"
        
        // When
        await analyticsService.trackUserFlow(flow: flow, step: step)
        
        // Then
        XCTAssertTrue(mockRepository.saveEventCalled)
        XCTAssertNotNil(mockRepository.savedEvent)
        
        if case .userFlow(let trackedFlow, let trackedStep) = mockRepository.savedEvent?.eventType {
            XCTAssertEqual(trackedFlow, flow)
            XCTAssertEqual(trackedStep, step)
        } else {
            XCTFail("Expected userFlow event type")
        }
    }
    
    func testTrackPerformance_CreatesAndTracksEvent() async {
        // Given
        mockConsentService.collectionAllowed = true
        let metric = "testMetric"
        let value = 1.5
        
        // When
        await analyticsService.trackPerformance(metric: metric, value: value)
        
        // Then
        XCTAssertTrue(mockRepository.saveEventCalled)
        XCTAssertNotNil(mockRepository.savedEvent)
        
        if case .performance(let trackedMetric, let trackedValue) = mockRepository.savedEvent?.eventType {
            XCTAssertEqual(trackedMetric, metric)
            XCTAssertEqual(trackedValue, value)
        } else {
            XCTFail("Expected performance event type")
        }
    }
    
    func testTrackError_CreatesAndTracksEvent() async {
        // Given
        mockConsentService.collectionAllowed = true
        let category = "testCategory"
        let code = "testCode"
        
        // When
        await analyticsService.trackError(category: category, code: code)
        
        // Then
        XCTAssertTrue(mockRepository.saveEventCalled)
        XCTAssertNotNil(mockRepository.savedEvent)
        
        if case .error(let trackedCategory, let trackedCode) = mockRepository.savedEvent?.eventType {
            XCTAssertEqual(trackedCategory, category)
            XCTAssertEqual(trackedCode, code)
        } else {
            XCTFail("Expected error event type")
        }
    }
    
    func testTrackEngagement_CreatesAndTracksEvent() async {
        // Given
        mockConsentService.collectionAllowed = true
        let type = "testType"
        let duration: TimeInterval = 30.0
        
        // When
        await analyticsService.trackEngagement(type: type, duration: duration)
        
        // Then
        XCTAssertTrue(mockRepository.saveEventCalled)
        XCTAssertNotNil(mockRepository.savedEvent)
        
        if case .engagement(let trackedType, let trackedDuration) = mockRepository.savedEvent?.eventType {
            XCTAssertEqual(trackedType, type)
            XCTAssertEqual(trackedDuration, duration)
        } else {
            XCTFail("Expected engagement event type")
        }
    }
    
    // MARK: - Aggregation Tests
    
    func testPerformDailyAggregation_CallsAggregationService() async {
        // When
        await analyticsService.performDailyAggregation()
        
        // Then
        XCTAssertTrue(mockAggregationService.dailyAggregationCalled)
    }
    
    func testPerformWeeklyAggregation_CallsAggregationService() async {
        // When
        await analyticsService.performWeeklyAggregation()
        
        // Then
        XCTAssertTrue(mockAggregationService.weeklyAggregationCalled)
    }
    
    func testPerformMonthlyAggregation_CallsAggregationService() async {
        // When
        await analyticsService.performMonthlyAggregation()
        
        // Then
        XCTAssertTrue(mockAggregationService.monthlyAggregationCalled)
    }
    
    // MARK: - Helper Methods
    
    private func createTestEvent() -> AnalyticsEvent {
        return AnalyticsEvent(
            eventType: .featureUsage(feature: "testFeature"),
            anonymizedUserID: "test-user-id",
            sessionID: "test-session-id",
            appVersion: "1.0.0",
            osVersion: "15.0",
            deviceModel: "iPhone",
            metadata: [:]
        )
    }
}

// MARK: - Mock Classes

class MockAnalyticsConsentService: AnalyticsConsentService, @unchecked Sendable {
    var collectionAllowed = true

    override func isCollectionAllowed(for userID: String) async -> Bool {
        return collectionAllowed
    }
}

class MockDataAnonymizationService: DataAnonymizationService, @unchecked Sendable {
    override func anonymize(event: AnalyticsEvent) -> AnalyticsEvent {
        return event
    }

    override func getCurrentAnonymizedUserID() async -> String {
        return "test-user-id"
    }

    override func getCurrentSessionID() -> String {
        return "test-session-id"
    }

    override func getAppVersion() async -> String {
        return "1.0.0"
    }

    override func getOSVersion() async -> String {
        return "15.0"
    }

    override func getDeviceModel() async -> String {
        return "iPhone"
    }
}

class MockAnalyticsAggregationService: AnalyticsAggregationService, @unchecked Sendable {
    var dailyAggregationCalled = false
    var weeklyAggregationCalled = false
    var monthlyAggregationCalled = false

    override func performDailyAggregation() async {
        dailyAggregationCalled = true
    }

    override func performWeeklyAggregation() async {
        weeklyAggregationCalled = true
    }

    override func performMonthlyAggregation() async {
        monthlyAggregationCalled = true
    }
}

class MockAnalyticsRepository: AnalyticsRepository, @unchecked Sendable {
    var saveEventCalled = false
    var savedEvent: AnalyticsEvent?
    var savedConsent: AnalyticsConsent?
    
    func saveEvent(_ event: AnalyticsEvent) async throws {
        saveEventCalled = true
        savedEvent = event
    }
    
    func fetchEvents(for userID: String, dateRange: DateRange?) async throws -> [AnalyticsEvent] {
        return []
    }
    
    func saveAggregation(_ aggregation: AnalyticsAggregation) async throws {
        // Mock implementation
    }
    
    func fetchAggregations(for aggregationType: AggregationType, dateRange: DateRange?) async throws -> [AnalyticsAggregation] {
        return []
    }
    
    func saveConsent(_ consent: AnalyticsConsent) async throws {
        savedConsent = consent
    }
    
    func fetchConsent(for familyID: String) async throws -> AnalyticsConsent? {
        return savedConsent
    }
}