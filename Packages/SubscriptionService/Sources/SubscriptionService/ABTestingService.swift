import Foundation
import SharedModels
import RewardCore

/// Service for A/B testing subscription optimization
public class ABTestingService: @unchecked Sendable {
    private let analyticsRepository: AnalyticsRepository?
    private var activeTests: [String: ABTest] = [:]
    private let userVariantCache: [String: String] = [:]

    public init(analyticsRepository: AnalyticsRepository? = nil) {
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Test Management

    /// Creates a new A/B test
    public func createTest(
        testName: String,
        variants: [ABTestVariant],
        trafficAllocation: Double = 1.0
    ) async throws {
        guard trafficAllocation > 0 && trafficAllocation <= 1.0 else {
            throw ABTestingError.invalidTrafficAllocation
        }

        let totalAllocation = variants.reduce(0) { $0 + $1.trafficAllocation }
        guard totalAllocation <= 1.0 else {
            throw ABTestingError.invalidVariantAllocation
        }

        let test = ABTest(
            name: testName,
            variants: variants,
            trafficAllocation: trafficAllocation,
            isActive: true,
            startDate: Date()
        )

        activeTests[testName] = test
    }

    /// Gets the variant for a user in a specific test
    public func getVariant(
        testName: String,
        userID: String
    ) async -> ABTestVariant? {
        guard let test = activeTests[testName], test.isActive else {
            return nil
        }

        // Check if user is in traffic allocation
        let userHash = Double(abs(userID.hash)) / Double(Int.max)
        guard userHash <= test.trafficAllocation else {
            return nil
        }

        // Determine variant based on consistent hashing
        let variantHash = Double(abs((userID + testName).hash)) / Double(Int.max)

        var cumulativeAllocation: Double = 0
        for variant in test.variants {
            cumulativeAllocation += variant.trafficAllocation
            if variantHash <= cumulativeAllocation {
                return variant
            }
        }

        return test.variants.first
    }

    /// Tracks A/B test exposure
    public func trackExposure(
        testName: String,
        variantName: String,
        userID: String,
        sessionID: String
    ) async {
        let event = AnalyticsEvent(
            eventType: .subscriptionEvent(
                eventType: .featureGateEncounter,
                metadata: [
                    "test_name": testName,
                    "variant": variantName,
                    "event_type": "exposure"
                ]
            ),
            anonymizedUserID: anonymizeID(userID),
            sessionID: sessionID,
            appVersion: await getAppVersion(),
            osVersion: await getOSVersion(),
            deviceModel: await getDeviceModel()
        )

        try? await analyticsRepository?.saveEvent(event)
    }

    /// Tracks A/B test conversion
    public func trackConversion(
        testName: String,
        variantName: String,
        userID: String,
        sessionID: String,
        conversionType: String
    ) async {
        let event = AnalyticsEvent(
            eventType: .subscriptionEvent(
                eventType: .purchase,
                metadata: [
                    "test_name": testName,
                    "variant": variantName,
                    "conversion_type": conversionType,
                    "event_type": "conversion"
                ]
            ),
            anonymizedUserID: anonymizeID(userID),
            sessionID: sessionID,
            appVersion: await getAppVersion(),
            osVersion: await getOSVersion(),
            deviceModel: await getDeviceModel()
        )

        try? await analyticsRepository?.saveEvent(event)
    }

    // MARK: - Paywall Design Testing

    /// Creates paywall design variant test
    public func createPaywallTest(
        testName: String,
        designs: [PaywallDesign]
    ) async throws {
        let variants = designs.map { design in
            ABTestVariant(
                testName: testName,
                variantName: design.name,
                configuration: design.configuration,
                isActive: true,
                trafficAllocation: design.trafficAllocation
            )
        }

        try await createTest(
            testName: testName,
            variants: variants,
            trafficAllocation: 1.0
        )
    }

    /// Gets paywall design configuration for user
    public func getPaywallDesign(
        testName: String,
        userID: String
    ) async -> PaywallDesign? {
        guard let variant = await getVariant(testName: testName, userID: userID) else {
            return nil
        }

        return PaywallDesign(
            name: variant.variantName,
            configuration: variant.configuration,
            trafficAllocation: variant.trafficAllocation
        )
    }

    // MARK: - Pricing Experiments

    /// Creates pricing experiment
    public func createPricingExperiment(
        testName: String,
        pricePoints: [PricePoint]
    ) async throws {
        let variants = pricePoints.map { pricePoint in
            ABTestVariant(
                testName: testName,
                variantName: "price_\(pricePoint.price)",
                configuration: [
                    "price": String(describing: pricePoint.price),
                    "currency": pricePoint.currency,
                    "tier": pricePoint.tier
                ],
                isActive: true,
                trafficAllocation: pricePoint.trafficAllocation
            )
        }

        try await createTest(
            testName: testName,
            variants: variants,
            trafficAllocation: 1.0
        )
    }

    /// Gets price point for user
    public func getPricePoint(
        testName: String,
        userID: String
    ) async -> PricePoint? {
        guard let variant = await getVariant(testName: testName, userID: userID) else {
            return nil
        }

        guard let priceString = variant.configuration["price"],
              let price = Decimal(string: priceString),
              let currency = variant.configuration["currency"],
              let tier = variant.configuration["tier"] else {
            return nil
        }

        return PricePoint(
            price: price,
            currency: currency,
            tier: tier,
            trafficAllocation: variant.trafficAllocation
        )
    }

    // MARK: - Feature Gate Experiments

    /// Creates feature gate experiment
    public func createFeatureGateExperiment(
        testName: String,
        gateConfigurations: [FeatureGateConfiguration]
    ) async throws {
        let variants = gateConfigurations.map { config in
            ABTestVariant(
                testName: testName,
                variantName: config.name,
                configuration: config.settings,
                isActive: true,
                trafficAllocation: config.trafficAllocation
            )
        }

        try await createTest(
            testName: testName,
            variants: variants,
            trafficAllocation: 1.0
        )
    }

    /// Gets feature gate configuration for user
    public func getFeatureGateConfiguration(
        testName: String,
        userID: String
    ) async -> FeatureGateConfiguration? {
        guard let variant = await getVariant(testName: testName, userID: userID) else {
            return nil
        }

        return FeatureGateConfiguration(
            name: variant.variantName,
            settings: variant.configuration,
            trafficAllocation: variant.trafficAllocation
        )
    }

    // MARK: - Test Analysis

    /// Analyzes A/B test results
    public func analyzeTestResults(
        testName: String,
        dateRange: DateRange
    ) async throws -> ABTestResults {
        guard let repository = analyticsRepository else {
            throw ABTestingError.repositoryNotAvailable
        }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        let testEvents = events.filter { event in
            if case .subscriptionEvent(_, let metadata) = event.eventType {
                return metadata["test_name"] == testName
            }
            return false
        }

        var variantStats: [String: VariantStats] = [:]

        for event in testEvents {
            if case .subscriptionEvent(_, let metadata) = event.eventType,
               let variant = metadata["variant"],
               let eventType = metadata["event_type"] {

                if variantStats[variant] == nil {
                    variantStats[variant] = VariantStats(
                        variantName: variant,
                        exposures: 0,
                        conversions: 0,
                        conversionRate: 0.0
                    )
                }

                switch eventType {
                case "exposure":
                    variantStats[variant]?.exposures += 1
                case "conversion":
                    variantStats[variant]?.conversions += 1
                default:
                    break
                }
            }
        }

        // Calculate conversion rates
        for (variant, _) in variantStats {
            if let stats = variantStats[variant], stats.exposures > 0 {
                variantStats[variant]?.conversionRate = Double(stats.conversions) / Double(stats.exposures)
            }
        }

        return ABTestResults(
            testName: testName,
            variantStats: Array(variantStats.values),
            isStatisticallySignificant: calculateStatisticalSignificance(variantStats)
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

    private func calculateStatisticalSignificance(_ variantStats: [String: VariantStats]) -> Bool {
        // Simplified statistical significance calculation
        // In a production environment, you would use proper statistical tests
        let variants = Array(variantStats.values)
        guard variants.count >= 2 else { return false }

        let sampleSizes = variants.map { $0.exposures }
        let minSampleSize = sampleSizes.min() ?? 0

        // Basic check: need at least 100 exposures per variant
        return minSampleSize >= 100
    }
}

// MARK: - Supporting Models

public struct ABTest: Codable, Equatable {
    public let name: String
    public let variants: [ABTestVariant]
    public let trafficAllocation: Double
    public let isActive: Bool
    public let startDate: Date

    public init(
        name: String,
        variants: [ABTestVariant],
        trafficAllocation: Double,
        isActive: Bool,
        startDate: Date
    ) {
        self.name = name
        self.variants = variants
        self.trafficAllocation = trafficAllocation
        self.isActive = isActive
        self.startDate = startDate
    }
}

public struct PaywallDesign: Codable, Equatable {
    public let name: String
    public let configuration: [String: String]
    public let trafficAllocation: Double

    public init(
        name: String,
        configuration: [String: String],
        trafficAllocation: Double
    ) {
        self.name = name
        self.configuration = configuration
        self.trafficAllocation = trafficAllocation
    }
}

public struct PricePoint: Codable, Equatable {
    public let price: Decimal
    public let currency: String
    public let tier: String
    public let trafficAllocation: Double

    public init(
        price: Decimal,
        currency: String,
        tier: String,
        trafficAllocation: Double
    ) {
        self.price = price
        self.currency = currency
        self.tier = tier
        self.trafficAllocation = trafficAllocation
    }
}

public struct FeatureGateConfiguration: Codable, Equatable {
    public let name: String
    public let settings: [String: String]
    public let trafficAllocation: Double

    public init(
        name: String,
        settings: [String: String],
        trafficAllocation: Double
    ) {
        self.name = name
        self.settings = settings
        self.trafficAllocation = trafficAllocation
    }
}

public struct VariantStats: Codable, Equatable {
    public let variantName: String
    public var exposures: Int
    public var conversions: Int
    public var conversionRate: Double

    public init(
        variantName: String,
        exposures: Int,
        conversions: Int,
        conversionRate: Double
    ) {
        self.variantName = variantName
        self.exposures = exposures
        self.conversions = conversions
        self.conversionRate = conversionRate
    }
}

public struct ABTestResults: Codable, Equatable {
    public let testName: String
    public let variantStats: [VariantStats]
    public let isStatisticallySignificant: Bool

    public init(
        testName: String,
        variantStats: [VariantStats],
        isStatisticallySignificant: Bool
    ) {
        self.testName = testName
        self.variantStats = variantStats
        self.isStatisticallySignificant = isStatisticallySignificant
    }
}

// MARK: - Errors

public enum ABTestingError: Error, LocalizedError {
    case invalidTrafficAllocation
    case invalidVariantAllocation
    case repositoryNotAvailable

    public var errorDescription: String? {
        switch self {
        case .invalidTrafficAllocation:
            return "Traffic allocation must be between 0.0 and 1.0"
        case .invalidVariantAllocation:
            return "Total variant allocation cannot exceed 1.0"
        case .repositoryNotAvailable:
            return "Analytics repository is not available"
        }
    }
}