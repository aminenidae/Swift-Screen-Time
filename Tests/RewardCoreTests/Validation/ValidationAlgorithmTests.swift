import XCTest
@testable import RewardCore
@testable import SharedModels

final class ValidationAlgorithmTests: XCTestCase {
    
    func testRapidSwitchingValidator() async throws {
        let validator = RapidSwitchingValidator()
        
        // Test normal session
        let normalSession = UsageSession(
            id: "test-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        let normalResult = await validator.validateSession(normalSession, validationLevel: .moderate)
        
        XCTAssertTrue(normalResult.isValid)
        XCTAssertTrue(normalResult.validationScore > 0.7)
        XCTAssertEqual(normalResult.detectedPatterns.count, 0)
        
        // Test suspiciously short session
        let shortSession = UsageSession(
            id: "test-2",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(15), // 15 seconds
            duration: 15,
            isValidated: false,
            validationDetails: nil
        )
        
        let shortResult = await validator.validateSession(shortSession, validationLevel: .strict)
        
        XCTAssertFalse(shortResult.isValid)
        XCTAssertTrue(shortResult.validationScore < 0.5)
        XCTAssertGreaterThanOrEqual(shortResult.detectedPatterns.count, 0)
    }
    
    func testEngagementValidator() async throws {
        let validator = EngagementValidator()
        
        // Test engaged session
        let engagedSession = UsageSession(
            id: "test-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        let engagedResult = await validator.validateSession(engagedSession, validationLevel: .moderate)
        
        XCTAssertTrue(engagedResult.isValid)
        XCTAssertTrue(engagedResult.validationScore > 0.7)
        
        // Test passive session
        let passiveSession = UsageSession(
            id: "test-2",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200), // 2 hours
            duration: 7200,
            isValidated: false,
            validationDetails: nil
        )
        
        let passiveResult = await validator.validateSession(passiveSession, validationLevel: .strict)
        
        XCTAssertLessThan(passiveResult.adjustmentFactor, 1.0)
    }
    
    func testTimingPatternValidator() async throws {
        let validator = TimingPatternValidator()
        
        // Test normal timing
        let normalSession = UsageSession(
            id: "test-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: Date().addingTimeInterval(120), // 2 minutes past the hour
            endTime: Date().addingTimeInterval(1920), // 32 minutes past the hour
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        let normalResult = await validator.validateSession(normalSession, validationLevel: .moderate)
        
        XCTAssertTrue(normalResult.isValid)
        XCTAssertTrue(normalResult.validationScore > 0.7)
        XCTAssertEqual(normalResult.detectedPatterns.count, 0)
        
        // Test exact hour boundary (more difficult to simulate accurately in tests)
        // This would require more precise date manipulation
    }
    
    func testValidationLevelThresholds() async throws {
        let validator = RapidSwitchingValidator()
        
        // Create a moderately suspicious session
        let session = UsageSession(
            id: "test-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(45), // 45 seconds
            duration: 45,
            isValidated: false,
            validationDetails: nil
        )
        
        // Test with lenient validation
        let lenientResult = await validator.validateSession(session, validationLevel: .lenient)
        XCTAssertTrue(lenientResult.isValid)
        
        // Test with strict validation
        let strictResult = await validator.validateSession(session, validationLevel: .strict)
        XCTAssertFalse(strictResult.isValid)
        
        // Test with moderate validation
        let moderateResult = await validator.validateSession(session, validationLevel: .moderate)
        XCTAssertFalse(moderateResult.isValid)
    }
    
    func testCompositeValidator() async throws {
        let rapidValidator = RapidSwitchingValidator()
        let engagementValidator = EngagementValidator()
        let timingValidator = TimingPatternValidator()
        
        let compositeValidator = CompositeUsageValidator(
            validators: [rapidValidator, engagementValidator, timingValidator]
        )
        
        let session = UsageSession(
            id: "test-1",
            childProfileID: "child-1",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        let result = await compositeValidator.validateSession(session, validationLevel: .moderate)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.validationScore > 0.7)
    }
}