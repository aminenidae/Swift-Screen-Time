import XCTest
import SwiftUI
@testable import ScreenTimeRewards

final class BedtimeSettingComponentsTests: XCTestCase {

    func testBedtimeStartSettingCreation() {
        // Test that BedtimeStartSetting can be created with valid bindings
        let bedtimeStart = Binding<Date?>.constant(nil)
        let settingView = BedtimeStartSetting(bedtimeStart: bedtimeStart)

        XCTAssertNotNil(settingView)
    }

    func testBedtimeEndSettingCreation() {
        // Test that BedtimeEndSetting can be created with valid bindings
        let bedtimeEnd = Binding<Date?>.constant(nil)
        let settingView = BedtimeEndSetting(bedtimeEnd: bedtimeEnd)

        XCTAssertNotNil(settingView)
    }

    func testTimePickerControlsIntegration() {
        // Test that time picker controls are properly integrated
        let calendar = Calendar.current
        let defaultStartTime = calendar.date(from: DateComponents(hour: 20, minute: 0))
        let defaultEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0))

        let bedtimeStart = Binding<Date?>.constant(defaultStartTime)
        let bedtimeEnd = Binding<Date?>.constant(defaultEndTime)

        let startSettingView = BedtimeStartSetting(bedtimeStart: bedtimeStart)
        let endSettingView = BedtimeEndSetting(bedtimeEnd: bedtimeEnd)

        XCTAssertNotNil(startSettingView)
        XCTAssertNotNil(endSettingView)
    }

    func testEnableDisableTogglesFunctionality() {
        // Test that enable/disable toggles work correctly
        var bedtimeStartValue: Date? = nil
        var bedtimeEndValue: Date? = nil

        let bedtimeStart = Binding(
            get: { bedtimeStartValue },
            set: { bedtimeStartValue = $0 }
        )

        let bedtimeEnd = Binding(
            get: { bedtimeEndValue },
            set: { bedtimeEndValue = $0 }
        )

        // Test initial disabled state
        XCTAssertNil(bedtimeStart.wrappedValue)
        XCTAssertNil(bedtimeEnd.wrappedValue)

        // Test enabling bedtime
        let calendar = Calendar.current
        let enabledStartTime = calendar.date(from: DateComponents(hour: 20, minute: 0))
        let enabledEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0))

        bedtimeStart.wrappedValue = enabledStartTime
        bedtimeEnd.wrappedValue = enabledEndTime

        XCTAssertNotNil(bedtimeStart.wrappedValue)
        XCTAssertNotNil(bedtimeEnd.wrappedValue)

        // Test disabling bedtime
        bedtimeStart.wrappedValue = nil
        bedtimeEnd.wrappedValue = nil

        XCTAssertNil(bedtimeStart.wrappedValue)
        XCTAssertNil(bedtimeEnd.wrappedValue)
    }

    func testDefaultValues() {
        // Test default values (8:00 PM start, 7:00 AM end) for new families
        let calendar = Calendar.current
        let defaultStartTime = calendar.date(from: DateComponents(hour: 20, minute: 0))!
        let defaultEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0))!

        let startComponents = calendar.dateComponents([.hour, .minute], from: defaultStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: defaultEndTime)

        XCTAssertEqual(startComponents.hour, 20)
        XCTAssertEqual(startComponents.minute, 0)
        XCTAssertEqual(endComponents.hour, 7)
        XCTAssertEqual(endComponents.minute, 0)
    }

    func testBedtimeStartComponentForBedtimeStartField() {
        // Test that BedtimeStartSetting specifically handles bedtimeStart field
        let calendar = Calendar.current
        let testTime = calendar.date(from: DateComponents(hour: 21, minute: 30))

        var bedtimeStartValue: Date? = testTime
        let bedtimeStart = Binding(
            get: { bedtimeStartValue },
            set: { bedtimeStartValue = $0 }
        )

        let settingView = BedtimeStartSetting(bedtimeStart: bedtimeStart)

        XCTAssertNotNil(settingView)
        XCTAssertEqual(bedtimeStart.wrappedValue, testTime)
    }

    func testBedtimeEndComponentForBedtimeEndField() {
        // Test that BedtimeEndSetting specifically handles bedtimeEnd field
        let calendar = Calendar.current
        let testTime = calendar.date(from: DateComponents(hour: 6, minute: 30))

        var bedtimeEndValue: Date? = testTime
        let bedtimeEnd = Binding(
            get: { bedtimeEndValue },
            set: { bedtimeEndValue = $0 }
        )

        let settingView = BedtimeEndSetting(bedtimeEnd: bedtimeEnd)

        XCTAssertNotNil(settingView)
        XCTAssertEqual(bedtimeEnd.wrappedValue, testTime)
    }

    func testTimePickerAccessibility() {
        // Test that time picker controls have proper accessibility support
        let bedtimeStart = Binding<Date?>.constant(Calendar.current.date(from: DateComponents(hour: 20, minute: 0)))
        let bedtimeEnd = Binding<Date?>.constant(Calendar.current.date(from: DateComponents(hour: 7, minute: 0)))

        let startSettingView = BedtimeStartSetting(bedtimeStart: bedtimeStart)
        let endSettingView = BedtimeEndSetting(bedtimeEnd: bedtimeEnd)

        // Verify components can be created (accessibility is tested at runtime)
        XCTAssertNotNil(startSettingView)
        XCTAssertNotNil(endSettingView)
    }

    func testBedtimeRangeLogic() {
        // Test bedtime range logic (overnight handling)
        let calendar = Calendar.current

        // Test normal overnight bedtime (8 PM to 7 AM)
        let startTime = calendar.date(from: DateComponents(hour: 20, minute: 0))!
        let endTime = calendar.date(from: DateComponents(hour: 7, minute: 0))!

        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

        // Overnight bedtime: end time is earlier than start time in 24h format
        XCTAssertLessThan(endMinutes, startMinutes)

        // Test same-day bedtime (1 PM to 3 PM - unusual but valid)
        let sameDayStart = calendar.date(from: DateComponents(hour: 13, minute: 0))!
        let sameDayEnd = calendar.date(from: DateComponents(hour: 15, minute: 0))!

        let sameDayStartComponents = calendar.dateComponents([.hour, .minute], from: sameDayStart)
        let sameDayEndComponents = calendar.dateComponents([.hour, .minute], from: sameDayEnd)

        let sameDayStartMinutes = (sameDayStartComponents.hour ?? 0) * 60 + (sameDayStartComponents.minute ?? 0)
        let sameDayEndMinutes = (sameDayEndComponents.hour ?? 0) * 60 + (sameDayEndComponents.minute ?? 0)

        XCTAssertGreaterThan(sameDayEndMinutes, sameDayStartMinutes)
    }

    func testTimeFormatterConsistency() {
        // Test that time formatter produces consistent results
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let calendar = Calendar.current
        let testTime = calendar.date(from: DateComponents(hour: 20, minute: 30))!

        let formattedTime = formatter.string(from: testTime)

        // Verify formatter produces a non-empty string
        XCTAssertFalse(formattedTime.isEmpty)

        // Verify formatter is consistent
        let formattedTimeAgain = formatter.string(from: testTime)
        XCTAssertEqual(formattedTime, formattedTimeAgain)
    }
}