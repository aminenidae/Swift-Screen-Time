import XCTest
@testable import RewardCore
@testable import SharedModels

final class ValidationModelsTests: XCTestCase {
    
    // MARK: - ValidationDetails Tests
    
    func testValidationDetailsInitialization() {
        // Given
        let validationScore = 0.85
        let confidenceLevel = 0.90
        let detectedPatterns: [GamingPattern] = [.exactHourBoundaries, .backgroundUsage]
        let engagementIndicators = EngagementMetrics(
            appStateChanges: 5,
            averageSessionLength: 1800,
            interactionDensity: 0.75,
            deviceMotionCorrelation: 0.8
        )
        let validatedAt = Date()
        let validationAlgorithmVersion = "1.0.0"
        
        // When
        let validationDetails = ValidationDetails(
            validationScore: validationScore,
            confidenceLevel: confidenceLevel,
            detectedPatterns: detectedPatterns,
            engagementIndicators: engagementIndicators,
            validatedAt: validatedAt,
            validationAlgorithmVersion: validationAlgorithmVersion
        )
        
        // Then
        XCTAssertEqual(validationDetails.validationScore, validationScore)
        XCTAssertEqual(validationDetails.confidenceLevel, confidenceLevel)
        XCTAssertEqual(validationDetails.detectedPatterns, detectedPatterns)
        XCTAssertEqual(validationDetails.engagementIndicators.appStateChanges, engagementIndicators.appStateChanges)
        XCTAssertEqual(validationDetails.engagementIndicators.averageSessionLength, engagementIndicators.averageSessionLength)
        XCTAssertEqual(validationDetails.engagementIndicators.interactionDensity, engagementIndicators.interactionDensity)
        XCTAssertEqual(validationDetails.engagementIndicators.deviceMotionCorrelation, engagementIndicators.deviceMotionCorrelation)
        XCTAssertEqual(validationDetails.validatedAt, validatedAt)
        XCTAssertEqual(validationDetails.validationAlgorithmVersion, validationAlgorithmVersion)
    }
    
    // MARK: - GamingPattern Tests
    
    func testGamingPatternCodable_RapidAppSwitching() throws {
        // Given
        let pattern = GamingPattern.rapidAppSwitching(frequency: 5.5)
        
        // When
        let data = try JSONEncoder().encode(pattern)
        let decodedPattern = try JSONDecoder().decode(GamingPattern.self, from: data)
        
        // Then
        if case .rapidAppSwitching(let frequency) = decodedPattern {
            XCTAssertEqual(frequency, 5.5)
        } else {
            XCTFail("Expected rapidAppSwitching pattern")
        }
    }
    
    func testGamingPatternCodable_SuspiciouslyLongSession() throws {
        // Given
        let duration: TimeInterval = 7200 // 2 hours
        let pattern = GamingPattern.suspiciouslyLongSession(duration: duration)
        
        // When
        let data = try JSONEncoder().encode(pattern)
        let decodedPattern = try JSONDecoder().decode(GamingPattern.self, from: data)
        
        // Then
        if case .suspiciouslyLongSession(let decodedDuration) = decodedPattern {
            XCTAssertEqual(decodedDuration, duration)
        } else {
            XCTFail("Expected suspiciouslyLongSession pattern")
        }
    }
    
    func testGamingPatternCodable_ExactHourBoundaries() throws {
        // Given
        let pattern = GamingPattern.exactHourBoundaries
        
        // When
        let data = try JSONEncoder().encode(pattern)
        let decodedPattern = try JSONDecoder().decode(GamingPattern.self, from: data)
        
        // Then
        if case .exactHourBoundaries = decodedPattern {
            // Success
        } else {
            XCTFail("Expected exactHourBoundaries pattern")
        }
    }
    
    func testGamingPatternCodable_DeviceLockDuringSession() throws {
        // Given
        let pattern = GamingPattern.deviceLockDuringSession
        
        // When
        let data = try JSONEncoder().encode(pattern)
        let decodedPattern = try JSONDecoder().decode(GamingPattern.self, from: data)
        
        // Then
        if case .deviceLockDuringSession = decodedPattern {
            // Success
        } else {
            XCTFail("Expected deviceLockDuringSession pattern")
        }
    }
    
    func testGamingPatternCodable_BackgroundUsage() throws {
        // Given
        let pattern = GamingPattern.backgroundUsage
        
        // When
        let data = try JSONEncoder().encode(pattern)
        let decodedPattern = try JSONDecoder().decode(GamingPattern.self, from: data)
        
        // Then
        if case .backgroundUsage = decodedPattern {
            // Success
        } else {
            XCTFail("Expected backgroundUsage pattern")
        }
    }
    
    // MARK: - EngagementMetrics Tests
    
    func testEngagementMetricsInitialization() {
        // Given
        let appStateChanges = 10
        let averageSessionLength: TimeInterval = 1800
        let interactionDensity = 0.85
        let deviceMotionCorrelation: Double? = 0.75
        
        // When
        let metrics = EngagementMetrics(
            appStateChanges: appStateChanges,
            averageSessionLength: averageSessionLength,
            interactionDensity: interactionDensity,
            deviceMotionCorrelation: deviceMotionCorrelation
        )
        
        // Then
        XCTAssertEqual(metrics.appStateChanges, appStateChanges)
        XCTAssertEqual(metrics.averageSessionLength, averageSessionLength)
        XCTAssertEqual(metrics.interactionDensity, interactionDensity)
        XCTAssertEqual(metrics.deviceMotionCorrelation, deviceMotionCorrelation)
    }
    
    // MARK: - ValidationLevel Tests
    
    func testValidationLevelInitialization() {
        XCTAssertEqual(ValidationLevel.lenient.rawValue, "lenient")
        XCTAssertEqual(ValidationLevel.moderate.rawValue, "moderate")
        XCTAssertEqual(ValidationLevel.strict.rawValue, "strict")
    }
    
    func testValidationLevelConfidenceThresholds() {
        XCTAssertEqual(ValidationLevel.lenient.confidenceThreshold, 0.90)
        XCTAssertEqual(ValidationLevel.moderate.confidenceThreshold, 0.75)
        XCTAssertEqual(ValidationLevel.strict.confidenceThreshold, 0.60)
    }
    
    func testValidationLevelAllCases() {
        let allCases = ValidationLevel.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.lenient))
        XCTAssertTrue(allCases.contains(.moderate))
        XCTAssertTrue(allCases.contains(.strict))
    }
    
    func testValidationLevelCodable() throws {
        // Given
        let level = ValidationLevel.moderate
        
        // When
        let data = try JSONEncoder().encode(level)
        let decodedLevel = try JSONDecoder().decode(ValidationLevel.self, from: data)
        
        // Then
        XCTAssertEqual(level, decodedLevel)
    }
    
    // MARK: - ValidationResult Tests
    
    func testValidationResultInitialization() {
        // Given
        let isValid = true
        let validationScore = 0.95
        let confidenceLevel = 0.85
        let detectedPatterns: [GamingPattern] = [.rapidAppSwitching(frequency: 3.0)]
        let engagementMetrics = EngagementMetrics(
            appStateChanges: 2,
            averageSessionLength: 3600,
            interactionDensity: 0.9,
            deviceMotionCorrelation: nil
        )
        let validationLevel = ValidationLevel.moderate
        let adjustmentFactor = 0.9
        
        // When
        let result = ValidationResult(
            isValid: isValid,
            validationScore: validationScore,
            confidenceLevel: confidenceLevel,
            detectedPatterns: detectedPatterns,
            engagementMetrics: engagementMetrics,
            validationLevel: validationLevel,
            adjustmentFactor: adjustmentFactor
        )
        
        // Then
        XCTAssertEqual(result.isValid, isValid)
        XCTAssertEqual(result.validationScore, validationScore)
        XCTAssertEqual(result.confidenceLevel, confidenceLevel)
        XCTAssertEqual(result.detectedPatterns, detectedPatterns)
        XCTAssertEqual(result.engagementMetrics.appStateChanges, engagementMetrics.appStateChanges)
        XCTAssertEqual(result.engagementMetrics.averageSessionLength, engagementMetrics.averageSessionLength)
        XCTAssertEqual(result.engagementMetrics.interactionDensity, engagementMetrics.interactionDensity)
        XCTAssertEqual(result.engagementMetrics.deviceMotionCorrelation, engagementMetrics.deviceMotionCorrelation)
        XCTAssertEqual(result.validationLevel, validationLevel)
        XCTAssertEqual(result.adjustmentFactor, adjustmentFactor)
    }
    
    func testValidationResultCodable() throws {
        // Given
        let result = ValidationResult(
            isValid: true,
            validationScore: 0.85,
            confidenceLevel: 0.90,
            detectedPatterns: [.exactHourBoundaries],
            engagementMetrics: EngagementMetrics(
                appStateChanges: 5,
                averageSessionLength: 1800,
                interactionDensity: 0.75,
                deviceMotionCorrelation: 0.8
            ),
            validationLevel: .strict,
            adjustmentFactor: 0.8
        )
        
        // When
        let data = try JSONEncoder().encode(result)
        let decodedResult = try JSONDecoder().decode(ValidationResult.self, from: data)
        
        // Then
        XCTAssertEqual(result.isValid, decodedResult.isValid)
        XCTAssertEqual(result.validationScore, decodedResult.validationScore)
        XCTAssertEqual(result.confidenceLevel, decodedResult.confidenceLevel)
        XCTAssertEqual(result.detectedPatterns, decodedResult.detectedPatterns)
        XCTAssertEqual(result.engagementMetrics.appStateChanges, decodedResult.engagementMetrics.appStateChanges)
        XCTAssertEqual(result.engagementMetrics.averageSessionLength, decodedResult.engagementMetrics.averageSessionLength)
        XCTAssertEqual(result.engagementMetrics.interactionDensity, decodedResult.engagementMetrics.interactionDensity)
        XCTAssertEqual(result.engagementMetrics.deviceMotionCorrelation, decodedResult.engagementMetrics.deviceMotionCorrelation)
        XCTAssertEqual(result.validationLevel, decodedResult.validationLevel)
        XCTAssertEqual(result.adjustmentFactor, decodedResult.adjustmentFactor)
    }
}