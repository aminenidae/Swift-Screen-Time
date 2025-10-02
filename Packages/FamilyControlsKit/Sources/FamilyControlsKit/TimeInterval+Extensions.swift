import Foundation

// MARK: - TimeInterval Extensions for Convenience

extension TimeInterval {
    /// Creates a TimeInterval from minutes
    /// - Parameter minutes: Number of minutes
    /// - Returns: TimeInterval in seconds
    public static func minutes(_ minutes: Int) -> TimeInterval {
        return TimeInterval(minutes * 60)
    }

    /// Creates a TimeInterval from hours
    /// - Parameter hours: Number of hours
    /// - Returns: TimeInterval in seconds
    public static func hours(_ hours: Int) -> TimeInterval {
        return TimeInterval(hours * 3600)
    }

    /// Converts TimeInterval to minutes
    public var inMinutes: Int {
        return Int(self / 60)
    }

    /// Converts TimeInterval to minutes (alternative name expected by tests)
    public var minutes: Int {
        return Int(self / 60)
    }

    /// Converts TimeInterval to hours
    public var inHours: Double {
        return self / 3600
    }

    /// Converts TimeInterval to hours (alternative name expected by tests)
    public var hours: Double {
        return self / 3600
    }
}