import Foundation
import OSLog

/// Performance monitoring utility for tracking operation execution times and memory usage
@available(iOS 14.0, macOS 11.0, *)
public struct PerformanceMonitor {
    @available(iOS 14.0, macOS 11.0, *)
    private static let logger = Logger(subsystem: "com.bmad.screen-time-rewards", category: "Performance")
    
    /// Measures the execution time of an operation
    /// - Parameters:
    ///   - operation: The name of the operation being measured
    ///   - block: The operation to measure
    /// - Returns: The result of the operation
    @available(iOS 14.0, macOS 11.0, *)
    public static func measure<T>(operation: String, _ block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        logger.info("Performance: \(operation) completed in \(String(format: "%.3f", executionTime)) seconds")
        
        // Log warning if operation takes longer than expected
        if executionTime > 2.0 {
            logger.warning("Performance: \(operation) took longer than expected: \(String(format: "%.3f", executionTime)) seconds")
        }
        
        return result
    }
    
    /// Measures the execution time of a synchronous operation
    /// - Parameters:
    ///   - operation: The name of the operation being measured
    ///   - block: The operation to measure
    /// - Returns: The result of the operation
    @available(iOS 14.0, macOS 11.0, *)
    public static func measure<T>(operation: String, _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        logger.info("Performance: \(operation) completed in \(String(format: "%.3f", executionTime)) seconds")
        
        // Log warning if operation takes longer than expected
        if executionTime > 2.0 {
            logger.warning("Performance: \(operation) took longer than expected: \(String(format: "%.3f", executionTime)) seconds")
        }
        
        return result
    }
    
    /// Logs current memory usage
    /// - Parameter context: Context for the memory usage log
    @available(iOS 14.0, macOS 11.0, *)
    public static func logMemoryUsage(for context: String) {
        let memoryUsage = getCurrentMemoryUsage()
        logger.info("Memory usage for \(context): \(String(format: "%.2f", memoryUsage)) MB")
        
        // Log warning if memory usage is high
        if memoryUsage > 100.0 {
            logger.warning("High memory usage for \(context): \(String(format: "%.2f", memoryUsage)) MB")
        }
    }
    
    /// Gets current memory usage in MB
    /// - Returns: Memory usage in MB
    private static func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
}