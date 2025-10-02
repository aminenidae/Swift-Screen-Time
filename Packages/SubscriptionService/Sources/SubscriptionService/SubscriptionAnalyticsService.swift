import Foundation
import SharedModels
import StoreKit
import RewardCore

/// Service for subscription analytics and optimization
public class SubscriptionAnalyticsService: @unchecked Sendable {
    private let analyticsRepository: AnalyticsRepository?

    public init(
        analyticsRepository: AnalyticsRepository? = nil
    ) {
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Conversion Funnel Tracking

    /// Tracks paywall impression events
    public func trackPaywallImpression(
        paywallID: String,
        trigger: String,
        familyID: String,
        sessionID: String
    ) async {
        let event = AnalyticsEvent(
            eventType: .subscriptionEvent(
                eventType: .paywallImpression,
                metadata: [
                    "paywall_id": paywallID,
                    "trigger": trigger,
                    "family_id": familyID
                ]
            ),
            anonymizedUserID: anonymizeID(familyID),
            sessionID: sessionID,
            appVersion: await getAppVersion(),
            osVersion: await getOSVersion(),
            deviceModel: await getDeviceModel()
        )

        try? await analyticsRepository?.saveEvent(event)
    }

    /// Tracks trial start events
    public func trackTrialStart(
        familyID: String,
        sessionID: String,
        tier: String,
        acquisitionChannel: String? = nil
    ) async {
        var metadata = [
            "family_id": familyID,
            "tier": tier
        ]

        if let channel = acquisitionChannel {
            metadata["acquisition_channel"] = channel
        }

        let event = AnalyticsEvent(
            eventType: .subscriptionEvent(
                eventType: .trialStart,
                metadata: metadata
            ),
            anonymizedUserID: anonymizeID(familyID),
            sessionID: sessionID,
            appVersion: await getAppVersion(),
            osVersion: await getOSVersion(),
            deviceModel: await getDeviceModel()
        )

        try? await analyticsRepository?.saveEvent(event)
    }

    /// Tracks purchase events with comprehensive metadata
    public func trackPurchase(
        familyID: String,
        sessionID: String,
        productID: String,
        price: Decimal,
        currency: String,
        tier: String,
        wasInTrial: Bool,
        timeToConversion: TimeInterval? = nil
    ) async {
        var metadata = [
            "family_id": familyID,
            "product_id": productID,
            "price": price.description,
            "currency": currency,
            "tier": tier,
            "was_in_trial": String(wasInTrial)
        ]

        if let conversionTime = timeToConversion {
            metadata["time_to_conversion"] = String(conversionTime)
        }

        let event = AnalyticsEvent(
            eventType: .subscriptionEvent(
                eventType: .purchase,
                metadata: metadata
            ),
            anonymizedUserID: anonymizeID(familyID),
            sessionID: sessionID,
            appVersion: await getAppVersion(),
            osVersion: await getOSVersion(),
            deviceModel: await getDeviceModel()
        )

        try? await analyticsRepository?.saveEvent(event)
    }

    /// Calculates conversion rates per funnel stage
    public func calculateConversionRates(
        dateRange: SharedModels.DateRange
    ) async throws -> [String: Double] {
        guard let repository = analyticsRepository else {
            return [:]
        }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        let subscriptionEvents = events.compactMap { event -> (SubscriptionEventType, AnalyticsEvent)? in
            if case .subscriptionEvent(let eventType, _) = event.eventType {
                return (eventType, event)
            }
            return nil
        }

        let impressions = subscriptionEvents.filter { $0.0 == SubscriptionEventType.paywallImpression }.count
        let trials = subscriptionEvents.filter { $0.0 == SubscriptionEventType.trialStart }.count
        let purchases = subscriptionEvents.filter { $0.0 == SubscriptionEventType.purchase }.count

        var conversionRates: [String: Double] = [:]

        if impressions > 0 {
            conversionRates["impression_to_trial"] = Double(trials) / Double(impressions)
            conversionRates["impression_to_purchase"] = Double(purchases) / Double(impressions)
        }

        if trials > 0 {
            conversionRates["trial_to_purchase"] = Double(purchases) / Double(trials)
        }

        return conversionRates
    }

    // MARK: - Key Metrics Calculation

    /// Calculates trial-to-paid conversion rate
    public func calculateTrialToPaidConversion(dateRange: SharedModels.DateRange) async throws -> Double {
        let conversionRates = try await calculateConversionRates(dateRange: dateRange)
        return conversionRates["trial_to_purchase"] ?? 0.0
    }

    /// Calculates Monthly Recurring Revenue (MRR)
    public func calculateMRR(dateRange: SharedModels.DateRange) async throws -> Double {
        guard let repository = analyticsRepository else { return 0.0 }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        let purchaseEvents = events.filter { event in
            if case .subscriptionEvent(let eventType, _) = event.eventType {
                return eventType == .purchase
            }
            return false
        }

        var totalMRR: Double = 0.0

        for event in purchaseEvents {
            if case .subscriptionEvent(_, let metadata) = event.eventType,
               let priceString = metadata["price"],
               let price = Double(priceString) {
                // Convert to monthly recurring value
                totalMRR += price
            }
        }

        return totalMRR
    }

    /// Calculates Annual Recurring Revenue (ARR)
    public func calculateARR(dateRange: SharedModels.DateRange) async throws -> Double {
        let mrr = try await calculateMRR(dateRange: dateRange)
        return mrr * 12
    }

    /// Computes Customer Lifetime Value (LTV)
    public func calculateLTV(dateRange: SharedModels.DateRange) async throws -> Double {
        let arpu = try await calculateARPU(dateRange: dateRange)
        let churnRate = try await calculateChurnRate(dateRange: dateRange)

        if churnRate > 0 {
            return arpu / churnRate
        }

        return 0.0
    }

    /// Tracks churn rate metrics
    public func calculateChurnRate(dateRange: SharedModels.DateRange) async throws -> Double {
        guard let repository = analyticsRepository else { return 0.0 }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        let subscriptionEvents = events.compactMap { event -> SubscriptionEventType? in
            if case .subscriptionEvent(let eventType, _) = event.eventType {
                return eventType
            }
            return nil
        }

        let activeSubscriptions = subscriptionEvents.filter { $0 == SubscriptionEventType.purchase || $0 == SubscriptionEventType.renewal }.count
        let churns = subscriptionEvents.filter { $0 == SubscriptionEventType.churn || $0 == SubscriptionEventType.cancellation }.count

        if activeSubscriptions > 0 {
            return Double(churns) / Double(activeSubscriptions)
        }

        return 0.0
    }

    /// Calculates Average Revenue Per User (ARPU)
    public func calculateARPU(dateRange: SharedModels.DateRange) async throws -> Double {
        let mrr = try await calculateMRR(dateRange: dateRange)

        guard let repository = analyticsRepository else { return 0.0 }
        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        let uniqueUsers = Set(events.map { $0.anonymizedUserID }).count

        if uniqueUsers > 0 {
            return mrr / Double(uniqueUsers)
        }

        return 0.0
    }

    /// Creates comprehensive subscription metrics
    public func generateSubscriptionMetrics(dateRange: SharedModels.DateRange) async throws -> SubscriptionMetrics {
        let conversionRates = try await calculateConversionRates(dateRange: dateRange)
        let mrr = try await calculateMRR(dateRange: dateRange)
        let arr = try await calculateARR(dateRange: dateRange)
        let ltv = try await calculateLTV(dateRange: dateRange)
        let churnRate = try await calculateChurnRate(dateRange: dateRange)
        let arpu = try await calculateARPU(dateRange: dateRange)
        let trialToPaid = try await calculateTrialToPaidConversion(dateRange: dateRange)

        return SubscriptionMetrics(
            conversionRates: conversionRates,
            monthlyRecurringRevenue: mrr,
            annualRecurringRevenue: arr,
            customerLifetimeValue: ltv,
            churnRate: churnRate,
            averageRevenuePerUser: arpu,
            trialToPaidConversion: trialToPaid
        )
    }

    // MARK: - Helper Methods

    private func anonymizeID(_ id: String) -> String {
        return "anon_" + String(id.hash)
    }

    private func getAppVersion() async -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func getOSVersion() async -> String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }

    private func getDeviceModel() async -> String {
        #if os(iOS)
        return "iPhone"
        #elseif os(macOS)
        return "Mac"
        #else
        return "Unknown"
        #endif
    }
}

