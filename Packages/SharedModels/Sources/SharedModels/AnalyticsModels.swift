import Foundation

// MARK: - Analytics Event Types

public enum AnalyticsEventType: Codable, Equatable {
    case featureUsage(feature: String)
    case userFlow(flow: String, step: String)
    case performance(metric: String, value: Double)
    case error(category: String, code: String)
    case engagement(type: String, duration: TimeInterval)
    case subscriptionEvent(eventType: SubscriptionEventType, metadata: [String: String] = [:])
}

// MARK: - Analytics Event

public struct AnalyticsEvent: Codable, Equatable, Identifiable {
    public let id: UUID
    public let eventType: AnalyticsEventType
    public let timestamp: Date
    public let anonymizedUserID: String     // Hashed family ID
    public let sessionID: String           // Analytics session identifier
    public let appVersion: String
    public let osVersion: String
    public let deviceModel: String         // Anonymized device type
    public let metadata: [String: String]  // Additional event-specific data
    
    public init(
        id: UUID = UUID(),
        eventType: AnalyticsEventType,
        timestamp: Date = Date(),
        anonymizedUserID: String,
        sessionID: String,
        appVersion: String,
        osVersion: String,
        deviceModel: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.eventType = eventType
        self.timestamp = timestamp
        self.anonymizedUserID = anonymizedUserID
        self.sessionID = sessionID
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.metadata = metadata
    }
}

// MARK: - Analytics Aggregation Types

public enum AggregationType: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
}

// MARK: - Retention Metrics

public struct RetentionMetrics: Codable, Equatable {
    public let dayOneRetention: Double     // Percentage
    public let daySevenRetention: Double
    public let dayThirtyRetention: Double
    public let cohortSize: Int
    
    public init(
        dayOneRetention: Double,
        daySevenRetention: Double,
        dayThirtyRetention: Double,
        cohortSize: Int
    ) {
        self.dayOneRetention = dayOneRetention
        self.daySevenRetention = daySevenRetention
        self.dayThirtyRetention = dayThirtyRetention
        self.cohortSize = cohortSize
    }
}

// MARK: - Memory Usage Metrics

public struct MemoryUsageMetrics: Codable, Equatable {
    public let averageMemory: Double       // MB
    public let peakMemory: Double          // MB
    public let memoryGrowthRate: Double    // MB/minute
    
    public init(
        averageMemory: Double,
        peakMemory: Double,
        memoryGrowthRate: Double
    ) {
        self.averageMemory = averageMemory
        self.peakMemory = peakMemory
        self.memoryGrowthRate = memoryGrowthRate
    }
}

// MARK: - Performance Metrics

public struct PerformanceMetrics: Codable, Equatable {
    public let averageAppLaunchTime: TimeInterval
    public let crashRate: Double           // Percentage
    public let averageBatteryImpact: Double
    public let memoryUsage: MemoryUsageMetrics
    
    public init(
        averageAppLaunchTime: TimeInterval,
        crashRate: Double,
        averageBatteryImpact: Double,
        memoryUsage: MemoryUsageMetrics
    ) {
        self.averageAppLaunchTime = averageAppLaunchTime
        self.crashRate = crashRate
        self.averageBatteryImpact = averageBatteryImpact
        self.memoryUsage = memoryUsage
    }
}

// MARK: - Analytics Aggregation

public struct AnalyticsAggregation: Codable, Equatable, Identifiable {
    public let id: UUID
    public let aggregationType: AggregationType
    public let startDate: Date
    public let endDate: Date
    public let totalUsers: Int             // Anonymous count
    public let totalSessions: Int
    public let averageSessionDuration: TimeInterval
    public let featureUsageCounts: [String: Int]
    public let retentionMetrics: RetentionMetrics
    public let performanceMetrics: PerformanceMetrics
    
    public init(
        id: UUID = UUID(),
        aggregationType: AggregationType,
        startDate: Date,
        endDate: Date,
        totalUsers: Int,
        totalSessions: Int,
        averageSessionDuration: TimeInterval,
        featureUsageCounts: [String: Int],
        retentionMetrics: RetentionMetrics,
        performanceMetrics: PerformanceMetrics
    ) {
        self.id = id
        self.aggregationType = aggregationType
        self.startDate = startDate
        self.endDate = endDate
        self.totalUsers = totalUsers
        self.totalSessions = totalSessions
        self.averageSessionDuration = averageSessionDuration
        self.featureUsageCounts = featureUsageCounts
        self.retentionMetrics = retentionMetrics
        self.performanceMetrics = performanceMetrics
    }
}

// MARK: - Analytics Consent Level

public enum AnalyticsConsentLevel: String, Codable, CaseIterable, Sendable {
    case none                       // No analytics collection
    case essential                  // Crash reports and critical metrics only
    case standard                   // Feature usage and performance
    case detailed                   // Comprehensive analytics (default)
}

// MARK: - Analytics Consent

/// Model representing a family's analytics consent
public struct AnalyticsConsent: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let familyID: String
    public let consentLevel: AnalyticsConsentLevel
    public let consentDate: Date
    public let consentVersion: String
    public let ipAddress: String?
    public let userAgent: String?
    public let lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        familyID: String,
        consentLevel: AnalyticsConsentLevel,
        consentDate: Date,
        consentVersion: String,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.familyID = familyID
        self.consentLevel = consentLevel
        self.consentDate = consentDate
        self.consentVersion = consentVersion
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Analytics Event Collector Protocol

@available(iOS 15.0, macOS 10.15, *)
public protocol AnalyticsEventCollector {
    func trackEvent(_ event: AnalyticsEvent) async
    func trackFeatureUsage(feature: String, metadata: [String: String]?) async
    func trackUserFlow(flow: String, step: String) async
    func trackPerformance(metric: String, value: Double) async
    func trackError(category: String, code: String) async
    func trackEngagement(type: String, duration: TimeInterval) async
}

// MARK: - Subscription Analytics Models

public enum SubscriptionEventType: String, Codable, CaseIterable {
    case paywallImpression = "paywall_impression"
    case paywallView = "paywall_view"
    case trialStart = "trial_start"
    case purchase = "purchase"
    case renewal = "renewal"
    case cancellation = "cancellation"
    case churn = "churn"
    case paywallDismiss = "paywall_dismiss"
    case featureGateEncounter = "feature_gate_encounter"
    case upgradeCTAClick = "upgrade_cta_click"
}

public struct ConversionFunnelEvent: Codable, Equatable, Identifiable {
    public let id: UUID
    public let funnelStage: FunnelStage
    public let timestamp: Date
    public let anonymizedUserID: String
    public let sessionID: String
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        funnelStage: FunnelStage,
        timestamp: Date = Date(),
        anonymizedUserID: String,
        sessionID: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.funnelStage = funnelStage
        self.timestamp = timestamp
        self.anonymizedUserID = anonymizedUserID
        self.sessionID = sessionID
        self.metadata = metadata
    }
}

public enum FunnelStage: String, Codable, CaseIterable {
    case paywallImpression = "paywall_impression"
    case paywallEngagement = "paywall_engagement"
    case trialStart = "trial_start"
    case purchase = "purchase"
    case retention = "retention"
}

public struct SubscriptionMetrics: Codable, Equatable {
    public let conversionRates: [String: Double]
    public let monthlyRecurringRevenue: Double
    public let annualRecurringRevenue: Double
    public let customerLifetimeValue: Double
    public let churnRate: Double
    public let averageRevenuePerUser: Double
    public let trialToPaidConversion: Double

    public init(
        conversionRates: [String: Double],
        monthlyRecurringRevenue: Double,
        annualRecurringRevenue: Double,
        customerLifetimeValue: Double,
        churnRate: Double,
        averageRevenuePerUser: Double,
        trialToPaidConversion: Double
    ) {
        self.conversionRates = conversionRates
        self.monthlyRecurringRevenue = monthlyRecurringRevenue
        self.annualRecurringRevenue = annualRecurringRevenue
        self.customerLifetimeValue = customerLifetimeValue
        self.churnRate = churnRate
        self.averageRevenuePerUser = averageRevenuePerUser
        self.trialToPaidConversion = trialToPaidConversion
    }
}

public struct CohortAnalysis: Codable, Equatable, Identifiable {
    public let id: UUID
    public let cohortStartDate: Date
    public let cohortSize: Int
    public let conversionRateByChannel: [String: Double]
    public let retentionByTier: [String: [String: Double]]
    public let acquisitionChannel: String?

    public init(
        id: UUID = UUID(),
        cohortStartDate: Date,
        cohortSize: Int,
        conversionRateByChannel: [String: Double],
        retentionByTier: [String: [String: Double]],
        acquisitionChannel: String? = nil
    ) {
        self.id = id
        self.cohortStartDate = cohortStartDate
        self.cohortSize = cohortSize
        self.conversionRateByChannel = conversionRateByChannel
        self.retentionByTier = retentionByTier
        self.acquisitionChannel = acquisitionChannel
    }
}

public struct ABTestVariant: Codable, Equatable, Identifiable {
    public let id: UUID
    public let testName: String
    public let variantName: String
    public let configuration: [String: String]
    public let isActive: Bool
    public let trafficAllocation: Double

    public init(
        id: UUID = UUID(),
        testName: String,
        variantName: String,
        configuration: [String: String],
        isActive: Bool,
        trafficAllocation: Double
    ) {
        self.id = id
        self.testName = testName
        self.variantName = variantName
        self.configuration = configuration
        self.isActive = isActive
        self.trafficAllocation = trafficAllocation
    }
}

public struct RevenueReport: Codable, Equatable, Identifiable {
    public let id: UUID
    public let reportType: ReportType
    public let startDate: Date
    public let endDate: Date
    public let totalRevenue: Double
    public let revenueByTier: [String: Double]
    public let refunds: Double
    public let netRevenue: Double

    public init(
        id: UUID = UUID(),
        reportType: ReportType,
        startDate: Date,
        endDate: Date,
        totalRevenue: Double,
        revenueByTier: [String: Double],
        refunds: Double,
        netRevenue: Double
    ) {
        self.id = id
        self.reportType = reportType
        self.startDate = startDate
        self.endDate = endDate
        self.totalRevenue = totalRevenue
        self.revenueByTier = revenueByTier
        self.refunds = refunds
        self.netRevenue = netRevenue
    }
}

public enum ReportType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

public struct OptimizationInsight: Codable, Equatable, Identifiable {
    public let id: UUID
    public let insightType: InsightType
    public let title: String
    public let description: String
    public let impact: InsightImpact
    public let recommendations: [String]
    public let dataPoints: [String: Double]

    public init(
        id: UUID = UUID(),
        insightType: InsightType,
        title: String,
        description: String,
        impact: InsightImpact,
        recommendations: [String],
        dataPoints: [String: Double]
    ) {
        self.id = id
        self.insightType = insightType
        self.title = title
        self.description = description
        self.impact = impact
        self.recommendations = recommendations
        self.dataPoints = dataPoints
    }
}

public enum InsightType: String, Codable, CaseIterable {
    case conversionDropOff = "conversion_drop_off"
    case pricingSensitivity = "pricing_sensitivity"
    case featureValuePerception = "feature_value_perception"
}

public enum InsightImpact: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

// MARK: - Analytics Repository Protocol

/// Protocol defining the interface for analytics data persistence
@available(iOS 15.0, macOS 10.15, *)
public protocol AnalyticsRepository: Sendable {
    /// Saves an analytics event
    /// - Parameter event: The analytics event to save
    func saveEvent(_ event: AnalyticsEvent) async throws
    
    /// Fetches analytics events for a specific family within a date range
    /// - Parameters:
    ///   - familyID: The family identifier to filter events for
    ///   - dateRange: The date range to filter events within
    /// - Returns: Array of analytics events matching the criteria
    func fetchEvents(for familyID: String, dateRange: DateRange?) async throws -> [AnalyticsEvent]
    
    /// Saves an analytics aggregation
    /// - Parameter aggregation: The analytics aggregation to save
    func saveAggregation(_ aggregation: AnalyticsAggregation) async throws
    
    /// Fetches analytics aggregations for a specific type within a date range
    /// - Parameters:
    ///   - aggregationType: The aggregation type to filter for
    ///   - dateRange: The date range to filter within
    /// - Returns: Array of analytics aggregations matching the criteria
    func fetchAggregations(for aggregationType: AggregationType, dateRange: DateRange?) async throws -> [AnalyticsAggregation]
    
    /// Saves analytics consent
    /// - Parameter consent: The analytics consent to save
    func saveConsent(_ consent: AnalyticsConsent) async throws
    
    /// Fetches analytics consent for a specific family
    /// - Parameter familyID: The family identifier to fetch consent for
    /// - Returns: The analytics consent for the family, if any
    func fetchConsent(for familyID: String) async throws -> AnalyticsConsent?
}