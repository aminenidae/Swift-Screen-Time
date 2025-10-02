import XCTest
@testable import FamilyControlsKit

final class TimeIntervalExtensionsTests: XCTestCase {

    // MARK: - Static Method Tests

    func testTimeIntervalMinutes() {
        XCTAssertEqual(TimeInterval.minutes(0), 0, "0 minutes should be 0 seconds")
        XCTAssertEqual(TimeInterval.minutes(1), 60, "1 minute should be 60 seconds")
        XCTAssertEqual(TimeInterval.minutes(30), 1800, "30 minutes should be 1800 seconds")
        XCTAssertEqual(TimeInterval.minutes(60), 3600, "60 minutes should be 3600 seconds")
        XCTAssertEqual(TimeInterval.minutes(120), 7200, "120 minutes should be 7200 seconds")
    }

    func testTimeIntervalHours() {
        XCTAssertEqual(TimeInterval.hours(0), 0, "0 hours should be 0 seconds")
        XCTAssertEqual(TimeInterval.hours(1), 3600, "1 hour should be 3600 seconds")
        XCTAssertEqual(TimeInterval.hours(2), 7200, "2 hours should be 7200 seconds")
        XCTAssertEqual(TimeInterval.hours(24), 86400, "24 hours should be 86400 seconds")
    }

    func testTimeIntervalMinutes_EdgeCases() {
        XCTAssertEqual(TimeInterval.minutes(-1), -60, "Negative minutes should work")
        XCTAssertEqual(TimeInterval.minutes(-60), -3600, "Negative 60 minutes should be -3600 seconds")
    }

    func testTimeIntervalHours_EdgeCases() {
        XCTAssertEqual(TimeInterval.hours(-1), -3600, "Negative hours should work")
        XCTAssertEqual(TimeInterval.hours(-24), -86400, "Negative 24 hours should be -86400 seconds")
    }

    // MARK: - Computed Property Tests

    func testTimeIntervalInMinutes() {
        XCTAssertEqual(TimeInterval(0).inMinutes, 0, "0 seconds should be 0 minutes")
        XCTAssertEqual(TimeInterval(30).inMinutes, 0, "30 seconds should be 0 minutes")
        XCTAssertEqual(TimeInterval(60).inMinutes, 1, "60 seconds should be 1 minute")
        XCTAssertEqual(TimeInterval(90).inMinutes, 1, "90 seconds should be 1 minute")
        XCTAssertEqual(TimeInterval(120).inMinutes, 2, "120 seconds should be 2 minutes")
        XCTAssertEqual(TimeInterval(3600).inMinutes, 60, "3600 seconds should be 60 minutes")
        XCTAssertEqual(TimeInterval(7200).inMinutes, 120, "7200 seconds should be 120 minutes")
    }

    func testTimeIntervalMinutesProperty() {
        XCTAssertEqual(TimeInterval(0).minutes, 0, "0 seconds should be 0 minutes")
        XCTAssertEqual(TimeInterval(30).minutes, 0, "30 seconds should be 0 minutes")
        XCTAssertEqual(TimeInterval(60).minutes, 1, "60 seconds should be 1 minute")
        XCTAssertEqual(TimeInterval(90).minutes, 1, "90 seconds should be 1 minute")
        XCTAssertEqual(TimeInterval(120).minutes, 2, "120 seconds should be 2 minutes")
        XCTAssertEqual(TimeInterval(3600).minutes, 60, "3600 seconds should be 60 minutes")
        XCTAssertEqual(TimeInterval(7200).minutes, 120, "7200 seconds should be 120 minutes")
    }

    func testTimeIntervalInHours() {
        XCTAssertEqual(TimeInterval(0).inHours, 0, "0 seconds should be 0 hours")
        XCTAssertEqual(TimeInterval(1800).inHours, 0.5, "1800 seconds should be 0.5 hours")
        XCTAssertEqual(TimeInterval(3600).inHours, 1.0, "3600 seconds should be 1 hour")
        XCTAssertEqual(TimeInterval(7200).inHours, 2.0, "7200 seconds should be 2 hours")
        XCTAssertEqual(TimeInterval(86400).inHours, 24.0, "86400 seconds should be 24 hours")
    }

    func testTimeIntervalHoursProperty() {
        XCTAssertEqual(TimeInterval(0).hours, 0, "0 seconds should be 0 hours")
        XCTAssertEqual(TimeInterval(1800).hours, 0.5, "1800 seconds should be 0.5 hours")
        XCTAssertEqual(TimeInterval(3600).hours, 1.0, "3600 seconds should be 1 hour")
        XCTAssertEqual(TimeInterval(7200).hours, 2.0, "7200 seconds should be 2 hours")
        XCTAssertEqual(TimeInterval(86400).hours, 24.0, "86400 seconds should be 24 hours")
    }

    // MARK: - Edge Case Tests

    func testTimeIntervalInMinutes_EdgeCases() {
        XCTAssertEqual(TimeInterval(-60).inMinutes, -1, "Negative 60 seconds should be -1 minute")
        XCTAssertEqual(TimeInterval(-120).inMinutes, -2, "Negative 120 seconds should be -2 minutes")
        XCTAssertEqual(TimeInterval(59).inMinutes, 0, "59 seconds should be 0 minutes")
        XCTAssertEqual(TimeInterval(61).inMinutes, 1, "61 seconds should be 1 minute")
    }

    func testTimeIntervalMinutesProperty_EdgeCases() {
        XCTAssertEqual(TimeInterval(-60).minutes, -1, "Negative 60 seconds should be -1 minute")
        XCTAssertEqual(TimeInterval(-120).minutes, -2, "Negative 120 seconds should be -2 minutes")
        XCTAssertEqual(TimeInterval(59).minutes, 0, "59 seconds should be 0 minutes")
        XCTAssertEqual(TimeInterval(61).minutes, 1, "61 seconds should be 1 minute")
    }

    func testTimeIntervalInHours_EdgeCases() {
        XCTAssertEqual(TimeInterval(-3600).inHours, -1.0, "Negative 3600 seconds should be -1 hour")
        XCTAssertEqual(TimeInterval(-7200).inHours, -2.0, "Negative 7200 seconds should be -2 hours")
        XCTAssertEqual(TimeInterval(1800).inHours, 0.5, "1800 seconds should be 0.5 hours")
        XCTAssertEqual(TimeInterval(5400).inHours, 1.5, "5400 seconds should be 1.5 hours")
    }

    func testTimeIntervalHoursProperty_EdgeCases() {
        XCTAssertEqual(TimeInterval(-3600).hours, -1.0, "Negative 3600 seconds should be -1 hour")
        XCTAssertEqual(TimeInterval(-7200).hours, -2.0, "Negative 7200 seconds should be -2 hours")
        XCTAssertEqual(TimeInterval(1800).hours, 0.5, "1800 seconds should be 0.5 hours")
        XCTAssertEqual(TimeInterval(5400).hours, 1.5, "5400 seconds should be 1.5 hours")
    }

    // MARK: - Large Value Tests

    func testTimeIntervalLargeValues() {
        let largeMinutes = 1000000
        let largeHours = 10000
        let largeSeconds = 100000000

        XCTAssertEqual(TimeInterval.minutes(largeMinutes), Double(largeMinutes * 60), "Large minutes conversion should work")
        XCTAssertEqual(TimeInterval.hours(largeHours), Double(largeHours * 3600), "Large hours conversion should work")
        XCTAssertEqual(TimeInterval(largeSeconds).inMinutes, largeSeconds / 60, "Large seconds to minutes should work")
        XCTAssertEqual(TimeInterval(largeSeconds).minutes, largeSeconds / 60, "Large seconds to minutes should work")
        XCTAssertEqual(TimeInterval(largeSeconds).inHours, Double(largeSeconds) / 3600.0, "Large seconds to hours should work")
        XCTAssertEqual(TimeInterval(largeSeconds).hours, Double(largeSeconds) / 3600.0, "Large seconds to hours should work")
    }

    // MARK: - Precision Tests

    func testTimeIntervalPrecision() {
        let preciseSeconds = 1800.5 // 30 minutes and 0.5 seconds
        XCTAssertEqual(TimeInterval(preciseSeconds).inMinutes, 30, "Should truncate to integer minutes")
        XCTAssertEqual(TimeInterval(preciseSeconds).minutes, 30, "Should truncate to integer minutes")
        
        let preciseHoursValue = 1.5
        XCTAssertEqual(TimeInterval.hours(Int(preciseHoursValue)), 5400, "1.5 hours should be 5400 seconds")
    }

    // MARK: - Zero Value Tests

    func testTimeIntervalZeroValues() {
        XCTAssertEqual(TimeInterval.minutes(0), 0, "Zero minutes should be zero seconds")
        XCTAssertEqual(TimeInterval.hours(0), 0, "Zero hours should be zero seconds")
        XCTAssertEqual(TimeInterval(0).inMinutes, 0, "Zero seconds should be zero minutes")
        XCTAssertEqual(TimeInterval(0).minutes, 0, "Zero seconds should be zero minutes")
        XCTAssertEqual(TimeInterval(0).inHours, 0, "Zero seconds should be zero hours")
        XCTAssertEqual(TimeInterval(0).hours, 0, "Zero seconds should be zero hours")
    }

    // MARK: - Performance Tests

    func testTimeIntervalMinutes_Performance() {
        measure {
            _ = TimeInterval.minutes(120)
        }
    }

    func testTimeIntervalHours_Performance() {
        measure {
            _ = TimeInterval.hours(2)
        }
    }

    func testTimeIntervalInMinutes_Performance() {
        let interval = TimeInterval(7200)
        measure {
            _ = interval.inMinutes
        }
    }

    func testTimeIntervalMinutesProperty_Performance() {
        let interval = TimeInterval(7200)
        measure {
            _ = interval.minutes
        }
    }

    func testTimeIntervalInHours_Performance() {
        let interval = TimeInterval(7200)
        measure {
            _ = interval.inHours
        }
    }

    func testTimeIntervalHoursProperty_Performance() {
        let interval = TimeInterval(7200)
        measure {
            _ = interval.hours
        }
    }

    // MARK: - Consistency Tests

    func testConsistencyBetweenMethods() {
        // Test that inMinutes and minutes return the same value
        let interval1 = TimeInterval(3600)
        XCTAssertEqual(interval1.inMinutes, interval1.minutes, "inMinutes and minutes should return the same value")
        
        let interval2 = TimeInterval(7200)
        XCTAssertEqual(interval2.inMinutes, interval2.minutes, "inMinutes and minutes should return the same value")
        
        // Test that inHours and hours return the same value
        let interval3 = TimeInterval(3600)
        XCTAssertEqual(interval3.inHours, interval3.hours, "inHours and hours should return the same value")
        
        let interval4 = TimeInterval(7200)
        XCTAssertEqual(interval4.inHours, interval4.hours, "inHours and hours should return the same value")
    }

    func testRoundTripConsistency() {
        // Test that converting minutes to seconds and back works consistently
        let minutes = 120
        let seconds = TimeInterval.minutes(minutes)
        let convertedBack = seconds.inMinutes
        XCTAssertEqual(convertedBack, minutes, "Round trip conversion should be consistent")
        
        // Test that converting hours to seconds and back works consistently
        let hours = 2
        let secondsFromHours = TimeInterval.hours(hours)
        let convertedHoursBack = secondsFromHours.inHours
        XCTAssertEqual(convertedHoursBack, Double(hours), "Round trip conversion should be consistent")
    }
}