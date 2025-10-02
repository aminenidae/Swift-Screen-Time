import Foundation
import SharedModels

#if canImport(MetricKit) && !os(macOS)
import MetricKit
#endif

// MARK: - Analytics Service

/// Main service for handling analytics collection with privacy-first design
public class AnalyticsService: AnalyticsEventCollector, @unchecked Sendable {
    private let consentService: AnalyticsConsentService
    private let anonymizationService: DataAnonymizationService
    private let aggregationService: AnalyticsAggregationService
    private let repository: AnalyticsRepository?
    
    public init(
        consentService: AnalyticsConsentService,
        anonymizationService: DataAnonymizationService,
        aggregationService: AnalyticsAggregationService,
        repository: AnalyticsRepository? = nil
    ) {
        self.consentService = consentService
        self.anonymizationService = anonymizationService
        self.aggregationService = aggregationService
        self.repository = repository
    }
    
    // MARK: - Event Tracking
    
    public func trackEvent(_ event: AnalyticsEvent) async {
        // Check consent level before tracking
        guard await consentService.isCollectionAllowed(for: event.anonymizedUserID) else {
            return
        }
        
        // Anonymize the event
        let anonymizedEvent = await anonymizationService.anonymize(event: event)
        
        // Store the event
        try? await repository?.saveEvent(anonymizedEvent)
    }
    
    public func trackFeatureUsage(feature: String, metadata: [String: String]?) async {
        let event = AnalyticsEvent(
            eventType: .featureUsage(feature: feature),
            anonymizedUserID: await anonymizationService.getCurrentAnonymizedUserID(),
            sessionID: await anonymizationService.getCurrentSessionID(),
            appVersion: await anonymizationService.getAppVersion(),
            osVersion: await anonymizationService.getOSVersion(),
            deviceModel: await anonymizationService.getDeviceModel(),
            metadata: metadata ?? [:]
        )
        
        await trackEvent(event)
    }
    
    public func trackUserFlow(flow: String, step: String) async {
        let event = AnalyticsEvent(
            eventType: .userFlow(flow: flow, step: step),
            anonymizedUserID: await anonymizationService.getCurrentAnonymizedUserID(),
            sessionID: await anonymizationService.getCurrentSessionID(),
            appVersion: await anonymizationService.getAppVersion(),
            osVersion: await anonymizationService.getOSVersion(),
            deviceModel: await anonymizationService.getDeviceModel()
        )
        
        await trackEvent(event)
    }
    
    public func trackPerformance(metric: String, value: Double) async {
        let event = AnalyticsEvent(
            eventType: .performance(metric: metric, value: value),
            anonymizedUserID: await anonymizationService.getCurrentAnonymizedUserID(),
            sessionID: await anonymizationService.getCurrentSessionID(),
            appVersion: await anonymizationService.getAppVersion(),
            osVersion: await anonymizationService.getOSVersion(),
            deviceModel: await anonymizationService.getDeviceModel()
        )
        
        await trackEvent(event)
    }
    
    public func trackError(category: String, code: String) async {
        let event = AnalyticsEvent(
            eventType: .error(category: category, code: code),
            anonymizedUserID: await anonymizationService.getCurrentAnonymizedUserID(),
            sessionID: await anonymizationService.getCurrentSessionID(),
            appVersion: await anonymizationService.getAppVersion(),
            osVersion: await anonymizationService.getOSVersion(),
            deviceModel: await anonymizationService.getDeviceModel()
        )
        
        await trackEvent(event)
    }
    
    public func trackEngagement(type: String, duration: TimeInterval) async {
        let event = AnalyticsEvent(
            eventType: .engagement(type: type, duration: duration),
            anonymizedUserID: await anonymizationService.getCurrentAnonymizedUserID(),
            sessionID: await anonymizationService.getCurrentSessionID(),
            appVersion: await anonymizationService.getAppVersion(),
            osVersion: await anonymizationService.getOSVersion(),
            deviceModel: await anonymizationService.getDeviceModel()
        )
        
        await trackEvent(event)
    }
    
    // MARK: - MetricKit Integration
    
    public func startMetricKitCollection() {
        #if canImport(MetricKit) && !os(macOS) && canImport(ObjectiveC)
        guard #available(iOS 15.0, *) else { return }
        
        // Subscribe to MetricKit payloads
        MXMetricManager.shared.add(self as! any MXMetricManagerSubscriber)
        #endif
    }
    
    public func stopMetricKitCollection() {
        #if canImport(MetricKit) && !os(macOS) && canImport(ObjectiveC)
        guard #available(iOS 15.0, *) else { return }
        
        // Unsubscribe from MetricKit payloads
        MXMetricManager.shared.remove(self as! any MXMetricManagerSubscriber)
        #endif
    }
    
    // MARK: - Aggregation
    
    public func performDailyAggregation() async {
        await aggregationService.performDailyAggregation()
    }
    
    public func performWeeklyAggregation() async {
        await aggregationService.performWeeklyAggregation()
    }
    
    public func performMonthlyAggregation() async {
        await aggregationService.performMonthlyAggregation()
    }
}

// MARK: - MetricKit Delegate

#if canImport(MetricKit) && !os(macOS) && canImport(ObjectiveC)
@available(iOS 15.0, *)
extension AnalyticsService {
    public func didReceive(_ payloads: [MXMetricPayload]) {
        Task {
            for payload in payloads {
                // Process diagnostic metrics
                await processMetricPayload(payload)
            }
        }
    }
    
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        Task {
            for payload in payloads {
                // Process diagnostic data
                await processDiagnosticPayload(payload)
            }
        }
    }
    
    private func processMetricPayload(_ payload: MXMetricPayload) async {
        // Extract performance metrics
        // Note: The actual properties may vary based on the MetricKit version
        // This is a simplified implementation
        
        // Track app launch time if available
        // In a real implementation, you would extract the actual values from the payload
        await trackPerformance(metric: "appLaunchTime", value: 0.0) // Placeholder
    }
    
    private func processDiagnosticPayload(_ payload: MXDiagnosticPayload) async {
        // Process crash diagnostics
        // Note: The actual properties may vary based on the MetricKit version
        // This is a simplified implementation
        
        // Track errors if available
        await trackError(category: "diagnostic", code: "unknown") // Placeholder
    }
}
#endif

