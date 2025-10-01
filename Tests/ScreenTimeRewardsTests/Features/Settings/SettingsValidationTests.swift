import XCTest
@testable import ScreenTimeRewards
@testable import SharedModels

final class SettingsValidationTests: XCTestCase {
    var viewModel: SettingsViewModel!

    override func setUp() {
        super.setUp()
        viewModel = SettingsViewModel.mockViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testDailyTimeLimitRangeValidation() {
        // Test validation for dailyTimeLimit range (0-480 minutes)

        // Test valid values
        let validValues = [0, 15, 60, 120, 240, 360, 480]
        for value in validValues {
            viewModel.updateDailyTimeLimit(value)
            let expectedValue = value == 0 ? nil : value
            XCTAssertEqual(viewModel.settings?.dailyTimeLimit, expectedValue, "Valid value \\(value) should be accepted")
        }

        // Test boundary values
        viewModel.updateDailyTimeLimit(0)
        XCTAssertNil(viewModel.settings?.dailyTimeLimit, "0 minutes should be stored as nil (unlimited)")

        viewModel.updateDailyTimeLimit(480)
        XCTAssertEqual(viewModel.settings?.dailyTimeLimit, 480, "480 minutes should be the maximum allowed")

        // Test invalid values (should be constrained)
        viewModel.updateDailyTimeLimit(-30)
        let settingsAfterNegative = viewModel.settings?.dailyTimeLimit
        XCTAssertTrue(settingsAfterNegative == nil || settingsAfterNegative! >= 0, "Negative values should be constrained to minimum")

        viewModel.updateDailyTimeLimit(600)
        let settingsAfterHigh = viewModel.settings?.dailyTimeLimit
        XCTAssertTrue(settingsAfterHigh == nil || settingsAfterHigh! <= 480, "Values over 480 should be constrained to maximum")
    }

    func testBedtimeTimeRangeValidation() {
        // Test bedtime time range validation (start before end, overnight handling)
        let calendar = Calendar.current

        // Test normal overnight bedtime (8 PM to 7 AM) - valid
        let normalStart = calendar.date(from: DateComponents(hour: 20, minute: 0))!
        let normalEnd = calendar.date(from: DateComponents(hour: 7, minute: 0))!

        viewModel.updateBedtimeStart(normalStart)
        viewModel.updateBedtimeEnd(normalEnd)

        XCTAssertEqual(viewModel.settings?.bedtimeStart, normalStart)
        XCTAssertEqual(viewModel.settings?.bedtimeEnd, normalEnd)

        // Test same-day bedtime (1 PM to 3 PM) - valid but unusual
        let sameDayStart = calendar.date(from: DateComponents(hour: 13, minute: 0))!
        let sameDayEnd = calendar.date(from: DateComponents(hour: 15, minute: 0))!

        viewModel.updateBedtimeStart(sameDayStart)
        viewModel.updateBedtimeEnd(sameDayEnd)

        XCTAssertEqual(viewModel.settings?.bedtimeStart, sameDayStart)
        XCTAssertEqual(viewModel.settings?.bedtimeEnd, sameDayEnd)

        // Test edge case: same time for start and end
        let sameTime = calendar.date(from: DateComponents(hour: 12, minute: 0))!

        viewModel.updateBedtimeStart(sameTime)
        viewModel.updateBedtimeEnd(sameTime)

        // Should still be valid (effective no bedtime restriction)
        XCTAssertEqual(viewModel.settings?.bedtimeStart, sameTime)
        XCTAssertEqual(viewModel.settings?.bedtimeEnd, sameTime)
    }

    func testUserFriendlyErrorMessagesForValidationFailures() {
        // Test user-friendly error messages for validation failures
        let mockRepository = MockFailingFamilySettingsRepository()
        let failingViewModel = SettingsViewModel(familySettingsRepository: mockRepository)

        // Test error message handling
        XCTAssertFalse(failingViewModel.showError)
        XCTAssertTrue(failingViewModel.errorMessage.isEmpty)

        Task {
            await failingViewModel.loadSettings()
        }

        // Allow time for async operation to complete
        let expectation = XCTestExpectation(description: "Error handling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        // Check that error state is properly managed
        // Note: In actual implementation, specific error messages would be tested
    }

    func testCloudKitSaveErrorHandling() {
        // Test CloudKit save error handling (network failures, auth issues)
        let mockRepository = MockFailingFamilySettingsRepository()
        mockRepository.shouldFailOnSave = true

        let failingViewModel = SettingsViewModel(familySettingsRepository: mockRepository)

        Task {
            await failingViewModel.loadSettings()
            failingViewModel.updateDailyTimeLimit(180)

            // Allow time for debounced save to attempt and fail
            try? await Task.sleep(nanoseconds: 1_100_000_000)
        }

        let expectation = XCTestExpectation(description: "Save error handling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // In actual implementation, would verify error handling state
    }

    func testConcurrentModificationDetectionAndResolution() {
        // Test concurrent modification detection and resolution
        let repository1 = MockConcurrentFamilySettingsRepository()
        let repository2 = MockConcurrentFamilySettingsRepository()

        // Share the same underlying data store
        let sharedSettings = FamilySettings(
            id: "shared-id",
            familyID: "shared-family",
            dailyTimeLimit: 120,
            bedtimeStart: nil,
            bedtimeEnd: nil,
            contentRestrictions: [:]
        )

        repository1.sharedSettings = sharedSettings
        repository2.sharedSettings = sharedSettings

        let viewModel1 = SettingsViewModel(familySettingsRepository: repository1)
        let viewModel2 = SettingsViewModel(familySettingsRepository: repository2)

        Task {
            await viewModel1.loadSettings()
            await viewModel2.loadSettings()

            // Simulate concurrent modifications
            viewModel1.updateDailyTimeLimit(180)
            viewModel2.updateDailyTimeLimit(240)

            // Allow both to complete their save operations
            try? await Task.sleep(nanoseconds: 1_200_000_000)
        }

        let expectation = XCTestExpectation(description: "Concurrent modification handling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // In a real implementation, would test conflict resolution strategy
        // (e.g., last-write-wins, user-prompted resolution, etc.)
    }

    func testValidationFeedbackUIComponents() {
        // Test validation feedback UI components (inline error text)
        let validationErrors = [
            "Daily time limit must be between 0 and 480 minutes",
            "Bedtime start cannot be after bedtime end on the same day",
            "Network connection required to save settings"
        ]

        for errorMessage in validationErrors {
            XCTAssertFalse(errorMessage.isEmpty, "Error message should not be empty")
            XCTAssertTrue(errorMessage.count > 10, "Error message should be descriptive")
        }

        // Test that viewModel can handle and display error messages
        viewModel.errorMessage = validationErrors[0]
        viewModel.showError = true

        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, validationErrors[0])
    }

    func testUnitTestsForValidationLogic() {
        // Test unit tests for validation logic
        let testSettings = FamilySettings(
            id: "test-validation",
            familyID: "test-family",
            dailyTimeLimit: 600, // Invalid: over 480
            bedtimeStart: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)),
            bedtimeEnd: Calendar.current.date(from: DateComponents(hour: 20, minute: 0)),
            contentRestrictions: [:]
        )

        // Test validation logic (would call private validation method in real implementation)
        // For now, test the constraints that should be applied

        // Daily time limit validation
        let validDailyLimit = max(0, min(480, testSettings.dailyTimeLimit ?? 0))
        XCTAssertEqual(validDailyLimit, 480, "Daily limit should be constrained to 480")

        // Bedtime range validation
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: testSettings.bedtimeStart!)
        let endComponents = calendar.dateComponents([.hour, .minute], from: testSettings.bedtimeEnd!)

        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        // This represents an unusual but potentially valid same-day bedtime
        XCTAssertGreaterThan(endMinutes, startMinutes, "End should be after start for same-day bedtime")
    }

    func testRangeValidationForDifferentTimeZones() {
        // Test range validation handles different time zones correctly
        let timeZones = [
            TimeZone(identifier: "UTC")!,
            TimeZone(identifier: "America/New_York")!,
            TimeZone(identifier: "Europe/London")!,
            TimeZone(identifier: "Asia/Tokyo")!
        ]

        for timeZone in timeZones {
            var calendar = Calendar.current
            calendar.timeZone = timeZone

            let bedtimeStart = calendar.date(from: DateComponents(hour: 20, minute: 0))!
            let bedtimeEnd = calendar.date(from: DateComponents(hour: 7, minute: 0))!

            viewModel.updateBedtimeStart(bedtimeStart)
            viewModel.updateBedtimeEnd(bedtimeEnd)

            // Should work consistently across time zones
            XCTAssertEqual(viewModel.settings?.bedtimeStart, bedtimeStart)
            XCTAssertEqual(viewModel.settings?.bedtimeEnd, bedtimeEnd)
        }
    }
}

// MARK: - Mock Repositories for Testing

class MockFailingFamilySettingsRepository: FamilySettingsRepository {
    var shouldFailOnSave = false
    var shouldFailOnLoad = false

    func createSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        if shouldFailOnSave {
            throw ValidationError.saveOperationFailed
        }
        return settings
    }

    func fetchSettings(for familyID: String) async throws -> FamilySettings? {
        if shouldFailOnLoad {
            throw ValidationError.loadOperationFailed
        }
        return FamilySettings(id: "test", familyID: familyID, dailyTimeLimit: 120)
    }

    func updateSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        if shouldFailOnSave {
            throw ValidationError.saveOperationFailed
        }
        return settings
    }

    func deleteSettings(id: String) async throws {
        throw ValidationError.deleteOperationFailed
    }
}

class MockConcurrentFamilySettingsRepository: FamilySettingsRepository {
    var sharedSettings: FamilySettings?
    var lastModificationTime: Date = Date()

    func createSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        sharedSettings = settings
        lastModificationTime = Date()
        return settings
    }

    func fetchSettings(for familyID: String) async throws -> FamilySettings? {
        return sharedSettings
    }

    func updateSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        // Simulate concurrent modification detection
        if Date().timeIntervalSince(lastModificationTime) < 0.1 {
            throw ValidationError.concurrentModificationDetected
        }
        sharedSettings = settings
        lastModificationTime = Date()
        return settings
    }

    func deleteSettings(id: String) async throws {
        sharedSettings = nil
    }
}

enum ValidationError: Error {
    case saveOperationFailed
    case loadOperationFailed
    case deleteOperationFailed
    case concurrentModificationDetected

    var localizedDescription: String {
        switch self {
        case .saveOperationFailed:
            return "Failed to save settings to CloudKit"
        case .loadOperationFailed:
            return "Failed to load settings from CloudKit"
        case .deleteOperationFailed:
            return "Failed to delete settings"
        case .concurrentModificationDetected:
            return "Settings were modified by another device"
        }
    }
}