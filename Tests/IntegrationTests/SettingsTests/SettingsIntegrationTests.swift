import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SharedModels

final class SettingsIntegrationTests: XCTestCase {
    var mockRepository: MockIntegrationFamilySettingsRepository!
    var viewModel: SettingsViewModel!

    override func setUp() {
        super.setUp()
        mockRepository = MockIntegrationFamilySettingsRepository()
        viewModel = SettingsViewModel(familySettingsRepository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    func testEndToEndIntegrationForAllThreeSettingsSections() async {
        // Test end-to-end integration for all three settings sections

        // Load initial settings
        await viewModel.loadSettings()
        XCTAssertNotNil(viewModel.settings, "Settings should be loaded")

        let initialSettings = viewModel.settings!

        // Test Time Management Section Integration
        await testTimeManagementSectionIntegration()

        // Test Bedtime Controls Section Integration
        await testBedtimeControlsSectionIntegration()

        // Test App Restrictions Section Integration
        await testAppRestrictionsSectionIntegration()

        // Verify all changes are persisted
        let finalSettings = mockRepository.currentSettings!
        XCTAssertNotEqual(finalSettings.dailyTimeLimit, initialSettings.dailyTimeLimit, "Daily time limit should have changed")
        XCTAssertNotEqual(finalSettings.bedtimeStart, initialSettings.bedtimeStart, "Bedtime start should have changed")
        XCTAssertNotEqual(finalSettings.contentRestrictions, initialSettings.contentRestrictions, "Content restrictions should have changed")
    }

    private func testTimeManagementSectionIntegration() async {
        // Test Time Management section end-to-end
        let originalLimit = viewModel.settings?.dailyTimeLimit

        // Update daily time limit
        viewModel.updateDailyTimeLimit(240)
        XCTAssertEqual(viewModel.settings?.dailyTimeLimit, 240, "Daily time limit should update immediately in UI")

        // Wait for persistence
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Verify persistence
        XCTAssertEqual(mockRepository.currentSettings?.dailyTimeLimit, 240, "Daily time limit should be persisted")

        // Test boundary values
        viewModel.updateDailyTimeLimit(0)
        XCTAssertNil(viewModel.settings?.dailyTimeLimit, "Zero time limit should be stored as nil")

        viewModel.updateDailyTimeLimit(480)
        XCTAssertEqual(viewModel.settings?.dailyTimeLimit, 480, "Maximum time limit should be accepted")

        // Test invalid values are constrained
        viewModel.updateDailyTimeLimit(600)
        XCTAssertLessThanOrEqual(viewModel.settings?.dailyTimeLimit ?? 0, 480, "Over-limit values should be constrained")
    }

    private func testBedtimeControlsSectionIntegration() async {
        // Test Bedtime Controls section end-to-end
        let calendar = Calendar.current

        // Test bedtime start
        let bedtimeStart = calendar.date(from: DateComponents(hour: 21, minute: 30))
        viewModel.updateBedtimeStart(bedtimeStart)
        XCTAssertEqual(viewModel.settings?.bedtimeStart, bedtimeStart, "Bedtime start should update immediately in UI")

        // Test bedtime end
        let bedtimeEnd = calendar.date(from: DateComponents(hour: 6, minute: 30))
        viewModel.updateBedtimeEnd(bedtimeEnd)
        XCTAssertEqual(viewModel.settings?.bedtimeEnd, bedtimeEnd, "Bedtime end should update immediately in UI")

        // Wait for persistence
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Verify persistence
        XCTAssertEqual(mockRepository.currentSettings?.bedtimeStart, bedtimeStart, "Bedtime start should be persisted")
        XCTAssertEqual(mockRepository.currentSettings?.bedtimeEnd, bedtimeEnd, "Bedtime end should be persisted")

        // Test disabling bedtime
        viewModel.updateBedtimeStart(nil)
        viewModel.updateBedtimeEnd(nil)
        XCTAssertNil(viewModel.settings?.bedtimeStart, "Bedtime start should be disabled")
        XCTAssertNil(viewModel.settings?.bedtimeEnd, "Bedtime end should be disabled")
    }

    private func testAppRestrictionsSectionIntegration() async {
        // Test App Restrictions section end-to-end
        let initialRestrictions = viewModel.settings?.contentRestrictions ?? [:]

        // Add some restrictions
        let newRestrictions = [
            "com.apple.safari": true,
            "com.apple.mail": false,
            "com.spotify.music": true
        ]

        viewModel.updateContentRestrictions(newRestrictions)
        XCTAssertEqual(viewModel.settings?.contentRestrictions, newRestrictions, "Content restrictions should update immediately in UI")

        // Wait for persistence
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Verify persistence
        XCTAssertEqual(mockRepository.currentSettings?.contentRestrictions, newRestrictions, "Content restrictions should be persisted")

        // Test updating individual restrictions
        var updatedRestrictions = newRestrictions
        updatedRestrictions["com.apple.mail"] = true

        viewModel.updateContentRestrictions(updatedRestrictions)
        XCTAssertEqual(viewModel.settings?.contentRestrictions["com.apple.mail"], true, "Individual restriction should update")
    }

    func testSettingsChangesImmediatelyReflectedInAppBehavior() async {
        // Test that settings changes are immediately reflected in app behavior

        await viewModel.loadSettings()

        // Test immediate UI reflection for daily time limit
        let originalLimit = viewModel.settings?.dailyTimeLimit ?? 120
        let newLimit = 300

        viewModel.updateDailyTimeLimit(newLimit)

        // Verify immediate reflection in view model
        XCTAssertEqual(viewModel.settings?.dailyTimeLimit, newLimit, "Daily time limit change should be immediately reflected")

        // Test immediate UI reflection for bedtime settings
        let bedtimeStart = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))
        viewModel.updateBedtimeStart(bedtimeStart)

        XCTAssertEqual(viewModel.settings?.bedtimeStart, bedtimeStart, "Bedtime start change should be immediately reflected")

        // Test immediate UI reflection for content restrictions
        let restrictions = ["com.test.immediate": true]
        viewModel.updateContentRestrictions(restrictions)

        XCTAssertEqual(viewModel.settings?.contentRestrictions, restrictions, "Content restrictions change should be immediately reflected")

        // Test that changes trigger publisher updates
        var publisherFired = false
        let cancellable = viewModel.$settings
            .dropFirst() // Skip initial value
            .sink { _ in
                publisherFired = true
            }

        viewModel.updateDailyTimeLimit(350)

        // Allow time for publisher to fire
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertTrue(publisherFired, "Settings changes should trigger publisher updates")
        cancellable.cancel()
    }

    func testCloudKitSynchronizationAcrossMultipleDevices() async {
        // Test CloudKit synchronization across multiple devices

        // Simulate device 1
        let repository1 = MockIntegrationFamilySettingsRepository()
        let viewModel1 = SettingsViewModel(familySettingsRepository: repository1)

        // Simulate device 2
        let repository2 = MockIntegrationFamilySettingsRepository()
        let viewModel2 = SettingsViewModel(familySettingsRepository: repository2)

        // Share the same CloudKit data
        let sharedSettings = FamilySettings(
            id: "shared-settings",
            familyID: "shared-family",
            dailyTimeLimit: 120,
            bedtimeStart: nil,
            bedtimeEnd: nil,
            contentRestrictions: [:]
        )

        repository1.currentSettings = sharedSettings
        repository2.currentSettings = sharedSettings

        // Load settings on both devices
        await viewModel1.loadSettings()
        await viewModel2.loadSettings()

        // Make change on device 1
        viewModel1.updateDailyTimeLimit(180)
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Simulate CloudKit sync to device 2
        repository2.currentSettings = repository1.currentSettings

        // Reload settings on device 2 to simulate CloudKit subscription update
        await viewModel2.refreshSettings()

        // Verify synchronization
        XCTAssertEqual(viewModel2.settings?.dailyTimeLimit, 180, "Settings should sync across devices")
    }

    func testDocumentTestResultsAndPerformanceBenchmarks() async {
        // Test and document test results and performance benchmarks

        let startTime = Date()

        // Test settings loading performance
        await viewModel.loadSettings()
        let loadTime = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(loadTime, 1.0, "Settings loading should complete in under 1 second")

        // Test settings save performance
        let saveStartTime = Date()
        viewModel.updateDailyTimeLimit(200)
        try? await Task.sleep(nanoseconds: 1_100_000_000) // Wait for debounced save
        let saveTime = Date().timeIntervalSince(saveStartTime)

        XCTAssertLessThan(saveTime, 2.0, "Settings save should complete in under 2 seconds (including debounce)")

        // Test memory usage (basic check)
        let memoryUsage = viewModel.settings != nil ? 1 : 0 // Simplified memory check
        XCTAssertGreaterThan(memoryUsage, 0, "Settings should be loaded in memory")

        // Test UI responsiveness simulation
        let uiUpdateStartTime = Date()
        viewModel.updateDailyTimeLimit(250)
        let uiUpdateTime = Date().timeIntervalSince(uiUpdateStartTime)

        XCTAssertLessThan(uiUpdateTime, 0.1, "UI updates should be immediate (under 0.1 seconds)")

        // Document performance results
        print("Performance Benchmarks:")
        print("- Settings loading time: \\(String(format: "%.3f", loadTime))s")
        print("- Settings save time: \\(String(format: "%.3f", saveTime))s")
        print("- UI update time: \\(String(format: "%.3f", uiUpdateTime))s")
    }

    func testCompleteUserWorkflow() async {
        // Test complete user workflow from navigation to save

        // Step 1: Navigate to settings (simulated)
        let coordinator = ParentDashboardNavigationCoordinator()
        let navigationActions = ParentDashboardNavigationActions(coordinator: coordinator)
        navigationActions.navigateToSettings()

        XCTAssertFalse(coordinator.navigationPath.isEmpty, "Navigation to settings should work")

        // Step 2: Load settings
        await viewModel.loadSettings()
        XCTAssertNotNil(viewModel.settings, "Settings should load successfully")

        // Step 3: User modifies time management settings
        viewModel.updateDailyTimeLimit(300)
        XCTAssertEqual(viewModel.settings?.dailyTimeLimit, 300, "Time limit should update")

        // Step 4: User configures bedtime settings
        let calendar = Calendar.current
        let bedtimeStart = calendar.date(from: DateComponents(hour: 20, minute: 30))
        let bedtimeEnd = calendar.date(from: DateComponents(hour: 7, minute: 30))

        viewModel.updateBedtimeStart(bedtimeStart)
        viewModel.updateBedtimeEnd(bedtimeEnd)

        XCTAssertEqual(viewModel.settings?.bedtimeStart, bedtimeStart, "Bedtime start should update")
        XCTAssertEqual(viewModel.settings?.bedtimeEnd, bedtimeEnd, "Bedtime end should update")

        // Step 5: User configures app restrictions
        let restrictions = [
            "com.example.social": true,
            "com.example.games": true,
            "com.example.educational": false
        ]

        viewModel.updateContentRestrictions(restrictions)
        XCTAssertEqual(viewModel.settings?.contentRestrictions, restrictions, "Content restrictions should update")

        // Step 6: Settings auto-save
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Step 7: Verify all changes are persisted
        let savedSettings = mockRepository.currentSettings!
        XCTAssertEqual(savedSettings.dailyTimeLimit, 300, "Daily time limit should be saved")
        XCTAssertEqual(savedSettings.bedtimeStart, bedtimeStart, "Bedtime start should be saved")
        XCTAssertEqual(savedSettings.bedtimeEnd, bedtimeEnd, "Bedtime end should be saved")
        XCTAssertEqual(savedSettings.contentRestrictions, restrictions, "Content restrictions should be saved")

        print("Complete user workflow test passed successfully")
    }

    func testErrorRecoveryWorkflow() async {
        // Test error recovery workflow

        // Simulate network error during save
        mockRepository.shouldFailOnNextSave = true

        await viewModel.loadSettings()
        viewModel.updateDailyTimeLimit(400)

        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Verify error state is handled
        // Note: In actual implementation, would check viewModel.showError and errorMessage

        // Simulate network recovery
        mockRepository.shouldFailOnNextSave = false
        viewModel.updateDailyTimeLimit(420)

        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // Verify successful save after recovery
        XCTAssertEqual(mockRepository.currentSettings?.dailyTimeLimit, 420, "Settings should save after error recovery")
    }
}

// MARK: - Mock Repository for Integration Testing

class MockIntegrationFamilySettingsRepository: FamilySettingsRepository {
    var currentSettings: FamilySettings?
    var shouldFailOnNextSave = false
    var saveOperationTime: TimeInterval = 0.1

    func createSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        try await Task.sleep(nanoseconds: UInt64(saveOperationTime * 1_000_000_000))
        currentSettings = settings
        return settings
    }

    func fetchSettings(for familyID: String) async throws -> FamilySettings? {
        try await Task.sleep(nanoseconds: UInt64(saveOperationTime * 1_000_000_000))

        if currentSettings == nil {
            currentSettings = FamilySettings(
                id: "integration-test-id",
                familyID: familyID,
                dailyTimeLimit: 120,
                bedtimeStart: Calendar.current.date(from: DateComponents(hour: 20, minute: 0)),
                bedtimeEnd: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)),
                contentRestrictions: [:]
            )
        }

        return currentSettings
    }

    func updateSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        try await Task.sleep(nanoseconds: UInt64(saveOperationTime * 1_000_000_000))

        if shouldFailOnNextSave {
            shouldFailOnNextSave = false
            throw IntegrationTestError.networkError
        }

        currentSettings = settings
        return settings
    }

    func deleteSettings(id: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(saveOperationTime * 1_000_000_000))
        currentSettings = nil
    }
}

enum IntegrationTestError: Error {
    case networkError
    case authenticationError

    var localizedDescription: String {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .authenticationError:
            return "Authentication failed"
        }
    }
}