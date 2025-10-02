import Foundation
import CryptoKit
import SharedModels

// MARK: - Data Anonymization Service

/// Service responsible for anonymizing analytics data to protect user privacy
public class DataAnonymizationService: @unchecked Sendable {
    private let salt: String
    private let sessionID: String
    
    public init(salt: String = UUID().uuidString) {
        self.salt = salt
        self.sessionID = UUID().uuidString
    }
    
    // MARK: - Anonymization Methods
    
    /// Anonymizes a user ID using SHA-256 hashing with app-specific salt
    public func anonymize(userID: String) -> String {
        let input = userID + salt
        let data = input.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return "anon_" + hashString.prefix(32)
    }
    
    /// Anonymizes a device model to protect device identity
    public func anonymize(deviceModel: String) -> String {
        // Group devices into broad categories to protect specific models
        if deviceModel.contains("iPhone") {
            return "iPhone"
        } else if deviceModel.contains("iPad") {
            return "iPad"
        } else {
            return "Other"
        }
    }
    
    /// Anonymizes an analytics event
    public func anonymize(event: AnalyticsEvent) -> AnalyticsEvent {
        return AnalyticsEvent(
            id: event.id,
            eventType: event.eventType,
            timestamp: event.timestamp,
            anonymizedUserID: anonymize(userID: event.anonymizedUserID),
            sessionID: event.sessionID, // Preserve original session ID
            appVersion: event.appVersion,
            osVersion: event.osVersion,
            deviceModel: anonymize(deviceModel: event.deviceModel),
            metadata: event.metadata
        )
    }
    
    // MARK: - Helper Methods
    
    /// Gets the current anonymized user ID
    public func getCurrentAnonymizedUserID() async -> String {
        // In a real implementation, this would retrieve the current user ID and anonymize it
        return anonymize(userID: "current-user-id")
    }
    
    /// Gets the current session ID
    public func getCurrentSessionID() -> String {
        return sessionID
    }
    
    /// Gets the current app version
    public func getAppVersion() async -> String {
        // In a real implementation, this would retrieve the actual app version
        return "1.0.0"
    }
    
    /// Gets the current OS version
    public func getOSVersion() async -> String {
        // In a real implementation, this would retrieve the actual OS version
        return "iOS 15.0"
    }
    
    /// Gets the current device model
    public func getDeviceModel() async -> String {
        // In a real implementation, this would retrieve the actual device model
        return "iPhone"
    }
}