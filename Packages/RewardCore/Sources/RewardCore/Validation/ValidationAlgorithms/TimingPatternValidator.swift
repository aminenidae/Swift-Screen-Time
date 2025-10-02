import Foundation
import SharedModels

/// Validator that detects suspicious timing patterns that may indicate gaming
@available(iOS 15.0, macOS 12.0, *)
public class TimingPatternValidator: UsageValidator {
    public var validatorName: String { "TimingPatternValidator" }
    
    // Thresholds for detection
    private let exactBoundaryTolerance: TimeInterval = 60.0 // 1 minute tolerance for exact boundaries
    
    public init() {}
    
    public func validate(session: UsageSession, familySettings: FamilySettings) async -> ValidationAlgorithmResult {
        let isSuspiciousTiming = detectSuspiciousTiming(in: session)
        let isExactBoundary = detectExactHourBoundary(in: session)
        
        if isSuspiciousTiming || isExactBoundary {
            return ValidationAlgorithmResult(isValid: false, violation: ValidationViolation.timeBased)
        } else {
            return ValidationAlgorithmResult(isValid: true, violation: nil)
        }
    }
    
    /// Detects suspicious timing patterns in the session
    /// - Parameter session: The usage session to analyze
    /// - Returns: True if suspicious timing is detected
    private func detectSuspiciousTiming(in session: UsageSession) -> Bool {
        // Check for exact hour boundaries (common gaming pattern)
        let startMinutes = Calendar.current.component(.minute, from: session.startTime)
        let startSeconds = Calendar.current.component(.second, from: session.startTime)
        let endMinutes = Calendar.current.component(.minute, from: session.endTime)
        let endSeconds = Calendar.current.component(.second, from: session.endTime)
        
        // Convert to TimeInterval for comparison
        let startSecondsDouble = TimeInterval(startSeconds)
        let endSecondsDouble = TimeInterval(endSeconds)
        
        // Suspicious if starting or ending very close to hour boundaries
        let isStartSuspicious = (startMinutes == 0 && startSecondsDouble < exactBoundaryTolerance) ||
                           (startMinutes == 59 && startSecondsDouble > (60.0 - exactBoundaryTolerance))
        let isEndSuspicious = (endMinutes == 0 && endSecondsDouble < exactBoundaryTolerance) ||
                         (endMinutes == 59 && endSecondsDouble > (60.0 - exactBoundaryTolerance))
        
        return isStartSuspicious || isEndSuspicious
    }
    
    /// Detects if session starts or ends exactly on hour boundaries
    /// - Parameter session: The usage session to analyze
    /// - Returns: True if exact hour boundary is detected
    private func detectExactHourBoundary(in session: UsageSession) -> Bool {
        let startSeconds = Calendar.current.component(.second, from: session.startTime)
        let startMinutes = Calendar.current.component(.minute, from: session.startTime)
        let endSeconds = Calendar.current.component(.second, from: session.endTime)
        let endMinutes = Calendar.current.component(.minute, from: session.endTime)
        
        // Convert to TimeInterval for comparison
        let startSecondsDouble = TimeInterval(startSeconds)
        let endSecondsDouble = TimeInterval(endSeconds)
        
        // Exact boundary if within tolerance
        let isStartExact = (startMinutes == 0 && startSecondsDouble <= exactBoundaryTolerance) ||
                      (startMinutes == 59 && startSecondsDouble >= (60.0 - exactBoundaryTolerance))
        let isEndExact = (endMinutes == 0 && endSecondsDouble <= exactBoundaryTolerance) ||
                    (endMinutes == 59 && endSecondsDouble >= (60.0 - exactBoundaryTolerance))
        
        return isStartExact || isEndExact
    }
}