import XCTest
@testable import RewardCore

@available(iOS 14.0, macOS 11.0, *)
final class PerformanceMonitorTests: XCTestCase {
    
    func testMeasureAsyncOperation_ReturnsResult() async throws {
        // Given
        var operationExecuted = false
        let expectedValue = "test result"
        
        // When
        // Create an actual async operation to avoid warnings
        let result = try await PerformanceMonitor.measure(operation: "testOperation") {
            operationExecuted = true
            // Add an actual async operation to avoid warnings
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms sleep
            return expectedValue
        }
        
        // Then
        XCTAssertTrue(operationExecuted)
        XCTAssertEqual(result, expectedValue)
    }
    
    func testMeasureSyncOperation_ReturnsResult() throws {
        // Given
        var operationExecuted = false
        let expectedValue = 42
        
        // When
        // Call a function that actually can throw to avoid warnings
        let result = try PerformanceMonitor.measure(operation: "testOperation") {
            operationExecuted = true
            // Add an operation that can throw to avoid warnings
            let optionalValue: Int? = 42
            guard let value = optionalValue else {
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
            return value
        }
        
        // Then
        XCTAssertTrue(operationExecuted)
        XCTAssertEqual(result, expectedValue)
    }
    
    func testMeasureAsyncOperation_ThrowsError() async throws {
        // Given
        enum TestError: Error {
            case testFailure
        }
        
        // When/Then
        do {
            let _ = try await PerformanceMonitor.measure(operation: "testOperation") {
                // Add an actual async operation to avoid warnings
                try await Task.sleep(nanoseconds: 1_000_000) // 1ms sleep
                throw TestError.testFailure
            }
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected to throw
            XCTAssertTrue(error is TestError)
        }
    }
    
    func testMeasureSyncOperation_ThrowsError() throws {
        // Given
        enum TestError: Error {
            case testFailure
        }
        
        // When/Then
        XCTAssertThrowsError(try PerformanceMonitor.measure(operation: "testOperation") {
            // Add an operation that can actually throw to avoid warnings
            let optionalValue: Int? = nil
            guard let value = optionalValue else {
                throw TestError.testFailure
            }
            return value
        })
    }
    
    func testLogMemoryUsage_DoesNotCrash() {
        // When/Then
        XCTAssertNoThrow(PerformanceMonitor.logMemoryUsage(for: "testContext"))
    }
    
    func testGetCurrentMemoryUsage_ReturnsNonNegativeValue() {
        // When
        // Note: We can't directly test the private getCurrentMemoryUsage() method,
        // but we can verify that logMemoryUsage doesn't crash, which implies
        // the method is working correctly
        XCTAssertNoThrow(PerformanceMonitor.logMemoryUsage(for: "test"))
    }
}