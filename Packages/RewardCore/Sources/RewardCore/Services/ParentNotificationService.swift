import Foundation
import SharedModels
import UserNotifications

/// Service responsible for notifying parents about suspicious usage sessions
@available(iOS 15.0, macOS 12.0, *)
public class ParentNotificationService {
    private let notificationCenter: UNUserNotificationCenterProtocol
    private let familyRepository: FamilyRepository

    public init(familyRepository: FamilyRepository, notificationCenter: UNUserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.familyRepository = familyRepository
        self.notificationCenter = notificationCenter
    }
    
    /// Sends a notification to parents when a session is flagged as suspicious
    /// - Parameter validationResult: The validation result that triggered the notification
    /// - Parameter session: The usage session that was flagged
    /// - Parameter familyID: The family ID to notify
    public func notifyParents(of validationResult: ValidationResult, for session: UsageSession, familyID: String) async {
        // Only notify if confidence is above threshold
        guard validationResult.confidenceLevel > 0.75 else { return }
        
        // Get family information
        guard let family = try? await familyRepository.fetchFamily(id: familyID) else { return }
        
        // Create notification content
        let content = createNotificationContent(for: validationResult, session: session)
        
        // Create notification request
        let request = UNNotificationRequest(
            identifier: "suspicious-session-\(session.id)",
            content: content,
            trigger: nil // Send immediately
        )
        
        // Schedule notification
        try? await notificationCenter.add(request)
    }
    
    /// Creates notification content for a suspicious session
    /// - Parameter validationResult: The validation result
    /// - Parameter session: The usage session
    /// - Returns: UNNotificationContent with details
    private func createNotificationContent(for validationResult: ValidationResult, session: UsageSession) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Suspicious Usage Detected"
        content.body = createNotificationBody(for: validationResult, session: session)
        content.sound = .default
        content.categoryIdentifier = "SUSPICIOUS_USAGE"
        
        // Add detailed information as userInfo for potential deep linking
        content.userInfo = [
            "sessionID": session.id,
            "validationScore": validationResult.validationScore,
            "confidenceLevel": validationResult.confidenceLevel,
            "detectedPatterns": validationResult.detectedPatterns.map { "\($0)" }
        ]
        
        return content
    }
    
    /// Creates the notification body text
    /// - Parameter validationResult: The validation result
    /// - Parameter session: The usage session
    /// - Returns: Formatted notification body text
    private func createNotificationBody(for validationResult: ValidationResult, session: UsageSession) -> String {
        let appName = session.appBundleID.components(separatedBy: ".").last ?? "Unknown App"
        let durationMinutes = Int(session.duration / 60)
        
        var body = "A usage session for \(appName) (duration: \(durationMinutes) minutes) has been flagged as suspicious.\n"
        
        if !validationResult.detectedPatterns.isEmpty {
            body += "Detected patterns: \(formatDetectedPatterns(validationResult.detectedPatterns))\n"
        }
        
        body += "Confidence level: \(Int(validationResult.confidenceLevel * 100))%"
        
        return body
    }
    
    /// Formats detected patterns for display
    /// - Parameter patterns: Array of detected gaming patterns
    /// - Returns: Formatted string of patterns
    private func formatDetectedPatterns(_ patterns: [GamingPattern]) -> String {
        guard !patterns.isEmpty else { return "None" }
        
        let patternDescriptions = patterns.map { pattern in
            switch pattern {
            case .rapidAppSwitching:
                return "Rapid app switching"
            case .suspiciouslyLongSession:
                return "Unusually long session"
            case .exactHourBoundaries:
                return "Exact hour boundaries"
            case .deviceLockDuringSession:
                return "Device lock during session"
            case .backgroundUsage:
                return "Background usage detected"
            }
        }
        
        return patternDescriptions.joined(separator: ", ")
    }
    
    /// Requests notification permissions
    /// - Parameter completion: Completion handler with authorization status
    public func requestNotificationPermissions(completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }
    
    /// Checks if notifications are authorized
    /// - Parameter completion: Completion handler with authorization status
    public func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.checkAuthorizationStatus { authorized in
            DispatchQueue.main.async {
                completion(authorized)
            }
        }
    }
}