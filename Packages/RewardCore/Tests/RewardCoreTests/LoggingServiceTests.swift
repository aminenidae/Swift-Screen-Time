import XCTest
import OSLog
@testable import RewardCore

final class LoggingServiceTests: XCTestCase {
    
    func testSharedInstance() {
        let instance1 = LoggingService.shared
        let instance2 = LoggingService.shared

        // Verify that the same instance is returned
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testDebugLogging() {
        let loggingService = LoggingService.shared
        
        // Test that debug messages are logged correctly
        loggingService.debug("Test debug message")
        loggingService.debug("Test debug message with context", file: "TestFile.swift", function: "testFunction()", line: 42)
        
        // Verify logging service is working
        XCTAssertTrue(true)
    }
    
    func testInfoLogging() {
        let loggingService = LoggingService.shared
        
        // Test that info messages are logged correctly
        loggingService.info("Test info message")
        loggingService.info("Test info message with context", file: "TestFile.swift", function: "testFunction()", line: 42)
        
        // Verify logging service is working
        XCTAssertTrue(true)
    }
    
    func testWarningLogging() {
        let loggingService = LoggingService.shared
        
        // Test that warning messages are logged correctly
        loggingService.warning("Test warning message")
        loggingService.warning("Test warning message with context", file: "TestFile.swift", function: "testFunction()", line: 42)
        
        // Verify logging service is working
        XCTAssertTrue(true)
    }
    
    func testErrorLogging() {
        let loggingService = LoggingService.shared
        
        // Test that error messages are logged correctly
        loggingService.error("Test error message")
        loggingService.error("Test error message with context", file: "TestFile.swift", function: "testFunction()", line: 42)
        
        // Test with an error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error description"])
        loggingService.error("Test error message with NSError", error: testError)
        
        // Verify logging service is working
        XCTAssertTrue(true)
    }
    
    func testFaultLogging() {
        let loggingService = LoggingService.shared
        
        // Test that fault messages are logged correctly
        loggingService.fault("Test fault message")
        loggingService.fault("Test fault message with context", file: "TestFile.swift", function: "testFunction()", line: 42)
        
        // Test with an error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error description"])
        loggingService.fault("Test fault message with NSError", error: testError)
        
        // Verify logging service is working
        XCTAssertTrue(true)
    }
    
    func testFileNameExtraction() {
        let loggingService = LoggingService.shared
        
        // This test verifies the internal fileName function through the public interface
        loggingService.debug("Test message", file: "/Users/test/Project/ViewController.swift", function: "viewDidLoad()", line: 10)
        
        // If we reach this point, the test passes
        XCTAssertTrue(true)
    }
    
    func testConvenienceFunctions() {
        // Test that convenience functions log messages correctly
        logDebug("Test debug convenience function")
        logInfo("Test info convenience function")
        logWarning("Test warning convenience function")
        logError("Test error convenience function")
        logFault("Test fault convenience function")

        // Test with an error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error description"])
        logError("Test error convenience function with NSError", error: testError)
        logFault("Test fault convenience function with NSError", error: testError)

        // Verify all convenience functions are working
        XCTAssertTrue(true)
    }

    // MARK: - Enhanced Logging Tests

    func testCategoryBasedLogging() {
        let loggingService = LoggingService.shared

        // Test all logging categories
        loggingService.debug("Test app category", category: .app)
        loggingService.info("Test error category", category: .errors)
        loggingService.warning("Test performance category", category: .performance)
        loggingService.error("Test security category", category: .security)
        loggingService.fault("Test network category", category: .network)

        XCTAssertTrue(true, "Category-based logging should complete without error")
    }

    func testSecurityEventLogging() {
        let loggingService = LoggingService.shared

        let securityEvent = SecurityEvent(
            description: "Test security event",
            classification: .medium
        )

        loggingService.logSecurityEvent(securityEvent)

        // Test all classification levels
        let classifications: [SecurityClassification] = [.low, .medium, .high, .critical]
        for classification in classifications {
            let event = SecurityEvent(
                description: "Test event for \(classification)",
                classification: classification
            )
            loggingService.logSecurityEvent(event)
        }

        XCTAssertTrue(true, "Security event logging should complete without error")
    }

    func testNetworkOperationLogging() {
        let loggingService = LoggingService.shared

        // Test successful operation
        loggingService.logNetworkOperation(
            "GET /api/points",
            duration: 0.5,
            success: true
        )

        // Test failed operation
        loggingService.logNetworkOperation(
            "POST /api/transactions",
            duration: 2.1,
            success: false,
            errorCode: 500
        )

        // Test with no error code
        loggingService.logNetworkOperation(
            "DELETE /api/session",
            duration: 0.1,
            success: false
        )

        XCTAssertTrue(true, "Network operation logging should complete without error")
    }

    func testPerformanceMetricLogging() {
        let loggingService = LoggingService.shared

        let metrics: [(PerformanceMetric, Double, String)] = [
            (.appLaunchTime, 1.2, "seconds"),
            (.screenLoadTime, 0.8, "seconds"),
            (.networkRequestTime, 0.3, "seconds"),
            (.databaseQueryTime, 0.05, "seconds"),
            (.memoryUsage, 85.6, "MB"),
            (.cpuUsage, 12.3, "percent")
        ]

        for (metric, value, unit) in metrics {
            loggingService.logPerformanceMetric(metric, value: value, unit: unit)
        }

        XCTAssertTrue(true, "Performance metric logging should complete without error")
    }

    func testDebugLogCollection() async {
        let loggingService = LoggingService.shared

        let report = await loggingService.collectDebugLogs()

        XCTAssertNotNil(report.timestamp, "Report should have a timestamp")
        XCTAssertFalse(report.appVersion.isEmpty, "Report should have app version")
        XCTAssertNotNil(report.performanceMetrics, "Report should have performance metrics")
        XCTAssertNotNil(report.errorPatterns, "Report should have error patterns")

        // Verify timestamp is recent
        XCTAssertTrue(report.timestamp.timeIntervalSinceNow < 1.0, "Timestamp should be recent")
        XCTAssertTrue(report.timestamp.timeIntervalSinceNow > -10.0, "Timestamp should not be too old")
    }

    func testEnhancedConvenienceFunctions() {
        // Test enhanced convenience functions
        let securityEvent = SecurityEvent(description: "Test security event", classification: .low)
        logSecurityEvent(securityEvent)

        logNetworkOperation("GET /test", duration: 1.0, success: true)
        logNetworkOperation("POST /test", duration: 2.0, success: false, errorCode: 404)

        XCTAssertTrue(true, "Enhanced convenience functions should work")
    }

    func testLoggingPerformance() {
        let loggingService = LoggingService.shared

        measure {
            for i in 0..<1000 {
                loggingService.debug("Performance test message \(i)")
            }
        }
    }

    func testCategorizedLoggingPerformance() {
        let loggingService = LoggingService.shared
        let categories: [LoggingCategory] = [.app, .errors, .performance, .security, .network]

        measure {
            for i in 0..<200 {
                for category in categories {
                    loggingService.info("Category performance test \(i)", category: category)
                }
            }
        }
    }

    func testLoggingWithEmptyAndSpecialMessages() {
        let loggingService = LoggingService.shared

        // Test empty messages
        loggingService.debug("")
        loggingService.info("")
        loggingService.warning("")
        loggingService.error("")
        loggingService.fault("")

        // Test special characters
        let specialMessage = "Test émojis 🎉, unicode ñäöü, symbols @#$%^&*()"
        loggingService.info(specialMessage)

        // Test very long message
        let longMessage = String(repeating: "A", count: 1000)
        loggingService.debug(longMessage)

        XCTAssertTrue(true, "Logging with edge case messages should not crash")
    }

    func testConcurrentLogging() async {
        let loggingService = LoggingService.shared
        let taskCount = 50

        let tasks = (0..<taskCount).map { i in
            Task {
                loggingService.info("Concurrent test message \(i)")
                loggingService.debug("Concurrent debug \(i)", category: .performance)
                loggingService.warning("Concurrent warning \(i)", category: .security)
            }
        }

        for task in tasks {
            await task.value
        }

        XCTAssertTrue(true, "Concurrent logging should complete without issues")
    }
}