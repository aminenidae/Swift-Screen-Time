import XCTest
@testable import FamilyControlsKit
import SharedModels

final class FamilyControlsKitTests: XCTestCase {

    func testFamilyControlsServiceSingleton() {
        let service1 = FamilyControlsService.shared
        let service2 = FamilyControlsService.shared

        XCTAssertTrue(service1 === service2, "FamilyControlsService should be a singleton")
    }

    func testAuthorizationStatus() {
        let service = FamilyControlsService.shared

        // Should return current authorization status without throwing
        let status = service.authorizationStatus
        XCTAssertTrue([
            AuthorizationStatus.notDetermined,
            AuthorizationStatus.denied,
            AuthorizationStatus.approved
        ].contains(status))
    }

    func testDiscoverApplications() {
        let service = FamilyControlsService.shared

        let selection = service.discoverApplications()
        XCTAssertNotNil(selection)
        // FamilyActivitySelection should be empty in placeholder implementation
        XCTAssertTrue(selection.applicationTokens.isEmpty)
    }

    func testGetApplicationInfo() {
        let service = FamilyControlsService.shared

        // Create a mock token (this would be a real token in production)
        let mockToken = ApplicationToken("com.example.app")

        let info = service.getApplicationInfo(for: mockToken)
        // Should return nil in placeholder implementation
        XCTAssertNil(info)
    }

    func testCategorizeApplication() {
        let service = FamilyControlsService.shared

        // Create a mock token
        let mockToken = ApplicationToken("com.example.app")

        let category = service.categorizeApplication(mockToken)
        // Should return .other in placeholder implementation
        XCTAssertEqual(category, .other)
    }

    func testApplicationInfoInitialization() {
        let mockToken = ApplicationToken("com.example.reading")
        let info = ApplicationInfo(
            bundleID: "com.example.reading",
            displayName: "Reading App",
            category: ApplicationCategory.education
        )

        XCTAssertEqual(info.bundleID, "com.example.reading")
        XCTAssertEqual(info.displayName, "Reading App")
        XCTAssertEqual(info.category, ApplicationCategory.education)
    }

    func testUsageReportInitialization() {
        let childID = UUID().uuidString
        let date = Date()
        let mockToken = ApplicationToken("com.example.app")

        let usage = ApplicationUsage(
            token: mockToken.bundleIdentifier,
            displayName: "Test App",
            category: SharedModels.ApplicationCategory.educational,
            timeSpent: 3600, // 1 hour
            pointsEarned: 120
        )

        let report = UsageReport(
            childID: childID,
            date: date,
            applications: [usage],
            totalScreenTime: 3600
        )

        XCTAssertEqual(report.childID, childID)
        XCTAssertEqual(report.date, date)
        XCTAssertEqual(report.applications.count, 1)
        XCTAssertEqual(report.totalScreenTime, 3600)

        let firstApp = report.applications.first!
        XCTAssertEqual(firstApp.displayName, "Test App")
        XCTAssertEqual(firstApp.category, SharedModels.ApplicationCategory.educational)
        XCTAssertEqual(firstApp.timeSpent, 3600)
        XCTAssertEqual(firstApp.pointsEarned, 120)
    }

    func testApplicationUsageInitialization() {
        let mockToken = ApplicationToken("com.example.math")

        let usage = ApplicationUsage(
            token: mockToken.bundleIdentifier,
            displayName: "Math App",
            category: SharedModels.ApplicationCategory.educational,
            timeSpent: 1800, // 30 minutes
            pointsEarned: 60
        )

        XCTAssertEqual(usage.token, mockToken.bundleIdentifier)
        XCTAssertEqual(usage.displayName, "Math App")
        XCTAssertEqual(usage.category, SharedModels.ApplicationCategory.educational)
        XCTAssertEqual(usage.timeSpent, 1800)
        XCTAssertEqual(usage.pointsEarned, 60)
    }

    func testFamilyControlsErrorDescriptions() {
        let authDeniedError = FamilyControlsError.authorizationDenied
        let authRestrictedError = FamilyControlsError.authorizationRestricted
        let unavailableError = FamilyControlsError.unavailable

        XCTAssertFalse(authDeniedError.localizedDescription.isEmpty)
        XCTAssertFalse(authRestrictedError.localizedDescription.isEmpty)
        XCTAssertFalse(unavailableError.localizedDescription.isEmpty)

        // Test errors with underlying errors
        let underlyingError = NSError(domain: "Test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let monitoringError = FamilyControlsError.monitoringFailed(underlyingError)
        let timeLimitError = FamilyControlsError.timeLimitFailed(underlyingError)
        let restrictionError = FamilyControlsError.restrictionFailed(underlyingError)

        XCTAssertTrue(monitoringError.localizedDescription.contains("Test error"))
        XCTAssertTrue(timeLimitError.localizedDescription.contains("Test error"))
        XCTAssertTrue(restrictionError.localizedDescription.contains("Test error"))
    }

    func testDeviceActivityScheduleConvenience() {
        let startTime = DateComponents(hour: 9, minute: 0)
        let endTime = DateComponents(hour: 17, minute: 0)

        let schedule = DeviceActivitySchedule.dailySchedule(from: startTime, to: endTime)

        XCTAssertEqual(schedule.intervalStart, startTime)
        XCTAssertEqual(schedule.intervalEnd, endTime)
        XCTAssertTrue(schedule.repeats)

        let allDaySchedule = DeviceActivitySchedule.allDay()
        XCTAssertEqual(allDaySchedule.intervalStart.hour, 0)
        XCTAssertEqual(allDaySchedule.intervalStart.minute, 0)
        XCTAssertEqual(allDaySchedule.intervalEnd.hour, 23)
        XCTAssertEqual(allDaySchedule.intervalEnd.minute, 59)
        XCTAssertTrue(allDaySchedule.repeats)
    }

    func testTimeIntervalExtensions() {
        // Test conversion to minutes and hours
        XCTAssertEqual(TimeInterval(3600).minutes, 60) // 1 hour = 60 minutes
        XCTAssertEqual(TimeInterval(3600).hours, 1)    // 3600 seconds = 1 hour
        XCTAssertEqual(TimeInterval(1800).minutes, 30) // 1800 seconds = 30 minutes
        XCTAssertEqual(TimeInterval(7200).hours, 2)    // 7200 seconds = 2 hours

        // Test creation from minutes and hours
        XCTAssertEqual(TimeInterval.minutes(30), 1800)  // 30 minutes = 1800 seconds
        XCTAssertEqual(TimeInterval.hours(2), 7200)     // 2 hours = 7200 seconds
        XCTAssertEqual(TimeInterval.minutes(60), 3600)  // 60 minutes = 3600 seconds
        XCTAssertEqual(TimeInterval.hours(1), 3600)     // 1 hour = 3600 seconds
    }

    func testGetCurrentUsage() async {
        let service = FamilyControlsService.shared
        let mockToken = ApplicationToken("com.example.app")
        let applications: Set<ApplicationToken> = [mockToken]

        let now = Date()
        let interval = DateInterval(start: now.addingTimeInterval(-3600), end: now) // Last hour

        let usage = await service.getCurrentUsage(for: applications, during: interval)

        // Should return empty dictionary in placeholder implementation
        XCTAssertTrue(usage.isEmpty)
    }

    func testStopMonitoring() {
        let service = FamilyControlsService.shared
        let childID = UUID().uuidString

        // This should not throw in placeholder implementation
        service.stopMonitoring(for: childID)

        // Test passes if no exception is thrown
        XCTAssertTrue(true)
    }

    func testRemoveAllRestrictions() {
        let service = FamilyControlsService.shared

        // This should not throw in placeholder implementation
        service.removeAllRestrictions()

        // Test passes if no exception is thrown
        XCTAssertTrue(true)
    }
    
    func testAppDiscoveryServiceInitialization() {
        let service = AppDiscoveryService()
        XCTAssertNotNil(service)
    }
    
    func testFetchInstalledApps() async throws {
        let service = AppDiscoveryService()
        let apps = try await service.fetchInstalledApps()
        
        XCTAssertFalse(apps.isEmpty)
        XCTAssertTrue(apps.allSatisfy { !$0.displayName.isEmpty })
        XCTAssertTrue(apps.allSatisfy { !$0.bundleID.isEmpty })
    }
    
    func testAppMetadataStructure() async throws {
        let service = AppDiscoveryService()
        let apps = try await service.fetchInstalledApps()
        
        guard let firstApp = apps.first else {
            XCTFail("No apps returned")
            return
        }
        
        XCTAssertFalse(firstApp.id.isEmpty)
        XCTAssertFalse(firstApp.bundleID.isEmpty)
        XCTAssertFalse(firstApp.displayName.isEmpty)
        XCTAssertNotNil(firstApp.isSystemApp)
    }
}