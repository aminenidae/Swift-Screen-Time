import Foundation
import OSLog
import MetricKit
import SharedModels

/// A service for structured logging throughout the application
@available(iOS 15.0, macOS 12.0, *)
public class LoggingService: NSObject {
    public static let shared = LoggingService()

    private let appLogger: Logger
    private let errorLogger: Logger
    private let performanceLogger: Logger
    private let securityLogger: Logger
    private let networkLogger: Logger

    // MetricKit for performance monitoring
    private let metricManager = MXMetricManager.shared

    private override init() {
        self.appLogger = Logger(subsystem: "com.screentime.rewards", category: "app")
        self.errorLogger = Logger(subsystem: "com.screentime.rewards", category: "errors")
        self.performanceLogger = Logger(subsystem: "com.screentime.rewards", category: "performance")
        self.securityLogger = Logger(subsystem: "com.screentime.rewards", category: "security")
        self.networkLogger = Logger(subsystem: "com.screentime.rewards", category: "network")

        super.init()
        setupMetricKit()
    }
    

    // MARK: - MetricKit Setup

    private func setupMetricKit() {
        metricManager.add(self)
    }
    
    // MARK: - General Logging

    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The logging category
    ///   - file: The file where the log was called (automatically filled)
    ///   - function: The function where the log was called (automatically filled)
    ///   - line: The line where the log was called (automatically filled)
    public func debug(_ message: String, category: LoggingCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = getLogger(for: category)
        logger.debug("\(message) [\(self.fileName(file)):\(function):\(line)]")
    }
    
    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The logging category
    ///   - file: The file where the log was called (automatically filled)
    ///   - function: The function where the log was called (automatically filled)
    ///   - line: The line where the log was called (automatically filled)
    public func info(_ message: String, category: LoggingCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = getLogger(for: category)
        logger.info("\(message) [\(self.fileName(file)):\(function):\(line)]")
    }

    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The logging category
    ///   - file: The file where the log was called (automatically filled)
    ///   - function: The function where the log was called (automatically filled)
    ///   - line: The line where the log was called (automatically filled)
    public func warning(_ message: String, category: LoggingCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = getLogger(for: category)
        logger.warning("\(message) [\(self.fileName(file)):\(function):\(line)]")
    }

    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: An optional error to include details from
    ///   - category: The logging category
    ///   - file: The file where the log was called (automatically filled)
    ///   - function: The function where the log was called (automatically filled)
    ///   - line: The line where the log was called (automatically filled)
    public func error(_ message: String, error: Error? = nil, category: LoggingCategory = .errors, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = getLogger(for: category)
        if let error = error {
            logger.error("\(message): \(self.sanitizeErrorMessage(error.localizedDescription)) [\(self.fileName(file)):\(function):\(line)]")
        } else {
            logger.error("\(message) [\(self.fileName(file)):\(function):\(line)]")
        }
    }

    /// Log a fault message (critical error)
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: An optional error to include details from
    ///   - category: The logging category
    ///   - file: The file where the log was called (automatically filled)
    ///   - function: The function where the log was called (automatically filled)
    ///   - line: The line where the log was called (automatically filled)
    public func fault(_ message: String, error: Error? = nil, category: LoggingCategory = .errors, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = getLogger(for: category)
        if let error = error {
            logger.fault("\(message): \(self.sanitizeErrorMessage(error.localizedDescription)) [\(self.fileName(file)):\(function):\(line)]")
        } else {
            logger.fault("\(message) [\(self.fileName(file)):\(function):\(line)]")
        }
    }

    // MARK: - Specialized Logging

    /// Log a security event with enhanced privacy protection
    public func logSecurityEvent(_ event: SecurityEvent, file: String = #file, function: String = #function, line: Int = #line) {
        securityLogger.info("\(event.description) [Classification: \(event.classification)] [\(self.fileName(file)):\(function):\(line)]")
    }

    /// Log a network operation with performance metrics
    public func logNetworkOperation(
        _ operation: String,
        duration: TimeInterval,
        success: Bool,
        errorCode: Int? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let status = success ? "SUCCESS" : "FAILED"
        var message = "Network operation: \(operation) - \(status) (\(String(format: "%.3f", duration))s)"

        if let errorCode = errorCode {
            message += " [Error: \(errorCode)]"
        }

        networkLogger.info("\(message) [\(self.fileName(file)):\(function):\(line)]")
    }

    /// Log performance metrics
    public func logPerformanceMetric(
        _ metric: PerformanceMetric,
        value: Double,
        unit: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        performanceLogger.info("\(metric.rawValue): \(value) \(unit) [\(self.fileName(file)):\(function):\(line)]")
    }

    // MARK: - Debug Log Collection

    /// Collect debug logs for troubleshooting
    public func collectDebugLogs() async -> DebugLogReport {
        var report = DebugLogReport()

        // Collect recent logs from OSLog
        report.timestamp = Date()
        report.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        report.systemVersion = await getSystemVersion()

        // Collect performance metrics if available
        if let metrics = self.getLatestMetrics() {
            report.performanceMetrics = formatMetrics(metrics)
        }

        // Collect error patterns
        report.errorPatterns = await self.analyzeErrorPatterns()

        return report
    }
    
    /// Extract just the file name from the full file path
    /// - Parameter file: The full file path
    /// - Returns: The file name without extension
    private func fileName(_ file: String) -> String {
        let components = file.split(separator: "/")
        if let lastComponent = components.last {
            let fileNameComponents = lastComponent.split(separator: ".")
            return String(fileNameComponents.first ?? lastComponent)
        }
        return file
    }
}

// MARK: - Convenience Functions

/// Convenience function for debug logging
/// - Parameters:
///   - message: The message to log
///   - file: The file where the log was called (automatically filled)
///   - function: The function where the log was called (automatically filled)
///   - line: The line where the log was called (automatically filled)
@available(iOS 15.0, macOS 12.0, *)
public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.debug(message, file: file, function: function, line: line)
}

/// Convenience function for info logging
/// - Parameters:
///   - message: The message to log
///   - file: The file where the log was called (automatically filled)
///   - function: The function where the log was called (automatically filled)
///   - line: The line where the log was called (automatically filled)
@available(iOS 15.0, macOS 12.0, *)
public func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.info(message, file: file, function: function, line: line)
}

/// Convenience function for warning logging
/// - Parameters:
///   - message: The message to log
///   - file: The file where the log was called (automatically filled)
///   - function: The function where the log was called (automatically filled)
///   - line: The line where the log was called (automatically filled)
@available(iOS 15.0, macOS 12.0, *)
public func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.warning(message, file: file, function: function, line: line)
}

/// Convenience function for error logging
/// - Parameters:
///   - message: The message to log
///   - error: An optional error to include details from
///   - file: The file where the log was called (automatically filled)
///   - function: The function where the log was called (automatically filled)
///   - line: The line where the log was called (automatically filled)
@available(iOS 15.0, macOS 12.0, *)
public func logError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.error(message, error: error, file: file, function: function, line: line)
}

/// Convenience function for fault logging
/// - Parameters:
///   - message: The message to log
///   - error: An optional error to include details from
///   - file: The file where the log was called (automatically filled)
///   - function: The function where the log was called (automatically filled)
///   - line: The line where the log was called (automatically filled)
@available(iOS 15.0, macOS 12.0, *)
public func logFault(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.fault(message, error: error, file: file, function: function, line: line)
}

// MARK: - LoggingService Helper Methods Extension

@available(iOS 15.0, macOS 12.0, *)
extension LoggingService {
    // MARK: - Helper Methods

    private func getLogger(for category: LoggingCategory) -> Logger {
        switch category {
        case .app:
            return appLogger
        case .errors:
            return errorLogger
        case .performance:
            return performanceLogger
        case .security:
            return securityLogger
        case .network:
            return networkLogger
        }
    }

    private func sanitizeErrorMessage(_ message: String) -> String {
        // Remove sensitive information from error messages
        return message
            .replacingOccurrences(of: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#, with: "[EMAIL]", options: .regularExpression)
            .replacingOccurrences(of: #"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b"#, with: "[CARD]", options: .regularExpression)
    }

    private func getSystemVersion() async -> String {
        return await Task { ProcessInfo.processInfo.operatingSystemVersionString }.value
    }

    private func getLatestMetrics() -> MXMetricPayload? {
        // Implementation would fetch latest MetricKit data
        return nil
    }

    private func formatMetrics(_ metrics: MXMetricPayload) -> [String: Any] {
        // Format MetricKit metrics for logging
        return [:]
    }

    private func analyzeErrorPatterns() async -> [String] {
        // Analyze recent error logs for patterns
        return []
    }
}

// MARK: - MetricKit Delegate

@available(iOS 15.0, macOS 12.0, *)
extension LoggingService: MXMetricManagerSubscriber {
    public func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            performanceLogger.info("Received performance metrics: \(payload.description)")

            // Log specific performance issues
            if let hangMetrics = payload.applicationExitMetrics {
                performanceLogger.warning("App hang detected: \(hangMetrics)")
            }

            if let crashMetrics = payload.metaData {
                errorLogger.fault("Crash metrics received: \(crashMetrics)")
            }
        }
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            errorLogger.fault("Diagnostic payload received: \(payload.description)")
        }
    }
}

// MARK: - Data Structures

/// Logging categories for structured logging
public enum LoggingCategory {
    case app
    case errors
    case performance
    case security
    case network
}

/// Security event classification
public struct SecurityEvent {
    public let description: String
    public let classification: SecurityClassification

    public init(description: String, classification: SecurityClassification) {
        self.description = description
        self.classification = classification
    }
}

/// Security classification levels
public enum SecurityClassification: CustomStringConvertible {
    case low
    case medium
    case high
    case critical

    public var description: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .critical: return "critical"
        }
    }
}

/// Performance metrics
public enum PerformanceMetric: String {
    case appLaunchTime = "app_launch_time"
    case screenLoadTime = "screen_load_time"
    case networkRequestTime = "network_request_time"
    case databaseQueryTime = "database_query_time"
    case memoryUsage = "memory_usage"
    case cpuUsage = "cpu_usage"
}

/// Debug log report structure
public struct DebugLogReport {
    public var timestamp: Date = Date()
    public var appVersion: String = ""
    public var systemVersion: String = ""
    public var performanceMetrics: [String: Any] = [:]
    public var errorPatterns: [String] = []
}

// MARK: - Enhanced Convenience Functions

/// Log a security event using the shared service
@available(iOS 15.0, macOS 12.0, *)
public func logSecurityEvent(_ event: SecurityEvent) {
    LoggingService.shared.logSecurityEvent(event)
}

/// Log a network operation using the shared service
@available(iOS 15.0, macOS 12.0, *)
public func logNetworkOperation(
    _ operation: String,
    duration: TimeInterval,
    success: Bool,
    errorCode: Int? = nil
) {
    LoggingService.shared.logNetworkOperation(
        operation,
        duration: duration,
        success: success,
        errorCode: errorCode
    )
}