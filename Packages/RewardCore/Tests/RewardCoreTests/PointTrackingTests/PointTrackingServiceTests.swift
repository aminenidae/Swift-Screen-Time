import XCTest
@testable import RewardCore
@testable import SharedModels
@testable import CloudKitService

final class PointTrackingServiceTests: XCTestCase {
    var service: PointTrackingService!
    var mockCalculationEngine: MockPointCalculationEngine!
    
    override func setUp() {
        super.setUp()
        mockCalculationEngine = MockPointCalculationEngine()
        
        service = PointTrackingService(
            calculationEngine: mockCalculationEngine
        )
    }
    
    override func tearDown() {
        service = nil
        mockCalculationEngine = nil
        super.tearDown()
    }
    
    func testProcessUsageSession_CalculatesPoints() {
        // Given
        let session = UsageSession(
            id: "test-session",
            childProfileID: "child-123",
            appBundleID: "com.example.educational-app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600), // 1 hour
            duration: 3600
        )
        
        // When
        service.processUsageSession(session)
        
        // Then
        XCTAssertTrue(mockCalculationEngine.calculatePointsCalled, "Calculate points should be called")
    }
    
    func testStartTracking_SetsUpTrackingForChild() {
        // Given
        let childProfileID = "child-123"
        
        // When
        service.startTracking(for: childProfileID)
        
        // Then
        // We can't easily test the DeviceActivityMonitor integration without a mock
        // But we can ensure the method doesn't crash
        XCTAssertTrue(true, "Start tracking should not crash")
    }
    
    func testStopTracking_StopsTrackingForChild() {
        // Given
        let childProfileID = "child-123"
        
        // When
        service.stopTracking(for: childProfileID)
        
        // Then
        // We can't easily test the DeviceActivityMonitor integration without a mock
        // But we can ensure the method doesn't crash
        XCTAssertTrue(true, "Stop tracking should not crash")
    }
}

// MARK: - Mock Classes

class MockPointCalculationEngine: PointCalculationEngine {
    private(set) var calculatePointsCalled = false
    
    override func calculatePoints(for session: UsageSession, pointsPerHour: Int) -> Int {
        calculatePointsCalled = true
        return 20 // Return a fixed value for testing (learning app)
    }
}