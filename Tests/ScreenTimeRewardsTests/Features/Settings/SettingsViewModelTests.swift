import XCTest
import Combine
@testable import ScreenTimeRewards
@testable import SharedModels

final class SettingsViewModelTests: XCTestCase {
    var viewModel: SettingsViewModel!
    var mockRepository: MockFamilySettingsRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockFamilySettingsRepository()
        viewModel = SettingsViewModel(familySettingsRepository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    func testSettingsViewModelWithFamilySettingsRepositoryIntegration() async {
        // Test that SettingsViewModel integrates with FamilySettingsRepository
        XCTAssertNotNil(viewModel)

        // Test loading settings
        await viewModel.loadSettings()

        XCTAssertNotNil(viewModel.settings)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCloudKitSaveOperationsForAllFamilySettingsFields() async {
        // Test CloudKit save operations for all FamilySettings fields
        await viewModel.loadSettings()

        let originalSettings = viewModel.settings!

        // Test dailyTimeLimit save
        viewModel.updateDailyTimeLimit(180)
        try? await Task.sleep(nanoseconds: 1_100_000_000) // Wait for debounce + save
        XCTAssertEqual(mockRepository.lastUpdatedSettings?.dailyTimeLimit, 180)

        // Test bedtimeStart save
        let newBedtimeStart = Calendar.current.date(from: DateComponents(hour: 21, minute: 0))
        viewModel.updateBedtimeStart(newBedtimeStart)
        try? await Task.sleep(nanoseconds: 1_100_000_000) // Wait for debounce + save
        XCTAssertEqual(mockRepository.lastUpdatedSettings?.bedtimeStart, newBedtimeStart)

        // Test bedtimeEnd save
        let newBedtimeEnd = Calendar.current.date(from: DateComponents(hour: 6, minute: 30))
        viewModel.updateBedtimeEnd(newBedtimeEnd)
        try? await Task.sleep(nanoseconds: 1_100_000_000) // Wait for debounce + save
        XCTAssertEqual(mockRepository.lastUpdatedSettings?.bedtimeEnd, newBedtimeEnd)

        // Test contentRestrictions save
        let newRestrictions = ["com.test.app": true]
        viewModel.updateContentRestrictions(newRestrictions)
        try? await Task.sleep(nanoseconds: 1_100_000_000) // Wait for debounce + save
        XCTAssertEqual(mockRepository.lastUpdatedSettings?.contentRestrictions, newRestrictions)
    }

    func testCombinePublishersForRealTimeSettingsSynchronization() {
        // Test Combine publishers for real-time settings synchronization
        var settingsUpdates: [FamilySettings?] = []
        var loadingStates: [Bool] = []
        var savingStates: [Bool] = []

        // Subscribe to publishers
        viewModel.$settings
            .sink { settings in
                settingsUpdates.append(settings)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        viewModel.$isSaving
            .sink { isSaving in
                savingStates.append(isSaving)
            }
            .store(in: &cancellables)

        // Trigger updates
        Task {
            await viewModel.loadSettings()
            viewModel.updateDailyTimeLimit(240)
        }

        // Allow time for async operations
        let expectation = XCTestExpectation(description: "Publishers updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertFalse(settingsUpdates.isEmpty)
        XCTAssertFalse(loadingStates.isEmpty)
    }

    func testLoadingStateManagementWithVisualIndicators() async {
        // Test loading state management with visual indicators
        XCTAssertFalse(viewModel.isLoading)

        let loadingTask = Task {
            await viewModel.loadSettings()
        }

        // Check loading state during operation
        XCTAssertTrue(viewModel.isLoading)

        await loadingTask.value

        // Check loading state after operation
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSyncConfirmationUI() async {
        // Test sync confirmation UI (success indicators, timestamp display)
        await viewModel.loadSettings()

        XCTAssertNil(viewModel.lastSaveTime)

        // Trigger a save operation
        viewModel.updateDailyTimeLimit(300)
        try? await Task.sleep(nanoseconds: 1_100_000_000) // Wait for debounce + save

        XCTAssertNotNil(viewModel.lastSaveTime)
        XCTAssertFalse(viewModel.lastSaveTimeFormatted.isEmpty)
    }

    func testCloudKitSubscriptionUpdatesForMultiDeviceSync() {
        // Test CloudKit subscription updates for multi-device sync
        // Note: This would typically require a more complex setup with CloudKit mocking
        let settingsViewModel = SettingsViewModel(familySettingsRepository: mockRepository)

        XCTAssertNotNil(settingsViewModel)

        // Test that viewModel can handle external updates (simulating CloudKit subscriptions)
        let externalUpdate = FamilySettings(
            id: "test-id",
            familyID: "test-family",
            dailyTimeLimit: 360,
            bedtimeStart: nil,
            bedtimeEnd: nil,
            contentRestrictions: [:]
        )

        // Simulate external update
        Task {
            await settingsViewModel.loadSettings()
            settingsViewModel.settings = externalUpdate
        }

        let expectation = XCTestExpectation(description: "External update processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testIntegrationTestsForDataPersistence() async {
        // Test integration tests for data persistence
        await viewModel.loadSettings()

        let originalSettings = viewModel.settings!

        // Test complete data persistence cycle
        viewModel.updateDailyTimeLimit(420)
        viewModel.updateBedtimeStart(Calendar.current.date(from: DateComponents(hour: 22, minute: 0)))
        viewModel.updateBedtimeEnd(Calendar.current.date(from: DateComponents(hour: 6, minute: 0)))
        viewModel.updateContentRestrictions(["com.integration.test": true])

        // Wait for all saves to complete
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Verify all changes were persisted
        let savedSettings = mockRepository.lastUpdatedSettings!
        XCTAssertEqual(savedSettings.dailyTimeLimit, 420)
        XCTAssertNotNil(savedSettings.bedtimeStart)
        XCTAssertNotNil(savedSettings.bedtimeEnd)
        XCTAssertEqual(savedSettings.contentRestrictions["com.integration.test"], true)
    }

    func testDebouncedSaveOperations() async {
        // Test that multiple rapid changes are debounced
        await viewModel.loadSettings()

        let saveCountBefore = mockRepository.updateCallCount

        // Make multiple rapid changes
        viewModel.updateDailyTimeLimit(100)
        viewModel.updateDailyTimeLimit(150)
        viewModel.updateDailyTimeLimit(200)
        viewModel.updateDailyTimeLimit(250)

        // Wait for debounce period to pass
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        let saveCountAfter = mockRepository.updateCallCount

        // Should only save once due to debouncing
        XCTAssertEqual(saveCountAfter - saveCountBefore, 1)
        XCTAssertEqual(mockRepository.lastUpdatedSettings?.dailyTimeLimit, 250)
    }
}

// MARK: - Mock Repository

class MockFamilySettingsRepository: FamilySettingsRepository {
    var mockSettings: FamilySettings?
    var lastUpdatedSettings: FamilySettings?
    var updateCallCount = 0
    var shouldThrowError = false

    func createSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed
        }
        mockSettings = settings
        return settings
    }

    func fetchSettings(for familyID: String) async throws -> FamilySettings? {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed
        }

        if mockSettings == nil {
            // Return default settings for testing
            mockSettings = FamilySettings(
                id: "mock-settings-id",
                familyID: familyID,
                dailyTimeLimit: 120,
                bedtimeStart: Calendar.current.date(from: DateComponents(hour: 20, minute: 0)),
                bedtimeEnd: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)),
                contentRestrictions: [:]
            )
        }

        return mockSettings
    }

    func updateSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed
        }
        updateCallCount += 1
        lastUpdatedSettings = settings
        mockSettings = settings
        return settings
    }

    func deleteSettings(id: String) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed
        }
        mockSettings = nil
    }
}

enum MockRepositoryError: Error {
    case operationFailed
}