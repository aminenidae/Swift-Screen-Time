import Foundation
import SharedModels

/// Engine responsible for calculating points based on usage sessions
public class PointCalculationEngine {
    // Default points per hour if not specified
    private let defaultPointsPerHour: Int = 10
    
    public init() {}
    
    /// Calculates points for a usage session
    /// - Parameters:
    ///   - session: The usage session
    ///   - pointsPerHour: Points earned per hour
    /// - Returns: The number of points earned
    public func calculatePoints(for session: UsageSession, pointsPerHour: Int) -> Int {
        let durationHours = session.duration / 3600.0
        let basePoints = Int(Double(pointsPerHour) * durationHours)
        
        // For now, we're not applying validation adjustments since we removed
        // the validationDetails property from UsageSession to avoid circular dependencies
        // TODO: Implement validation adjustments in a different way that doesn't create circular dependencies
        return basePoints
    }

    /// Gets the points per hour for a specific app and category
    /// - Parameters:
    ///   - appBundleID: The bundle ID of the app
    ///   - category: The category of the app
    /// - Returns: Points per hour for the app
    private func getPointsPerHour(for appBundleID: String, category: AppCategory) -> Int {
        // This would typically retrieve the value from settings or a database
        // For now, we'll return a default value based on category
        switch category {
        case .learning:
            return 20 // Higher points for learning apps
        case .reward:
            return 5 // Lower points for reward apps
        }
    }
    
    /// Calculates points for a specific duration and rate
    /// - Parameters:
    ///   - durationSeconds: Duration in seconds
    ///   - pointsPerHour: Points earned per hour
    ///   - category: The app category (affects point calculation)
    /// - Returns: The number of points earned
    public func calculatePoints(durationSeconds: TimeInterval, pointsPerHour: Int, category: AppCategory = .learning) -> Int {
        // Adjust points based on category
        let adjustedPointsPerHour = adjustPointsForCategory(pointsPerHour, category: category)
        let durationHours = durationSeconds / 3600.0
        return Int(Double(adjustedPointsPerHour) * durationHours)
    }
    
    /// Adjusts points based on app category
    /// - Parameters:
    ///   - pointsPerHour: Base points per hour
    ///   - category: The app category
    /// - Returns: Adjusted points per hour
    private func adjustPointsForCategory(_ pointsPerHour: Int, category: AppCategory) -> Int {
        switch category {
        case .learning:
            return pointsPerHour // Full points for learning apps
        case .reward:
            return Int(Double(pointsPerHour) * 0.5) // 50% points for reward apps
        }
    }
    
    /// Validates that the calculation produces expected results
    /// - Parameters:
    ///   - durationSeconds: Duration in seconds
    ///   - pointsPerHour: Points per hour
    ///   - category: The app category
    ///   - expectedPoints: Expected points result
    /// - Returns: Whether the calculation matches expectations
    public func validateCalculation(durationSeconds: TimeInterval, pointsPerHour: Int, category: AppCategory = .learning, expectedPoints: Int) -> Bool {
        return calculatePoints(durationSeconds: durationSeconds, pointsPerHour: pointsPerHour, category: category) == expectedPoints
    }
}