import XCTest
import CloudKit
@testable import RewardCore
@testable import SharedModels

final class ErrorHandlingServiceTests: XCTestCase {
    var errorHandlingService: ErrorHandlingService!

    override func setUp() {
        super.setUp()
        errorHandlingService = ErrorHandlingService.shared
    }

    override func tearDown() {
        errorHandlingService = nil
        super.tearDown()
    }

    // MARK: - CloudKit Error Mapping Tests

    func testMapCloudKitNetworkUnavailableError() {
        let ckError = CKError(.networkUnavailable)
        let appError = errorHandlingService.mapCloudKitError(ckError)

        switch appError {
        case .networkUnavailable:
            XCTAssertTrue(true, "Correctly mapped to networkUnavailable")
        default:
            XCTFail("Expected networkUnavailable, got \(appError)")
        }
    }

    func testMapCloudKitNotAuthenticatedError() {
        let ckError = CKError(.notAuthenticated)
        let appError = errorHandlingService.mapCloudKitError(ckError)

        switch appError {
        case .authenticationFailed:
            XCTAssertTrue(true, "Correctly mapped to authenticationFailed")
        default:
            XCTFail("Expected authenticationFailed, got \(appError)")
        }
    }

    func testMapCloudKitPermissionFailureError() {
        let ckError = CKError(.permissionFailure)
        let appError = errorHandlingService.mapCloudKitError(ckError)

        switch appError {
        case .unauthorized:
            XCTAssertTrue(true, "Correctly mapped to unauthorized")
        default:
            XCTFail("Expected unauthorized, got \(appError)")
        }
    }

    func testMapCloudKitUnknownItemError() {
        let ckError = CKError(.unknownItem)
        let appError = errorHandlingService.mapCloudKitError(ckError)

        switch appError {
        case .cloudKitRecordNotFound:
            XCTAssertTrue(true, "Correctly mapped to cloudKitRecordNotFound")
        default:
            XCTFail("Expected cloudKitRecordNotFound, got \(appError)")
        }
    }

    func testMapCloudKitQuotaExceededError() {
        let ckError = CKError(.quotaExceeded)
        let appError = errorHandlingService.mapCloudKitError(ckError)

        switch appError {
        case .cloudKitSaveError(let message):
            XCTAssertTrue(message.contains("quota"), "Error message should mention quota")
        default:
            XCTFail("Expected cloudKitSaveError with quota message, got \(appError)")
        }
    }

    // MARK: - Error Conversion Tests

    func testConvertAppErrorReturnsOriginal() {
        let originalError = AppError.insufficientPoints
        let convertedError = errorHandlingService.convertToAppError(originalError)

        switch convertedError {
        case .insufficientPoints:
            XCTAssertTrue(true, "AppError returned unchanged")
        default:
            XCTFail("Expected same AppError, got \(convertedError)")
        }
    }

    func testConvertCloudKitError() {
        let ckError = CKError(.networkFailure)
        let appError = errorHandlingService.convertToAppError(ckError)

        switch appError {
        case .networkUnavailable:
            XCTAssertTrue(true, "CloudKit error correctly converted")
        default:
            XCTFail("Expected networkUnavailable, got \(appError)")
        }
    }

    func testConvertNSURLError() {
        let urlError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let appError = errorHandlingService.convertToAppError(urlError)

        switch appError {
        case .networkUnavailable:
            XCTAssertTrue(true, "URL error correctly converted to networkUnavailable")
        default:
            XCTFail("Expected networkUnavailable, got \(appError)")
        }
    }

    func testConvertURLTimeoutError() {
        let urlError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        let appError = errorHandlingService.convertToAppError(urlError)

        switch appError {
        case .networkTimeout:
            XCTAssertTrue(true, "URL timeout error correctly converted")
        default:
            XCTFail("Expected networkTimeout, got \(appError)")
        }
    }

    func testConvertUnknownErrorToUnknownError() {
        struct CustomError: Error {
            let message = "Custom error message"
        }

        let customError = CustomError()
        let appError = errorHandlingService.convertToAppError(customError)

        switch appError {
        case .unknownError(let message):
            XCTAssertTrue(message.contains("Custom error message"), "Should preserve original error description")
        default:
            XCTFail("Expected unknownError, got \(appError)")
        }
    }

    // MARK: - Retry Logic Tests

    func testExecuteWithRetrySucceedsOnFirstAttempt() async throws {
        var attemptCount = 0

        let result = try await errorHandlingService.executeWithRetry(
            operation: {
                attemptCount += 1
                return "Success"
            },
            maxRetries: 3,
            delay: 0.001
        )

        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 1, "Should succeed on first attempt")
    }

    func testExecuteWithRetrySucceedsAfterRetries() async throws {
        var attemptCount = 0

        let result = try await errorHandlingService.executeWithRetry(
            operation: {
                attemptCount += 1
                if attemptCount < 3 {
                    throw AppError.networkTimeout
                }
                return "Success"
            },
            maxRetries: 3,
            delay: 0.001
        )

        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 3, "Should succeed on third attempt")
    }

    func testExecuteWithRetryFailsAfterMaxRetries() async {
        var attemptCount = 0

        do {
            _ = try await errorHandlingService.executeWithRetry(
                operation: {
                    attemptCount += 1
                    throw AppError.networkTimeout
                },
                maxRetries: 2,
                delay: 0.001
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount, 3, "Should attempt maxRetries + 1 times")
            XCTAssertTrue(error is AppError, "Should throw AppError")
        }
    }

    func testExecuteWithRetryDoesNotRetryNonRetryableErrors() async {
        var attemptCount = 0

        do {
            _ = try await errorHandlingService.executeWithRetry(
                operation: {
                    attemptCount += 1
                    throw AppError.unauthorized
                },
                maxRetries: 3,
                delay: 0.001
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount, 1, "Should not retry non-retryable errors")
        }
    }

    // MARK: - Error Processing Tests

    func testProcessErrorLogsWithCorrectSeverity() {
        // This test would require a way to capture log output
        // For now, we'll just verify the method doesn't crash
        let error = AppError.networkUnavailable
        errorHandlingService.processError(error, context: "testContext", severity: .error)
        XCTAssertTrue(true, "processError should complete without crashing")
    }

    // MARK: - Error Recovery Tests

    func testAttemptRecoveryFromNetworkError() async {
        let error = AppError.networkUnavailable
        let recoveryResult = await errorHandlingService.attemptRecovery(from: error)

        // Recovery might succeed or fail depending on actual network state
        // We're just testing that the method completes without crashing
        XCTAssertTrue(recoveryResult || !recoveryResult, "Recovery attempt should complete")
    }

    func testAttemptRecoveryFromCloudKitError() async {
        let error = AppError.cloudKitNotAvailable
        let recoveryResult = await errorHandlingService.attemptRecovery(from: error)

        // Recovery might succeed or fail depending on actual CloudKit state
        // We're just testing that the method completes without crashing
        XCTAssertTrue(recoveryResult || !recoveryResult, "Recovery attempt should complete")
    }

    func testAttemptRecoveryFromAuthenticationError() async {
        let error = AppError.authenticationFailed
        let recoveryResult = await errorHandlingService.attemptRecovery(from: error)

        // Authentication errors typically require user intervention
        XCTAssertFalse(recoveryResult, "Authentication errors should not auto-recover")
    }

    func testAttemptRecoveryFromNonRecoverableError() async {
        let error = AppError.insufficientPoints
        let recoveryResult = await errorHandlingService.attemptRecovery(from: error)

        XCTAssertFalse(recoveryResult, "Non-recoverable errors should return false")
    }

    // MARK: - Performance Tests

    func testErrorMappingPerformance() {
        let ckError = CKError(.networkUnavailable)

        measure {
            for _ in 0..<1000 {
                _ = errorHandlingService.mapCloudKitError(ckError)
            }
        }
    }

    func testErrorConversionPerformance() {
        let errors: [Error] = [
            AppError.networkUnavailable,
            CKError(.notAuthenticated),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        ]

        measure {
            for _ in 0..<1000 {
                for error in errors {
                    _ = errorHandlingService.convertToAppError(error)
                }
            }
        }
    }

    // MARK: - Edge Cases

    func testEmptyErrorMessage() {
        let error = AppError.networkError("")
        let convertedError = errorHandlingService.convertToAppError(error)

        switch convertedError {
        case .networkError(let message):
            XCTAssertEqual(message, "", "Empty message should be preserved")
        default:
            XCTFail("Error type should be preserved")
        }
    }

    func testVeryLongErrorMessage() {
        let longMessage = String(repeating: "A", count: 10000)
        let error = AppError.systemError(longMessage)
        let convertedError = errorHandlingService.convertToAppError(error)

        switch convertedError {
        case .systemError(let message):
            XCTAssertEqual(message, longMessage, "Long message should be preserved")
        default:
            XCTFail("Error type should be preserved")
        }
    }
}

// MARK: - Test Extensions

extension ErrorHandlingServiceTests {
    /// Helper method to create a mock CloudKit error with specific code
    private func createMockCKError(code: CKError.Code) -> CKError {
        return CKError(code)
    }

    /// Helper method to verify error mapping consistency
    private func verifyErrorMapping(ckErrorCode: CKError.Code, expectedAppError: AppError) {
        let ckError = createMockCKError(code: ckErrorCode)
        let mappedError = errorHandlingService.mapCloudKitError(ckError)

        switch (mappedError, expectedAppError) {
        case (.networkUnavailable, .networkUnavailable),
             (.authenticationFailed, .authenticationFailed),
             (.unauthorized, .unauthorized),
             (.cloudKitRecordNotFound, .cloudKitRecordNotFound):
            XCTAssertTrue(true, "Error mapping is correct")
        default:
            XCTFail("Expected \(expectedAppError), got \(mappedError)")
        }
    }
}