import Foundation
import SharedModels

// MARK: - Analytics Consent Service

/// Service responsible for managing analytics consent levels
public class AnalyticsConsentService: @unchecked Sendable {
    private let repository: AnalyticsConsentRepository?
    private var cachedConsents: [String: AnalyticsConsent] = [:] // familyID: consent
    private let cacheQueue = DispatchQueue(label: "analytics-consent-cache", attributes: .concurrent)
    
    public init(repository: AnalyticsConsentRepository? = nil) {
        self.repository = repository
    }
    
    // MARK: - Consent Management
    
    /// Sets the analytics consent level for a family
    public func setConsentLevel(
        _ level: AnalyticsConsentLevel,
        for familyID: String,
        ipAddress: String? = nil,
        userAgent: String? = nil
    ) async throws {
        let consent = AnalyticsConsent(
            familyID: familyID,
            consentLevel: level,
            consentDate: Date(),
            consentVersion: "1.0",
            ipAddress: ipAddress,
            userAgent: userAgent,
            lastUpdated: Date()
        )
        
        // Save to repository if available
        if let repository = repository {
            try await repository.saveConsent(consent)
        }
        
        // Update cache
        cacheQueue.async(flags: .barrier) {
            self.cachedConsents[familyID] = consent
        }
    }
    
    /// Gets the current consent level for a family
    public func getConsentLevel(for familyID: String) async throws -> AnalyticsConsentLevel {
        // Check cache first
        var cachedConsent: AnalyticsConsent?
        cacheQueue.sync {
            cachedConsent = self.cachedConsents[familyID]
        }
        
        if let consent = cachedConsent {
            return consent.consentLevel
        }
        
        // If not in cache, fetch from repository
        if let repository = repository, let consent = try await repository.fetchConsent(for: familyID) {
            // Update cache
            cacheQueue.async(flags: .barrier) {
                self.cachedConsents[familyID] = consent
            }
            return consent.consentLevel
        }
        
        // Default to no consent if no explicit consent has been given
        return .none
    }
    
    /// Checks if analytics collection is allowed for a user based on their consent level
    public func isCollectionAllowed(for familyID: String) async -> Bool {
        do {
            let consentLevel = try await getConsentLevel(for: familyID)
            return consentLevel != .none
        } catch {
            // If we can't determine consent, default to not collecting
            return false
        }
    }
    
    /// Checks if detailed analytics collection is allowed
    public func isDetailedCollectionAllowed(for familyID: String) async -> Bool {
        do {
            let consentLevel = try await getConsentLevel(for: familyID)
            return consentLevel == .detailed
        } catch {
            return false
        }
    }
    
    /// Checks if essential analytics collection is allowed
    public func isEssentialCollectionAllowed(for familyID: String) async -> Bool {
        do {
            let consentLevel = try await getConsentLevel(for: familyID)
            return consentLevel == .essential || consentLevel == .standard || consentLevel == .detailed
        } catch {
            return false
        }
    }
    
    /// Checks if standard analytics collection is allowed
    public func isStandardCollectionAllowed(for familyID: String) async -> Bool {
        do {
            let consentLevel = try await getConsentLevel(for: familyID)
            return consentLevel == .standard || consentLevel == .detailed
        } catch {
            return false
        }
    }
    
    /// Withdraws analytics consent for a family
    public func withdrawConsent(for familyID: String) async throws {
        // In a real implementation, this would also delete previously collected data
        // for the family based on privacy regulations
        
        // Remove from cache
        cacheQueue.async(flags: .barrier) {
            self.cachedConsents.removeValue(forKey: familyID)
        }
        
        // Remove from repository if available
        if let repository = repository {
            try await repository.deleteConsent(for: familyID)
        }
    }
}

// MARK: - Analytics Consent Repository Protocol

public protocol AnalyticsConsentRepository: Sendable {
    func saveConsent(_ consent: AnalyticsConsent) async throws
    func fetchConsent(for familyID: String) async throws -> AnalyticsConsent?
    func deleteConsent(for familyID: String) async throws
}