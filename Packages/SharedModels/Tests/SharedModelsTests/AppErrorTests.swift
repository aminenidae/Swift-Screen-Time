import XCTest
@testable import SharedModels

final class AppErrorTests: XCTestCase {
    
    func testNetworkUnavailableError() {
        let error = AppError.networkUnavailable
        XCTAssertEqual(error.errorDescription, "No internet connection. Please check your network settings and try again.")
        XCTAssertEqual(error.failureReason, "Network unavailable")
        XCTAssertEqual(error.recoverySuggestion, "Try connecting to Wi-Fi or cellular data, then retry the operation.")
    }
    
    func testNetworkTimeoutError() {
        let error = AppError.networkTimeout
        XCTAssertEqual(error.errorDescription, "The request timed out. Please try again.")
        XCTAssertEqual(error.failureReason, "Network timeout")
    }
    
    func testNetworkErrorWithMessage() {
        let errorMessage = "Connection refused"
        let error = AppError.networkError(errorMessage)
        XCTAssertEqual(error.errorDescription, "Network error: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Network error")
    }
    
    func testCloudKitNotAvailableError() {
        let error = AppError.cloudKitNotAvailable
        XCTAssertEqual(error.errorDescription, "iCloud is not available. Please sign in to iCloud and try again.")
        XCTAssertEqual(error.failureReason, "CloudKit unavailable")
    }
    
    func testCloudKitRecordNotFoundError() {
        let error = AppError.cloudKitRecordNotFound
        XCTAssertEqual(error.errorDescription, "The requested data was not found.")
        XCTAssertEqual(error.failureReason, "Record not found")
    }
    
    func testCloudKitSaveErrorWithMessage() {
        let errorMessage = "Record quota exceeded"
        let error = AppError.cloudKitSaveError(errorMessage)
        XCTAssertEqual(error.errorDescription, "Failed to save data: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Save failed")
    }
    
    func testCloudKitFetchErrorWithMessage() {
        let errorMessage = "Zone not found"
        let error = AppError.cloudKitFetchError(errorMessage)
        XCTAssertEqual(error.errorDescription, "Failed to fetch data: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Fetch failed")
    }
    
    func testCloudKitDeleteErrorWithMessage() {
        let errorMessage = "Permission denied"
        let error = AppError.cloudKitDeleteError(errorMessage)
        XCTAssertEqual(error.errorDescription, "Failed to delete data: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Delete failed")
    }
    
    func testCloudKitZoneErrorWithMessage() {
        let errorMessage = "Invalid zone name"
        let error = AppError.cloudKitZoneError(errorMessage)
        XCTAssertEqual(error.errorDescription, "CloudKit zone error: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Zone error")
    }
    
    func testInvalidDataErrorWithMessage() {
        let errorMessage = "Invalid date format"
        let error = AppError.invalidData(errorMessage)
        XCTAssertEqual(error.errorDescription, "Invalid data: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Invalid data")
    }
    
    func testMissingRequiredFieldError() {
        let fieldName = "childProfileID"
        let error = AppError.missingRequiredField(fieldName)
        XCTAssertEqual(error.errorDescription, "Required field is missing: \(fieldName)")
        XCTAssertEqual(error.failureReason, "Missing required field")
    }
    
    func testDataValidationErrorWithMessage() {
        let errorMessage = "Points must be positive"
        let error = AppError.dataValidationError(errorMessage)
        XCTAssertEqual(error.errorDescription, "Data validation error: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Data validation error")
    }
    
    func testUnauthorizedError() {
        let error = AppError.unauthorized
        XCTAssertEqual(error.errorDescription, "You are not authorized to perform this action.")
        XCTAssertEqual(error.failureReason, "Unauthorized")
    }
    
    func testAuthenticationFailedError() {
        let error = AppError.authenticationFailed
        XCTAssertEqual(error.errorDescription, "Authentication failed. Please try signing in again.")
        XCTAssertEqual(error.failureReason, "Authentication failed")
    }
    
    func testFamilyAccessDeniedError() {
        let error = AppError.familyAccessDenied
        XCTAssertEqual(error.errorDescription, "Access to family data denied.")
        XCTAssertEqual(error.failureReason, "Family access denied")
    }
    
    func testInsufficientPointsError() {
        let error = AppError.insufficientPoints
        XCTAssertEqual(error.errorDescription, "Not enough points for this reward.")
        XCTAssertEqual(error.failureReason, "Insufficient points")
        XCTAssertEqual(error.recoverySuggestion, "Complete more learning activities to earn the required points.")
    }

    func testCloudKitNotAvailableErrorRecovery() {
        let error = AppError.cloudKitNotAvailable
        XCTAssertEqual(error.recoverySuggestion, "Go to Settings > [Your Name] > iCloud and make sure you're signed in.")
    }

    func testRecoverySuggestionNotEmpty() {
        let allErrorCases: [AppError] = [
            .networkUnavailable,
            .networkTimeout,
            .networkError("test"),
            .cloudKitNotAvailable,
            .cloudKitRecordNotFound,
            .cloudKitSaveError("test"),
            .cloudKitFetchError("test"),
            .cloudKitDeleteError("test"),
            .cloudKitZoneError("test"),
            .invalidData("test"),
            .missingRequiredField("test"),
            .dataValidationError("test"),
            .unauthorized,
            .authenticationFailed,
            .familyAccessDenied,
            .insufficientPoints,
            .invalidOperation("test"),
            .operationNotAllowed("test"),
            .systemError("test"),
            .unknownError("test")
        ]

        for error in allErrorCases {
            XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil for \(error)")
            XCTAssertFalse(error.recoverySuggestion?.isEmpty ?? true, "Recovery suggestion should not be empty for \(error)")
        }
    }
    
    func testInvalidOperationErrorWithMessage() {
        let errorMessage = "Cannot delete active redemption"
        let error = AppError.invalidOperation(errorMessage)
        XCTAssertEqual(error.errorDescription, "Invalid operation: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Invalid operation")
    }
    
    func testOperationNotAllowedErrorWithMessage() {
        let errorMessage = "Reward redemption disabled for this family"
        let error = AppError.operationNotAllowed(errorMessage)
        XCTAssertEqual(error.errorDescription, "Operation not allowed: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Operation not allowed")
    }
    
    func testSystemErrorWithMessage() {
        let errorMessage = "Disk full"
        let error = AppError.systemError(errorMessage)
        XCTAssertEqual(error.errorDescription, "System error: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "System error")
    }
    
    func testUnknownErrorWithMessage() {
        let errorMessage = "Unexpected error occurred"
        let error = AppError.unknownError(errorMessage)
        XCTAssertEqual(error.errorDescription, "An unknown error occurred: \(errorMessage)")
        XCTAssertEqual(error.failureReason, "Unknown error")
    }
}