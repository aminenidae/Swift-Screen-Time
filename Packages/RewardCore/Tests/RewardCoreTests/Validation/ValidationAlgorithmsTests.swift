import XCTest
@testable import RewardCore
@testable import SharedModels

final class ValidationAlgorithmsTests: XCTestCase {

    // MARK: - RapidSwitchingValidator Tests

    func testRapidSwitchingValidatorInitialization() {
        // When
        let validator = RapidSwitchingValidator()

        // Then
        XCTAssertNotNil(validator)
        XCTAssertEqual(validator.validatorName, "RapidSwitchingValidator")
    }

    func testRapidSwitchingValidator_ValidateSession_ShortDuration_ReturnsSuspiciousResult() async {
        // Given
        let validator = RapidSwitchingValidator()
        let session = createTestSession(duration: 15) // 15 seconds - very short
        let familySettings = createTestFamilySettings()

        // When
        let result = await validator.validate(session: session, familySettings: familySettings)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.violation, .frequency)
    }

    func testRapidSwitchingValidator_ValidateSession_LongDuration_ReturnsValidResult() async {
        // Given
        let validator = RapidSwitchingValidator()
        let session = createTestSession(duration: 3600) // 1 hour - long session
        let familySettings = createTestFamilySettings()

        // When
        let result = await validator.validate(session: session, familySettings: familySettings)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.violation)
    }

    // MARK: - EngagementValidator Tests

    func testEngagementValidatorInitialization() {
        // When
        let validator = EngagementValidator()

        // Then
        XCTAssertNotNil(validator)
        XCTAssertEqual(validator.validatorName, "EngagementValidator")
    }

    func testEngagementValidator_ValidateSession_ReturnsResult() async {
        // Given
        let validator = EngagementValidator()
        let session = createTestSession(duration: 1800) // 30 minutes
        let familySettings = createTestFamilySettings()

        // When
        let result = await validator.validate(session: session, familySettings: familySettings)

        // Then
        // Result should be valid or invalid based on implementation
        XCTAssertNotNil(result)
    }

    // MARK: - TimingPatternValidator Tests

    func testTimingPatternValidatorInitialization() {
        // When
        let validator = TimingPatternValidator()

        // Then
        XCTAssertNotNil(validator)
        XCTAssertEqual(validator.validatorName, "TimingPatternValidator")
    }

    func testTimingPatternValidator_ValidateSession_ReturnsResult() async {
        // Given
        let validator = TimingPatternValidator()
        let session = createTestSession(duration: 1800) // 30 minutes
        let familySettings = createTestFamilySettings()

        // When
        let result = await validator.validate(session: session, familySettings: familySettings)

        // Then
        // Result should be valid or invalid based on implementation
        XCTAssertNotNil(result)
    }

    // MARK: - Helper Methods

    private func createTestSession(duration: TimeInterval) -> UsageSession {
        let now = Date()
        let endTime = now.addingTimeInterval(duration)

        return UsageSession(
            id: "test-session-\(UUID().uuidString)",
            childProfileID: "child-123",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: now,
            endTime: endTime,
            duration: duration,
            isValidated: false
        )
    }

    private func createTestFamilySettings() -> FamilySettings {
        return FamilySettings(
            id: "test-family-\(UUID().uuidString)",
            familyID: "family-123",
            dailyTimeLimit: nil,
            bedtimeStart: nil,
            bedtimeEnd: nil,
            contentRestrictions: [:]
        )
    }
}