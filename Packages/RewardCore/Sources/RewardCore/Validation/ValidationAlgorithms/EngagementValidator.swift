import Foundation
import SharedModels
import DeviceActivity

/// Validator that detects passive usage vs active engagement
@available(iOS 15.0, macOS 12.0, *)
public class EngagementValidator: UsageValidator {
    public var validatorName: String { "EngagementValidator" }
    
    // Thresholds for detection
    private let minimumInteractionTime: TimeInterval = 600.0 // 10 minutes
    private let passiveUsageThreshold: Double = 0.3 // 30% interaction density considered passive
    
    public init() {}
    
    public func validate(session: UsageSession, familySettings: FamilySettings) async -> ValidationAlgorithmResult {
        let engagementMetrics = analyzeEngagement(in: session)
        let isPassiveUsage = detectPassiveUsage(engagementMetrics: engagementMetrics)
        
        if isPassiveUsage {
            return ValidationAlgorithmResult(isValid: false, violation: ValidationViolation.timeBased)
        } else {
            return ValidationAlgorithmResult(isValid: true, violation: nil)
        }
    }
    
    /// Analyzes engagement metrics for a session
    /// - Parameter session: The usage session to analyze
    /// - Returns: EngagementMetrics with analysis results
    private func analyzeEngagement(in session: UsageSession) -> EngagementMetrics {
        // In a real implementation, this would use DeviceActivityMonitor data
        // For simulation, we'll estimate based on session characteristics
        
        // Estimate app state changes based on session duration
        let estimatedStateChanges = max(1, Int(session.duration / 300.0)) // Roughly every 5 minutes
        
        // Estimate interaction density based on session duration
        // Longer sessions might have lower interaction density
        let interactionDensity = max(0.1, min(1.0, 2.0 - (session.duration / 3600.0)))
        
        // Estimate average session length (this would be more complex in reality)
        let averageSessionLength = session.duration
        
        return EngagementMetrics(
            appStateChanges: estimatedStateChanges,
            averageSessionLength: averageSessionLength,
            interactionDensity: interactionDensity,
            deviceMotionCorrelation: session.duration > minimumInteractionTime ? 0.7 : 0.3
        )
    }
    
    /// Detects if the session shows signs of passive usage
    /// - Parameter engagementMetrics: The engagement metrics to analyze
    /// - Returns: True if passive usage is detected
    private func detectPassiveUsage(engagementMetrics: EngagementMetrics) -> Bool {
        // Check if interaction density is below threshold
        let isLowInteraction = engagementMetrics.interactionDensity < passiveUsageThreshold
        
        // Check if session is long with minimal state changes
        let isLongSessionWithLowActivity = 
            engagementMetrics.averageSessionLength > minimumInteractionTime && 
            engagementMetrics.appStateChanges < 3
        
        return isLowInteraction || isLongSessionWithLowActivity
    }
}