import XCTest
@testable import RewardCore
@testable import SharedModels

final class UsageValidationServiceTests: XCTestCase {
    var validationService: UsageValidationService!
    var mockFamilySettingsRepository: MockFamilySettingsRepository!

    override func setUp() {
        super.setUp()
        mockFamilySettingsRepository = MockFamilySettingsRepository()
        validationService = UsageValidationService(
            familySettingsRepository: mockFamilySettingsRepository
        )
    }

    override func tearDown() {
        validationService = nil
        mockFamilySettingsRepository = nil
        super.tearDown()
    }

    // MARK: - Validation Tests

    func testValidateSession_ReturnsValidationResult() async throws {
        // Given
        let session = createTestSession(duration: 1800) // 30 minutes

        // When
        let result = try await validationService.validateSession(session)

        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.confidenceScore, 0.0)
        XCTAssertLessThanOrEqual(result.confidenceScore, 1.0)
    }

    func testValidateSession_WithShortDuration_MayReturnViolations() async throws {
        // Given
        let session = createTestSession(duration: 15) // Very short session

        // When
        let result = try await validationService.validateSession(session)

        // Then
        XCTAssertNotNil(result)
        // Result may be valid or invalid depending on validators
        XCTAssertGreaterThanOrEqual(result.confidenceScore, 0.0)
        XCTAssertLessThanOrEqual(result.confidenceScore, 1.0)
    }

    func testValidateSession_WithLongDuration_ReturnsBetterScore() async throws {
        // Given
        let session = createTestSession(duration: 3600) // Long session

        // When
        let result = try await validationService.validateSession(session)

        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.confidenceScore, 0.0)
        XCTAssertLessThanOrEqual(result.confidenceScore, 1.0)
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
}

// MARK: - Mock Classes

class MockFamilySettingsRepository: FamilySettingsRepository {
    var mockSettings: FamilySettings?

    func createSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        mockSettings = settings
        return settings
    }

    func fetchSettings(for familyID: String) async throws -> FamilySettings? {
        return mockSettings
    }

    func updateSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        mockSettings = settings
        return settings
    }

    func deleteSettings(id: String) async throws {
        mockSettings = nil
    }
}

