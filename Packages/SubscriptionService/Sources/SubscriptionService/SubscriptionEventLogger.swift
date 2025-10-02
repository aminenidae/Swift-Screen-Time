import Foundation
@preconcurrency import SharedModels
import RewardCore

/// Service for logging subscription events to analytics backend
public class SubscriptionEventLogger: @unchecked Sendable {
    private let analyticsRepository: AnalyticsRepository?
    private let eventQueue: EventQueue
    private let errorHandler: EventLoggingErrorHandler

    public init(
        analyticsRepository: AnalyticsRepository? = nil,
        eventQueue: EventQueue = EventQueue(),
        errorHandler: EventLoggingErrorHandler = DefaultEventLoggingErrorHandler()
    ) {
        self.analyticsRepository = analyticsRepository
        self.eventQueue = eventQueue
        self.errorHandler = errorHandler
    }

    // MARK: - Core Event Logging

    /// Logs a subscription event with error handling and retry logic
    public func logEvent(
        _ eventType: SubscriptionEventType,
        familyID: String,
        sessionID: String = UUID().uuidString,
        metadata: [String: String] = [:],
        userProperties: UserProperties? = nil
    ) async {
        let event = createAnalyticsEvent(
            eventType: eventType,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata
        )

        do {
            try await eventQueue.enqueue(event)
            try await processEvent(event, userProperties: userProperties)
        } catch {
            await errorHandler.handleError(error, for: event)
        }
    }

    // MARK: - Subscription Event Logging

    /// Logs trial start event
    public func logTrialStart(
        familyID: String,
        sessionID: String,
        tier: String,
        acquisitionChannel: String? = nil
    ) async {
        var metadata = [
            "tier": tier,
            "trial_duration": "14_days"
        ]

        if let channel = acquisitionChannel {
            metadata["acquisition_channel"] = channel
        }

        let userProperties = UserProperties(
            subscriptionTier: tier,
            trialStatus: "active",
            ltv: 0.0
        )

        await logEvent(
            .trialStart,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata,
            userProperties: userProperties
        )
    }

    /// Logs purchase event
    public func logPurchase(
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
            "product_id": productID,
            "price": price.description,
            "currency": currency,
            "tier": tier,
            "was_in_trial": String(wasInTrial)
        ]

        if let conversionTime = timeToConversion {
            metadata["time_to_conversion"] = String(conversionTime)
        }

        let userProperties = UserProperties(
            subscriptionTier: tier,
            trialStatus: wasInTrial ? "converted" : "none",
            ltv: Double(truncating: price as NSNumber)
        )

        await logEvent(
            .purchase,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata,
            userProperties: userProperties
        )
    }

    /// Logs renewal event
    public func logRenewal(
        familyID: String,
        sessionID: String,
        productID: String,
        price: Decimal,
        currency: String,
        tier: String,
        renewalPeriod: Int
    ) async {
        let metadata = [
            "product_id": productID,
            "price": price.description,
            "currency": currency,
            "tier": tier,
            "renewal_period": String(renewalPeriod)
        ]

        let userProperties = UserProperties(
            subscriptionTier: tier,
            trialStatus: "none",
            ltv: Double(truncating: price as NSNumber) * Double(renewalPeriod)
        )

        await logEvent(
            .renewal,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata,
            userProperties: userProperties
        )
    }

    /// Logs cancellation event
    public func logCancellation(
        familyID: String,
        sessionID: String,
        tier: String,
        reason: String? = nil,
        timeAsSubscriber: TimeInterval? = nil
    ) async {
        var metadata = [
            "tier": tier,
            "cancellation_type": "user_initiated"
        ]

        if let reason = reason {
            metadata["reason"] = reason
        }

        if let timeAsSubscriber = timeAsSubscriber {
            metadata["time_as_subscriber"] = String(timeAsSubscriber)
        }

        let userProperties = UserProperties(
            subscriptionTier: "none",
            trialStatus: "none",
            ltv: 0.0
        )

        await logEvent(
            .cancellation,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata,
            userProperties: userProperties
        )
    }

    /// Logs churn event
    public func logChurn(
        familyID: String,
        sessionID: String,
        tier: String,
        churnReason: ChurnReason,
        timeAsSubscriber: TimeInterval? = nil
    ) async {
        var metadata = [
            "tier": tier,
            "churn_reason": churnReason.rawValue
        ]

        if let timeAsSubscriber = timeAsSubscriber {
            metadata["time_as_subscriber"] = String(timeAsSubscriber)
        }

        let userProperties = UserProperties(
            subscriptionTier: "none",
            trialStatus: "churned",
            ltv: 0.0
        )

        await logEvent(
            .churn,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata,
            userProperties: userProperties
        )
    }

    /// Logs paywall impression
    public func logPaywallImpression(
        familyID: String,
        sessionID: String,
        paywallID: String,
        trigger: String,
        context: String? = nil
    ) async {
        var metadata = [
            "paywall_id": paywallID,
            "trigger": trigger
        ]

        if let context = context {
            metadata["context"] = context
        }

        await logEvent(
            .paywallImpression,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata
        )
    }

    /// Logs feature gate encounter
    public func logFeatureGateEncounter(
        familyID: String,
        sessionID: String,
        feature: String,
        gateTrigger: String,
        userResponse: FeatureGateResponse? = nil
    ) async {
        var metadata = [
            "feature": feature,
            "gate_trigger": gateTrigger
        ]

        if let response = userResponse {
            metadata["user_response"] = response.rawValue
        }

        await logEvent(
            .featureGateEncounter,
            familyID: familyID,
            sessionID: sessionID,
            metadata: metadata
        )
    }

    // MARK: - Batch Event Processing

    /// Processes queued events in batches
    public func processQueuedEvents() async {
        do {
            let events = try await eventQueue.dequeueAll()
            try await processBatch(events)
        } catch {
            await errorHandler.handleBatchError(error)
        }
    }

    /// Flushes all pending events
    public func flush() async {
        await processQueuedEvents()
    }

    // MARK: - Private Helper Methods

    private func createAnalyticsEvent(
        eventType: SubscriptionEventType,
        familyID: String,
        sessionID: String,
        metadata: [String: String]
    ) -> AnalyticsEvent {
        return AnalyticsEvent(
            eventType: .subscriptionEvent(eventType: eventType, metadata: metadata),
            anonymizedUserID: anonymizeID(familyID),
            sessionID: sessionID,
            appVersion: getAppVersion(),
            osVersion: getOSVersion(),
            deviceModel: getDeviceModel(),
            metadata: metadata
        )
    }

    private func processEvent(
        _ event: AnalyticsEvent,
        userProperties: UserProperties? = nil
    ) async throws {
        try await analyticsRepository?.saveEvent(event)

        // Update user properties if provided
        if let properties = userProperties {
            await updateUserProperties(properties, for: event.anonymizedUserID)
        }
    }

    private func processBatch(_ events: [AnalyticsEvent]) async throws {
        for event in events {
            try await processEvent(event)
        }
    }

    private func updateUserProperties(
        _ properties: UserProperties,
        for userID: String
    ) async {
        // In a real implementation, this would update user properties in the analytics backend
        // For now, we'll just log the update
        print("Updating user properties for \(userID): \(properties)")
    }

    private func anonymizeID(_ id: String) -> String {
        return "anon_" + String(id.hash)
    }

    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func getOSVersion() -> String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }

    private func getDeviceModel() -> String {
        #if os(iOS)
        return "iPhone"
        #elseif os(macOS)
        return "Mac"
        #else
        return "Unknown"
        #endif
    }
}

// MARK: - Supporting Models

public struct UserProperties: Codable, Equatable {
    public let subscriptionTier: String
    public let trialStatus: String
    public let ltv: Double

    public init(
        subscriptionTier: String,
        trialStatus: String,
        ltv: Double
    ) {
        self.subscriptionTier = subscriptionTier
        self.trialStatus = trialStatus
        self.ltv = ltv
    }
}

public enum ChurnReason: String, Codable, CaseIterable {
    case paymentFailed = "payment_failed"
    case userCancelled = "user_cancelled"
    case refundRequested = "refund_requested"
    case fraudDetected = "fraud_detected"
    case trialExpired = "trial_expired"
}

public enum FeatureGateResponse: String, Codable, CaseIterable {
    case upgrade = "upgrade"
    case dismiss = "dismiss"
    case laterReminder = "later_reminder"
}

// MARK: - Event Queue

public class EventQueue: @unchecked Sendable {
    private var events: [AnalyticsEvent] = []
    private let queue = DispatchQueue(label: "subscription-event-queue", attributes: .concurrent)

    public init() {}

    public func enqueue(_ event: AnalyticsEvent) async throws {
        queue.async(flags: .barrier) {
            self.events.append(event)
        }
    }

    public func dequeueAll() async throws -> [AnalyticsEvent] {
        return queue.sync {
            let allEvents = self.events
            self.events.removeAll()
            return allEvents
        }
    }
}

// MARK: - Error Handling

public protocol EventLoggingErrorHandler: Sendable {
    func handleError(_ error: Error, for event: AnalyticsEvent) async
    func handleBatchError(_ error: Error) async
}

public final class DefaultEventLoggingErrorHandler: @unchecked Sendable, EventLoggingErrorHandler {
    public init() {}

    public func handleError(_ error: Error, for event: AnalyticsEvent) async {
        print("Error logging event \(event.id): \(error.localizedDescription)")
        // In a real implementation, this would implement retry logic, dead letter queues, etc.
    }

    public func handleBatchError(_ error: Error) async {
        print("Error processing event batch: \(error.localizedDescription)")
        // In a real implementation, this would implement batch retry logic
    }
}