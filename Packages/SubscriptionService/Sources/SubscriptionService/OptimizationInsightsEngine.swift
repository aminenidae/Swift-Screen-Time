import Foundation
import SharedModels
import RewardCore

/// Service for generating optimization insights and recommendations
public class OptimizationInsightsEngine: @unchecked Sendable {
    private let analyticsRepository: AnalyticsRepository?
    private let subscriptionAnalyticsService: SubscriptionAnalyticsService
    private let cohortAnalysisService: CohortAnalysisService
    private let abTestingService: ABTestingService

    public init(
        analyticsRepository: AnalyticsRepository? = nil,
        subscriptionAnalyticsService: SubscriptionAnalyticsService,
        cohortAnalysisService: CohortAnalysisService,
        abTestingService: ABTestingService
    ) {
        self.analyticsRepository = analyticsRepository
        self.subscriptionAnalyticsService = subscriptionAnalyticsService
        self.cohortAnalysisService = cohortAnalysisService
        self.abTestingService = abTestingService
    }

    // MARK: - Drop-off Point Identification

    /// Identifies drop-off points in the conversion funnel
    public func identifyConversionDropOffs(
        dateRange: SharedModels.DateRange
    ) async throws -> [OptimizationInsight] {
        let conversionRates = try await subscriptionAnalyticsService.calculateConversionRates(dateRange: dateRange)
        var insights: [OptimizationInsight] = []

        // Analyze impression to trial conversion
        if let impressionToTrial = conversionRates["impression_to_trial"] {
            if impressionToTrial < 0.15 { // Less than 15% conversion
                insights.append(createDropOffInsight(
                    stage: "Paywall Impression → Trial Start",
                    conversionRate: impressionToTrial,
                    recommendations: [
                        "Optimize paywall design and messaging",
                        "Test different value propositions",
                        "Reduce friction in trial signup process",
                        "Add social proof and testimonials"
                    ]
                ))
            }
        }

        // Analyze trial to paid conversion
        if let trialToPaid = conversionRates["trial_to_purchase"] {
            if trialToPaid < 0.25 { // Less than 25% conversion
                insights.append(createDropOffInsight(
                    stage: "Trial → Paid Subscription",
                    conversionRate: trialToPaid,
                    recommendations: [
                        "Improve trial experience and onboarding",
                        "Send targeted conversion reminders",
                        "Highlight premium features during trial",
                        "Optimize trial-to-paid flow timing"
                    ]
                ))
            }
        }

        return insights
    }

    /// Identifies feature-specific drop-off points
    public func identifyFeatureDropOffs(
        dateRange: SharedModels.DateRange
    ) async throws -> [OptimizationInsight] {
        guard let repository = analyticsRepository else { return [] }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        let featureGateEvents = events.filter { event in
            if case .subscriptionEvent(let eventType, _) = event.eventType {
                return eventType == .featureGateEncounter
            }
            return false
        }

        var featureEncounters: [String: Int] = [:]
        var featureUpgrades: [String: Int] = [:]

        for event in featureGateEvents {
            if case .subscriptionEvent(_, let metadata) = event.eventType,
               let feature = metadata["feature"] {
                featureEncounters[feature, default: 0] += 1

                if let response = metadata["user_response"], response == "upgrade" {
                    featureUpgrades[feature, default: 0] += 1
                }
            }
        }

        var insights: [OptimizationInsight] = []

        for (feature, encounters) in featureEncounters {
            let upgrades = featureUpgrades[feature] ?? 0
            let conversionRate = encounters > 0 ? Double(upgrades) / Double(encounters) : 0.0

            if conversionRate < 0.10 && encounters > 50 { // Less than 10% with significant volume
                insights.append(OptimizationInsight(
                    insightType: .conversionDropOff,
                    title: "Low Feature Gate Conversion: \(feature)",
                    description: "Feature \(feature) has a \(String(format: "%.1f", conversionRate * 100))% conversion rate from gate encounters to upgrades.",
                    impact: encounters > 200 ? .high : .medium,
                    recommendations: [
                        "Improve feature value communication",
                        "Test different gate messaging",
                        "Consider freemium alternative",
                        "Optimize gate placement and timing"
                    ],
                    dataPoints: [
                        "encounters": Double(encounters),
                        "upgrades": Double(upgrades),
                        "conversion_rate": conversionRate
                    ]
                ))
            }
        }

        return insights
    }

    // MARK: - Pricing Sensitivity Analysis

    /// Analyzes pricing sensitivity based on A/B test results
    public func analyzePricingSensitivity(
        pricingTestName: String,
        dateRange: DateRange
    ) async throws -> [OptimizationInsight] {
        let testResults = try await abTestingService.analyzeTestResults(
            testName: pricingTestName,
            dateRange: dateRange
        )

        var insights: [OptimizationInsight] = []

        // Analyze conversion rates by price point
        let sortedVariants = testResults.variantStats.sorted { $0.variantName < $1.variantName }

        for i in 0..<sortedVariants.count {
            let variant = sortedVariants[i]

            // Extract price from variant name (assumes format "price_X.XX")
            guard let priceString = variant.variantName.components(separatedBy: "_").last,
                  let price = Double(priceString) else {
                continue
            }

            var recommendations: [String] = []
            var impact = InsightImpact.medium

            // Compare with other variants
            let avgConversionRate = sortedVariants.map { $0.conversionRate }.reduce(0, +) / Double(sortedVariants.count)

            if variant.conversionRate > avgConversionRate * 1.2 {
                recommendations = [
                    "Consider this as the optimal price point",
                    "Test slightly higher prices to find ceiling",
                    "Implement price tier for this segment"
                ]
                impact = .high
            } else if variant.conversionRate < avgConversionRate * 0.8 {
                recommendations = [
                    "Price may be too high for target market",
                    "Test lower price points",
                    "Consider value-based pricing strategies"
                ]
                impact = .high
            }

            if !recommendations.isEmpty {
                insights.append(OptimizationInsight(
                    insightType: .pricingSensitivity,
                    title: "Pricing Sensitivity at $\(priceString)",
                    description: "Price point $\(priceString) shows \(String(format: "%.1f", variant.conversionRate * 100))% conversion rate.",
                    impact: impact,
                    recommendations: recommendations,
                    dataPoints: [
                        "price": price,
                        "conversion_rate": variant.conversionRate,
                        "exposures": Double(variant.exposures),
                        "conversions": Double(variant.conversions)
                    ]
                ))
            }
        }

        return insights
    }

    /// Analyzes price elasticity of demand
    public func analyzePriceElasticity(
        pricingTests: [String],
        dateRange: DateRange
    ) async throws -> OptimizationInsight? {
        var pricePoints: [(price: Double, demand: Double)] = []

        for testName in pricingTests {
            let testResults = try await abTestingService.analyzeTestResults(
                testName: testName,
                dateRange: dateRange
            )

            for variant in testResults.variantStats {
                guard let priceString = variant.variantName.components(separatedBy: "_").last,
                      let price = Double(priceString) else {
                    continue
                }

                let demand = Double(variant.conversions)
                pricePoints.append((price: price, demand: demand))
            }
        }

        guard pricePoints.count >= 3 else { return nil }

        // Calculate price elasticity (simplified)
        pricePoints.sort { $0.price < $1.price }
        let elasticities = calculateElasticities(pricePoints)
        let avgElasticity = elasticities.reduce(0, +) / Double(elasticities.count)

        var recommendations: [String] = []
        var impact = InsightImpact.medium

        if avgElasticity < -1.0 {
            // Elastic demand
            recommendations = [
                "Demand is price-sensitive - consider lower pricing",
                "Focus on value communication over premium pricing",
                "Test promotional pricing strategies"
            ]
            impact = .high
        } else if avgElasticity > -0.5 {
            // Inelastic demand
            recommendations = [
                "Demand is not highly price-sensitive",
                "Consider testing higher price points",
                "Focus on premium positioning"
            ]
            impact = .high
        }

        return OptimizationInsight(
            insightType: .pricingSensitivity,
            title: "Price Elasticity Analysis",
            description: "Average price elasticity of demand is \(String(format: "%.2f", avgElasticity))",
            impact: impact,
            recommendations: recommendations,
            dataPoints: [
                "average_elasticity": avgElasticity,
                "data_points": Double(pricePoints.count)
            ]
        )
    }

    // MARK: - Feature Value Perception

    /// Analyzes feature value perception based on usage and conversion
    public func analyzeFeatureValuePerception(
        dateRange: SharedModels.DateRange
    ) async throws -> [OptimizationInsight] {
        guard let repository = analyticsRepository else { return [] }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        var featureMetrics: [String: FeatureMetrics] = [:]

        // Collect feature usage and conversion data
        for event in events {
            switch event.eventType {
            case .featureUsage(let feature):
                if featureMetrics[feature] == nil {
                    featureMetrics[feature] = FeatureMetrics()
                }
                featureMetrics[feature]?.usageCount += 1

            case .subscriptionEvent(let eventType, let metadata):
                if eventType == .featureGateEncounter,
                   let feature = metadata["feature"] {
                    if featureMetrics[feature] == nil {
                        featureMetrics[feature] = FeatureMetrics()
                    }
                    featureMetrics[feature]?.gateEncounters += 1

                    if let response = metadata["user_response"], response == "upgrade" {
                        featureMetrics[feature]?.conversions += 1
                    }
                }

            default:
                break
            }
        }

        var insights: [OptimizationInsight] = []

        for (feature, metrics) in featureMetrics {
            let conversionRate = metrics.gateEncounters > 0 ?
                Double(metrics.conversions) / Double(metrics.gateEncounters) : 0.0

            let usageToGateRatio = metrics.usageCount > 0 ?
                Double(metrics.gateEncounters) / Double(metrics.usageCount) : 0.0

            // High usage, low conversion = value perception issue
            if metrics.usageCount > 100 && conversionRate < 0.05 {
                insights.append(OptimizationInsight(
                    insightType: .featureValuePerception,
                    title: "Low Value Perception: \(feature)",
                    description: "Feature \(feature) has high usage (\(metrics.usageCount)) but low conversion rate (\(String(format: "%.1f", conversionRate * 100))%).",
                    impact: .high,
                    recommendations: [
                        "Improve value proposition communication",
                        "Highlight premium benefits more clearly",
                        "Consider reducing friction in upgrade flow",
                        "Test different pricing for this feature"
                    ],
                    dataPoints: [
                        "usage_count": Double(metrics.usageCount),
                        "gate_encounters": Double(metrics.gateEncounters),
                        "conversions": Double(metrics.conversions),
                        "conversion_rate": conversionRate,
                        "usage_to_gate_ratio": usageToGateRatio
                    ]
                ))
            }

            // Low usage, high gate encounters = discoverability issue
            if usageToGateRatio > 0.5 && metrics.usageCount < 50 {
                insights.append(OptimizationInsight(
                    insightType: .featureValuePerception,
                    title: "Discoverability Issue: \(feature)",
                    description: "Feature \(feature) has more gate encounters than usage, suggesting discoverability issues.",
                    impact: .medium,
                    recommendations: [
                        "Improve feature discovery and onboarding",
                        "Add feature hints and tooltips",
                        "Consider repositioning in UI",
                        "Test different entry points"
                    ],
                    dataPoints: [
                        "usage_count": Double(metrics.usageCount),
                        "gate_encounters": Double(metrics.gateEncounters),
                        "usage_to_gate_ratio": usageToGateRatio
                    ]
                ))
            }
        }

        return insights
    }

    // MARK: - Comprehensive Insights Generation

    /// Generates comprehensive optimization insights
    public func generateComprehensiveInsights(
        dateRange: SharedModels.DateRange,
        pricingTests: [String] = [],
        featureTests: [String] = []
    ) async throws -> [OptimizationInsight] {
        var allInsights: [OptimizationInsight] = []

        // Conversion funnel insights
        allInsights.append(contentsOf: try await identifyConversionDropOffs(dateRange: dateRange))
        allInsights.append(contentsOf: try await identifyFeatureDropOffs(dateRange: dateRange))

        // Pricing insights
        for testName in pricingTests {
            allInsights.append(contentsOf: try await analyzePricingSensitivity(
                pricingTestName: testName,
                dateRange: dateRange
            ))
        }

        if let elasticityInsight = try await analyzePriceElasticity(
            pricingTests: pricingTests,
            dateRange: dateRange
        ) {
            allInsights.append(elasticityInsight)
        }

        // Feature value insights
        allInsights.append(contentsOf: try await analyzeFeatureValuePerception(dateRange: dateRange))

        // Sort by impact priority
        return allInsights.sorted { lhs, rhs in
            let lhsPriority = impactPriority(lhs.impact)
            let rhsPriority = impactPriority(rhs.impact)
            return lhsPriority > rhsPriority
        }
    }

    // MARK: - Helper Methods

    private func createDropOffInsight(
        stage: String,
        conversionRate: Double,
        recommendations: [String]
    ) -> OptimizationInsight {
        return OptimizationInsight(
            insightType: .conversionDropOff,
            title: "Low Conversion: \(stage)",
            description: "Conversion rate of \(String(format: "%.1f", conversionRate * 100))% is below optimal levels.",
            impact: conversionRate < 0.10 ? .high : .medium,
            recommendations: recommendations,
            dataPoints: [
                "conversion_rate": conversionRate,
                "stage": Double(stage.hash.magnitude)
            ]
        )
    }

    private func calculateElasticities(_ pricePoints: [(price: Double, demand: Double)]) -> [Double] {
        var elasticities: [Double] = []

        for i in 1..<pricePoints.count {
            let p1 = pricePoints[i-1].price
            let p2 = pricePoints[i].price
            let q1 = pricePoints[i-1].demand
            let q2 = pricePoints[i].demand

            if p1 != p2 && q1 != 0 {
                let percentChangeQ = (q2 - q1) / q1
                let percentChangeP = (p2 - p1) / p1
                let elasticity = percentChangeQ / percentChangeP
                elasticities.append(elasticity)
            }
        }

        return elasticities
    }

    private func impactPriority(_ impact: InsightImpact) -> Int {
        switch impact {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - Supporting Models

private struct FeatureMetrics {
    var usageCount: Int = 0
    var gateEncounters: Int = 0
    var conversions: Int = 0
}