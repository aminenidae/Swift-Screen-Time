import Foundation
import CloudKit
import OSLog
import SharedModels

/// A centralized service for consistent error handling and processing throughout the application
@available(iOS 15.0, macOS 11.0, *)
public class ErrorHandlingService {
    public static let shared = ErrorHandlingService()
    private let logger = Logger(subsystem: "com.screentime.rewards", category: "error-handling")

    private init() {}

    // MARK: - CloudKit Error Mapping

    /// Convert CloudKit errors to domain-specific AppError instances
    /// - Parameter ckError: The CloudKit error to convert
    /// - Returns: Corresponding AppError with user-friendly messaging
    public func mapCloudKitError(_ ckError: CKError) -> AppError {
        logger.error("CloudKit error occurred: \(ckError.localizedDescription)")

        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .requestRateLimited:
            return .networkTimeout
        case .notAuthenticated:
            return .authenticationFailed
        case .permissionFailure:
            return .unauthorized
        case .accountTemporarilyUnavailable:
            return .cloudKitNotAvailable
        case .unknownItem:
            return .cloudKitRecordNotFound
        case .serverRecordChanged:
            return .cloudKitSaveError("Record was modified by another device")
        case .zoneBusy:
            return .cloudKitZoneError("Zone is busy, try again later")
        case .zoneNotFound:
            return .cloudKitZoneError("Zone not found")
        case .quotaExceeded:
            return .cloudKitSaveError("iCloud storage quota exceeded")
        case .operationCancelled:
            return .operationNotAllowed("Operation was cancelled")
        default:
            return .cloudKitSaveError("CloudKit operation failed: \(ckError.localizedDescription)")
        }
    }

    // MARK: - Error Processing and Logging

    /// Process and log an error with appropriate severity level
    /// - Parameters:
    ///   - error: The error to process
    ///   - context: Additional context about where the error occurred
    ///   - severity: The severity level of the error
    public func processError(
        _ error: Error,
        context: String,
        severity: ErrorSeverity = .error
    ) {
        let appError = convertToAppError(error)

        switch severity {
        case .debug:
            logger.debug("[\(context)] \(appError.localizedDescription)")
        case .info:
            logger.info("[\(context)] \(appError.localizedDescription)")
        case .warning:
            logger.warning("[\(context)] \(appError.localizedDescription)")
        case .error:
            logger.error("[\(context)] \(appError.localizedDescription)")
        case .fault:
            logger.fault("[\(context)] \(appError.localizedDescription)")
        }
    }

    /// Convert any error to an AppError instance
    /// - Parameter error: The error to convert
    /// - Returns: AppError instance with appropriate messaging
    public func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let ckError = error as? CKError {
            return mapCloudKitError(ckError)
        }

        // Handle other common error types
        if (error as NSError).domain == NSURLErrorDomain {
            let nsError = error as NSError
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .networkTimeout
            default:
                return .networkError(nsError.localizedDescription)
            }
        }

        return .unknownError(error.localizedDescription)
    }

    // MARK: - Retry Logic

    /// Execute an operation with retry logic for transient errors
    /// - Parameters:
    ///   - operation: The async operation to execute
    ///   - maxRetries: Maximum number of retry attempts
    ///   - delay: Delay between retries in seconds
    /// - Returns: The result of the operation
    public func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                let appError = convertToAppError(error)

                // Don't retry for certain error types
                if !shouldRetry(appError) || attempt == maxRetries {
                    throw appError
                }

                logger.warning("Operation failed (attempt \(attempt + 1)/\(maxRetries + 1)), retrying in \(delay) seconds: \(appError.localizedDescription)")

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? AppError.unknownError("Operation failed after \(maxRetries) retries")
    }

    /// Determine if an error should trigger a retry attempt
    /// - Parameter error: The error to evaluate
    /// - Returns: True if the operation should be retried
    private func shouldRetry(_ error: AppError) -> Bool {
        switch error {
        case .networkTimeout, .networkUnavailable, .cloudKitNotAvailable:
            return true
        case .cloudKitSaveError, .cloudKitFetchError, .cloudKitDeleteError:
            return true
        case .systemError:
            return true
        default:
            return false
        }
    }

    // MARK: - Error Recovery

    /// Attempt to recover from an error automatically
    /// - Parameter error: The error to recover from
    /// - Returns: True if recovery was successful
    public func attemptRecovery(from error: AppError) async -> Bool {
        logger.info("Attempting recovery from error: \(error.localizedDescription)")

        switch error {
        case .networkUnavailable:
            // Wait and check network connectivity
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return await checkNetworkConnectivity()

        case .cloudKitNotAvailable:
            // Try to refresh CloudKit account status
            return await refreshCloudKitStatus()

        case .authenticationFailed:
            // Clear cached credentials and prompt re-authentication
            await clearAuthenticationCache()
            return false // User intervention required

        default:
            return false
        }
    }

    // MARK: - Helper Methods

    private func checkNetworkConnectivity() async -> Bool {
        // Simplified network check - in real app this would be more robust
        do {
            let url = URL(string: "https://www.apple.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private func refreshCloudKitStatus() async -> Bool {
        do {
            let accountStatus = try await CKContainer.default().accountStatus()
            return accountStatus == .available
        } catch {
            return false
        }
    }

    private func clearAuthenticationCache() async {
        // Clear any cached authentication tokens or user data
        logger.info("Clearing authentication cache")
    }
}

// MARK: - Error Severity

/// Severity levels for error processing
public enum ErrorSeverity {
    case debug
    case info
    case warning
    case error
    case fault
}

// MARK: - Convenience Functions

/// Process an error with the shared error handling service
/// - Parameters:
///   - error: The error to process
///   - context: Additional context about where the error occurred
///   - severity: The severity level of the error
@available(iOS 15.0, macOS 11.0, *)
public func processError(
    _ error: Error,
    context: String,
    severity: ErrorSeverity = .error
) {
    ErrorHandlingService.shared.processError(error, context: context, severity: severity)
}

/// Convert any error to an AppError using the shared service
/// - Parameter error: The error to convert
/// - Returns: AppError instance with appropriate messaging
@available(iOS 15.0, macOS 11.0, *)
public func convertToAppError(_ error: Error) -> AppError {
    return ErrorHandlingService.shared.convertToAppError(error)
}