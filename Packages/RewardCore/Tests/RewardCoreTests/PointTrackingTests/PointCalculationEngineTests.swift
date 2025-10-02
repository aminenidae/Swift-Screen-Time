import XCTest
@testable import RewardCore
@testable import SharedModels

final class PointCalculationEngineTests: XCTestCase {
    var engine: PointCalculationEngine!
    
    override func setUp() {
        super.setUp()
        engine = PointCalculationEngine()
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    func testPointCalculation_30MinutesAt10PerHourLearningCategory_Returns10Points() {
        // Given
        let duration: TimeInterval = 1800 // 30 minutes in seconds
        let pointsPerHour = 10
        let category: AppCategory = .learning
        
        // When
        let points = engine.calculatePoints(durationSeconds: duration, pointsPerHour: pointsPerHour, category: category)
        
        // Then
        XCTAssertEqual(points, 10, "30 minutes at 10 points per hour for learning category should equal 10 points")
    }
    
    func testPointCalculation_1HourAt20PerHourLearningCategory_Returns20Points() {
        // Given
        let duration: TimeInterval = 3600 // 1 hour in seconds
        let pointsPerHour = 20
        let category: AppCategory = .learning
        
        // When
        let points = engine.calculatePoints(durationSeconds: duration, pointsPerHour: pointsPerHour, category: category)
        
        // Then
        XCTAssertEqual(points, 20, "1 hour at 20 points per hour for learning category should equal 20 points")
    }
    
    func testPointCalculation_15MinutesAt40PerHourRewardCategory_Returns10Points() {
        // Given
        let duration: TimeInterval = 900 // 15 minutes in seconds
        let pointsPerHour = 40
        let category: AppCategory = .reward // Reward category gets 50% of points
        
        // When
        let points = engine.calculatePoints(durationSeconds: duration, pointsPerHour: pointsPerHour, category: category)
        
        // Then
        XCTAssertEqual(points, 10, "15 minutes at 40 points per hour for reward category should equal 10 points (50% of 20)")
    }
    
    func testPointCalculation_ZeroDuration_ReturnsZeroPoints() {
        // Given
        let duration: TimeInterval = 0
        let pointsPerHour = 10
        let category: AppCategory = .learning
        
        // When
        let points = engine.calculatePoints(durationSeconds: duration, pointsPerHour: pointsPerHour, category: category)
        
        // Then
        XCTAssertEqual(points, 0, "Zero duration should always result in zero points")
    }
    
    func testPointCalculation_ZeroPointsPerHour_ReturnsZeroPoints() {
        // Given
        let duration: TimeInterval = 3600 // 1 hour in seconds
        let pointsPerHour = 0
        let category: AppCategory = .learning
        
        // When
        let points = engine.calculatePoints(durationSeconds: duration, pointsPerHour: pointsPerHour, category: category)
        
        // Then
        XCTAssertEqual(points, 0, "Zero points per hour should always result in zero points")
    }
    
    func testValidation_CorrectCalculation_ReturnsTrue() {
        // Given
        let duration: TimeInterval = 1800 // 30 minutes
        let pointsPerHour = 10
        let category: AppCategory = .learning
        let expectedPoints = 10
        
        // When
        let isValid = engine.validateCalculation(
            durationSeconds: duration,
            pointsPerHour: pointsPerHour,
            category: category,
            expectedPoints: expectedPoints
        )
        
        // Then
        XCTAssertTrue(isValid, "Validation should pass for correct calculation")
    }
    
    func testValidation_IncorrectCalculation_ReturnsFalse() {
        // Given
        let duration: TimeInterval = 1800 // 30 minutes
        let pointsPerHour = 10
        let category: AppCategory = .learning
        let expectedPoints = 5 // Incorrect expectation
        
        // When
        let isValid = engine.validateCalculation(
            durationSeconds: duration,
            pointsPerHour: pointsPerHour,
            category: category,
            expectedPoints: expectedPoints
        )
        
        // Then
        XCTAssertFalse(isValid, "Validation should fail for incorrect calculation")
    }
    
    func testUsageSessionCalculation() {
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
        let points = engine.calculatePoints(for: session, pointsPerHour: 20)
        
        // Then
        XCTAssertEqual(points, 20, "1 hour of learning app usage should earn 20 points")
    }
}