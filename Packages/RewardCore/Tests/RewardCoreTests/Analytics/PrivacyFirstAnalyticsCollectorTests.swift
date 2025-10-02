import XCTest
@testable import RewardCore
@testable import SharedModels

final class PrivacyFirstAnalyticsCollectorTests: XCTestCase {
    var analyticsCollector: PrivacyFirstAnalyticsCollector!
    var mockAnalyticsService: MockAnalyticsService!
    var mockConsentService: MockAnalyticsConsentServiceForCollectorTests!
    
    override func setUp() {
        super.setUp()
        mockAnalyticsService = MockAnalyticsService()
        mockConsentService = MockAnalyticsConsentServiceForCollectorTests()
        analyticsCollector = PrivacyFirstAnalyticsCollector(
            analyticsService: mockAnalyticsService,
            consentService: mockConsentService
        )
    }
    
    override func tearDown() {
        analyticsCollector = nil
        mockAnalyticsService = nil
        mockConsentService = nil
        super.tearDown()
    }
    
    // MARK: - Feature Usage Tests
    
    func testTrackFeatureUsage_CallsAnalyticsService() async {
        // Given
        let feature = "testFeature"
        let metadata = ["key": "value"]
        
        // When
        await analyticsCollector.trackFeatureUsage(feature: feature, metadata: metadata)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackFeatureUsageCalled)
        XCTAssertEqual(mockAnalyticsService.lastFeature, feature)
        XCTAssertEqual(mockAnalyticsService.lastMetadata, metadata)
    }
    
    // MARK: - User Flow Tests
    
    func testTrackUserFlow_CallsAnalyticsService() async {
        // Given
        let flow = "testFlow"
        let step = "testStep"
        
        // When
        await analyticsCollector.trackUserFlow(flow: flow, step: step)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackUserFlowCalled)
        XCTAssertEqual(mockAnalyticsService.lastFlow, flow)
        XCTAssertEqual(mockAnalyticsService.lastStep, step)
    }
    
    // MARK: - Performance Tests
    
    func testTrackPerformance_CallsAnalyticsService() async {
        // Given
        let metric = "testMetric"
        let value = 1.5
        
        // When
        await analyticsCollector.trackPerformance(metric: metric, value: value)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackPerformanceCalled)
        XCTAssertEqual(mockAnalyticsService.lastMetric, metric)
        XCTAssertEqual(mockAnalyticsService.lastValue, value)
    }
    
    // MARK: - Error Tests
    
    func testTrackError_CallsAnalyticsService() async {
        // Given
        let category = "testCategory"
        let code = "testCode"
        
        // When
        await analyticsCollector.trackError(category: category, code: code)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackErrorCalled)
        XCTAssertEqual(mockAnalyticsService.lastCategory, category)
        XCTAssertEqual(mockAnalyticsService.lastCode, code)
    }
    
    // MARK: - Engagement Tests
    
    func testTrackEngagement_CallsAnalyticsService() async {
        // Given
        let type = "testType"
        let duration: TimeInterval = 30.0
        
        // When
        await analyticsCollector.trackEngagement(type: type, duration: duration)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackEngagementCalled)
        XCTAssertEqual(mockAnalyticsService.lastEngagementType, type)
        XCTAssertEqual(mockAnalyticsService.lastDuration, duration)
    }
}

// MARK: - Mock Classes

class MockAnalyticsService: AnalyticsService, @unchecked Sendable {
    var trackFeatureUsageCalled = false
    var trackUserFlowCalled = false
    var trackPerformanceCalled = false
    var trackErrorCalled = false
    var trackEngagementCalled = false

    var lastFeature: String?
    var lastMetadata: [String: String]?
    var lastFlow: String?
    var lastStep: String?
    var lastMetric: String?
    var lastValue: Double?
    var lastCategory: String?
    var lastCode: String?
    var lastEngagementType: String?
    var lastDuration: TimeInterval?

    init() {
        super.init(
            consentService: AnalyticsConsentService(),
            anonymizationService: DataAnonymizationService(),
            aggregationService: AnalyticsAggregationService()
        )
    }
    
    override func trackFeatureUsage(feature: String, metadata: [String : String]?) async {
        trackFeatureUsageCalled = true
        lastFeature = feature
        lastMetadata = metadata
    }
    
    override func trackUserFlow(flow: String, step: String) async {
        trackUserFlowCalled = true
        lastFlow = flow
        lastStep = step
    }
    
    override func trackPerformance(metric: String, value: Double) async {
        trackPerformanceCalled = true
        lastMetric = metric
        lastValue = value
    }
    
    override func trackError(category: String, code: String) async {
        trackErrorCalled = true
        lastCategory = category
        lastCode = code
    }
    
    override func trackEngagement(type: String, duration: TimeInterval) async {
        trackEngagementCalled = true
        lastEngagementType = type
        lastDuration = duration
    }
}

class MockAnalyticsConsentServiceForCollectorTests: AnalyticsConsentService, @unchecked Sendable {
    var currentConsentLevel: AnalyticsConsentLevel = .detailed
    
    override func isDetailedCollectionAllowed(for familyID: String) async -> Bool {
        return currentConsentLevel == .detailed
    }
    
    override func isEssentialCollectionAllowed(for familyID: String) async -> Bool {
        return currentConsentLevel == .essential || currentConsentLevel == .standard || currentConsentLevel == .detailed
    }
    
    override func isStandardCollectionAllowed(for familyID: String) async -> Bool {
        return currentConsentLevel == .standard || currentConsentLevel == .detailed
    }
}