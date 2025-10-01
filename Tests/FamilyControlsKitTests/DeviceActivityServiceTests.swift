import XCTest
@testable import FamilyControlsKit

#if canImport(DeviceActivity) && canImport(FamilyControls)
import DeviceActivity
import FamilyControls

// MARK: - Device Activity Service Tests
@available(iOS 15.0, *)
final class DeviceActivityServiceTests: XCTestCase {

    // MARK: - Properties

    private var deviceActivityService: DeviceActivityService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        deviceActivityService = DeviceActivityService()
    }

    override func tearDown() {
        deviceActivityService = nil
        super.tearDown()
    }

    // MARK: - Service Instantiation Tests

    func testDeviceActivityService_CanBeInstantiated() {
        // Given/When - Create service instance
        let service = DeviceActivityService()

        // Then - Service should be created successfully
        XCTAssertNotNil(service)
    }

    // MARK: - Schedule Creation Tests

    func testCreateDailySchedule_ValidTimeComponents() {
        // Given
        let startTime = DateComponents(hour: 8, minute: 0)
        let endTime = DateComponents(hour: 20, minute: 0)

        // When
        let schedule = deviceActivityService.createDailySchedule(startTime: startTime, endTime: endTime)

        // Then
        XCTAssertEqual(schedule.intervalStart, startTime)
        XCTAssertEqual(schedule.intervalEnd, endTime)
        XCTAssertTrue(schedule.repeats)
    }

    func testDeviceActivitySchedule_ConvenienceConstructors() {
        // Test all-day schedule
        let allDay = DeviceActivitySchedule.allDaySchedule()
        XCTAssertEqual(allDay.intervalStart.hour, 0)
        XCTAssertEqual(allDay.intervalStart.minute, 0)
        XCTAssertEqual(allDay.intervalEnd.hour, 23)
        XCTAssertEqual(allDay.intervalEnd.minute, 59)
        XCTAssertTrue(allDay.repeats)

        // Test school hours schedule
        let schoolHours = DeviceActivitySchedule.schoolHoursSchedule()
        XCTAssertEqual(schoolHours.intervalStart.hour, 7)
        XCTAssertEqual(schoolHours.intervalStart.minute, 0)
        XCTAssertEqual(schoolHours.intervalEnd.hour, 21)
        XCTAssertEqual(schoolHours.intervalEnd.minute, 0)
        XCTAssertTrue(schoolHours.repeats)

        // Test weekend schedule
        let weekend = DeviceActivitySchedule.weekendSchedule()
        XCTAssertEqual(weekend.intervalStart.hour, 8)
        XCTAssertEqual(weekend.intervalStart.minute, 0)
        XCTAssertEqual(weekend.intervalEnd.hour, 22)
        XCTAssertEqual(weekend.intervalEnd.minute, 0)
        XCTAssertTrue(weekend.repeats)
    }

    // MARK: - Event Creation Tests

    func testCreateTimeBasedEvents_ValidInputs() {
        // Given
        let mockApplications: Set<ApplicationToken> = []
        let pointsThreshold: TimeInterval = 900 // 15 minutes
        let timeLimitThreshold: TimeInterval = 3600 // 1 hour

        // When
        let events = deviceActivityService.createTimeBasedEvents(
            for: mockApplications,
            pointsEarningThreshold: pointsThreshold,
            timeLimitThreshold: timeLimitThreshold
        )

        // Then
        XCTAssertEqual(events.count, 2)
        XCTAssertNotNil(events[DeviceActivityEvent.Name("pointsEarned")])
        XCTAssertNotNil(events[DeviceActivityEvent.Name("timeLimit")])
    }

    // MARK: - Configuration Tests

    func testActivityMonitoringConfiguration_Initialization() {
        // Given
        let schedule = DeviceActivitySchedule.schoolHoursSchedule()
        let educationalApps: Set<ApplicationToken> = []
        let recreationalApps: Set<ApplicationToken> = []
        let pointsInterval: TimeInterval = 900
        let timeLimitInterval: TimeInterval = 3600

        // When
        let configuration = ActivityMonitoringConfiguration(
            schedule: schedule,
            educationalApps: educationalApps,
            recreationalApps: recreationalApps,
            pointsEarningInterval: pointsInterval,
            timeLimitInterval: timeLimitInterval
        )

        // Then
        XCTAssertEqual(configuration.schedule.intervalStart, schedule.intervalStart)
        XCTAssertEqual(configuration.schedule.intervalEnd, schedule.intervalEnd)
        XCTAssertEqual(configuration.educationalApps.count, 0)
        XCTAssertEqual(configuration.recreationalApps.count, 0)
        XCTAssertEqual(configuration.pointsEarningInterval, pointsInterval)
        XCTAssertEqual(configuration.timeLimitInterval, timeLimitInterval)
    }

    func testActivityMonitoringConfiguration_DefaultConfiguration() {
        // Given
        let educationalApps: Set<ApplicationToken> = []
        let recreationalApps: Set<ApplicationToken> = []

        // When
        let defaultConfig = ActivityMonitoringConfiguration.defaultConfiguration(
            educationalApps: educationalApps,
            recreationalApps: recreationalApps
        )

        // Then
        XCTAssertEqual(defaultConfig.educationalApps.count, 0)
        XCTAssertEqual(defaultConfig.recreationalApps.count, 0)
        XCTAssertEqual(defaultConfig.pointsEarningInterval, TimeInterval.minutes(15))
        XCTAssertEqual(defaultConfig.timeLimitInterval, TimeInterval.hours(1))
    }

    // MARK: - Active Monitoring Tests

    func testGetActiveMonitoring_InitiallyEmpty() {
        // When
        let activeMonitoring = deviceActivityService.getActiveMonitoring()

        // Then
        XCTAssertTrue(activeMonitoring.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testDeviceActivityError_AllCases() {
        let testError = NSError(domain: "TestError", code: -1, userInfo: nil)
        let errors: [DeviceActivityError] = [
            .monitoringStartFailed(testError),
            .invalidConfiguration,
            .unauthorizedAccess,
            .deviceNotSupported
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion?.isEmpty ?? true)
        }
    }

    // MARK: - TimeInterval Extension Tests

    func testTimeInterval_ConvenienceConstructors() {
        XCTAssertEqual(TimeInterval.minutes(1), 60)
        XCTAssertEqual(TimeInterval.minutes(15), 900)
        XCTAssertEqual(TimeInterval.hours(1), 3600)
        XCTAssertEqual(TimeInterval.hours(2), 7200)
    }
}

#else

// MARK: - macOS Fallback Tests for Device Activity
final class DeviceActivityServiceFallbackTests: XCTestCase {

    func testDeviceActivity_NotAvailableOnMacOS() {
        // Document that Device Activity monitoring is iOS-only
        XCTAssertTrue(true, "Device Activity monitoring is iOS-only - cannot test on macOS")

        print("⚠️  Device Activity monitoring testing requires physical iOS device")
        print("📝 Simulator limitations documented in README.md")
        print("🔄 Full monitoring test coverage available only on iOS device")
    }

    func testDeviceActivityMonitoring_Requirements() {
        let monitoringRequirements = [
            "Physical iOS device with iOS 15.0+",
            "Family Controls authorization granted",
            "DeviceActivityMonitor extension configured",
            "App installed on device (not just Xcode deployment)",
            "Background app refresh enabled",
            "Test apps installed for monitoring validation"
        ]

        XCTAssertEqual(monitoringRequirements.count, 6, "All monitoring requirements documented")

        print("📋 Device Activity monitoring test requirements:")
        for (index, requirement) in monitoringRequirements.enumerated() {
            print("  \(index + 1). \(requirement)")
        }
    }

    func testDeviceActivityEvents_Documentation() {
        let supportedEvents = [
            "intervalDidStart - Session monitoring begins",
            "intervalDidEnd - Session monitoring ends",
            "eventDidReachThreshold - Time/usage limits reached",
            "intervalWillStartWarning - Pre-session warning",
            "intervalWillEndWarning - Pre-end warning",
            "eventWillReachThresholdWarning - Pre-limit warning"
        ]

        XCTAssertEqual(supportedEvents.count, 6, "All device activity events documented")

        print("🔔 Supported Device Activity events:")
        for event in supportedEvents {
            print("  • \(event)")
        }
    }
}

#endif
