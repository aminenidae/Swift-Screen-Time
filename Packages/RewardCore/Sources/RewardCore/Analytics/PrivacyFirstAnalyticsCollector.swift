import Foundation
import SharedModels

// MARK: - Privacy First Analytics Collector

/// Implementation of AnalyticsEventCollector with privacy-first design
public class PrivacyFirstAnalyticsCollector: AnalyticsEventCollector {
    private let analyticsService: AnalyticsService
    private let consentService: AnalyticsConsentService
    
    public init(
        analyticsService: AnalyticsService,
        consentService: AnalyticsConsentService
    ) {
        self.analyticsService = analyticsService
        self.consentService = consentService
    }
    
    // MARK: - Event Tracking Implementation
    
    public func trackEvent(_ event: AnalyticsEvent) async {
        // The analytics service already handles privacy concerns
        await analyticsService.trackEvent(event)
    }
    
    public func trackFeatureUsage(feature: String, metadata: [String: String]?) async {
        // Only track if detailed collection is allowed
        let familyID = await getCurrentFamilyID()
        if await consentService.isDetailedCollectionAllowed(for: familyID) {
            await analyticsService.trackFeatureUsage(feature: feature, metadata: metadata)
        }
    }
    
    public func trackUserFlow(flow: String, step: String) async {
        // Only track if detailed collection is allowed
        let familyID = await getCurrentFamilyID()
        if await consentService.isDetailedCollectionAllowed(for: familyID) {
            await analyticsService.trackUserFlow(flow: flow, step: step)
        }
    }
    
    public func trackPerformance(metric: String, value: Double) async {
        // Performance metrics are considered essential
        let familyID = await getCurrentFamilyID()
        if await consentService.isEssentialCollectionAllowed(for: familyID) {
            await analyticsService.trackPerformance(metric: metric, value: value)
        }
    }
    
    public func trackError(category: String, code: String) async {
        // Error tracking is considered essential
        let familyID = await getCurrentFamilyID()
        if await consentService.isEssentialCollectionAllowed(for: familyID) {
            await analyticsService.trackError(category: category, code: code)
        }
    }
    
    public func trackEngagement(type: String, duration: TimeInterval) async {
        // Engagement tracking is considered standard
        let familyID = await getCurrentFamilyID()
        if await consentService.isStandardCollectionAllowed(for: familyID) {
            await analyticsService.trackEngagement(type: type, duration: duration)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets the current family ID
    private func getCurrentFamilyID() async -> String {
        // In a real implementation, this would retrieve the current family ID
        // For now, we'll return a placeholder
        return "current-family-id"
    }
}