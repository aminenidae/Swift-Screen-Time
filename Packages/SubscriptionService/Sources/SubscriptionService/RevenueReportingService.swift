import Foundation
import SharedModels
import StoreKit
import RewardCore

/// Service for revenue reporting and tracking
public class RevenueReportingService: @unchecked Sendable {
    private let analyticsRepository: AnalyticsRepository?
    private let transactionRepository: TransactionRepository?

    public init(
        analyticsRepository: AnalyticsRepository? = nil,
        transactionRepository: TransactionRepository? = nil
    ) {
        self.analyticsRepository = analyticsRepository
        self.transactionRepository = transactionRepository
    }

    // MARK: - Revenue Report Generation

    /// Generates daily revenue reports
    public func generateDailyReport(for date: Date) async throws -> RevenueReport {
        let dateRange = DateRange.singleDay(date)
        return try await generateReport(
            reportType: .daily,
            dateRange: dateRange
        )
    }

    /// Generates weekly revenue reports
    public func generateWeeklyReport(for weekStartDate: Date) async throws -> RevenueReport {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        let dateRange = DateRange(start: weekStartDate, end: weekEnd)

        return try await generateReport(
            reportType: .weekly,
            dateRange: dateRange
        )
    }

    /// Generates monthly revenue reports
    public func generateMonthlyReport(for month: Int, year: Int) async throws -> RevenueReport {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? Date()
        let dateRange = DateRange(start: startDate, end: endDate)

        return try await generateReport(
            reportType: .monthly,
            dateRange: dateRange
        )
    }

    /// Generates comprehensive revenue report
    private func generateReport(
        reportType: ReportType,
        dateRange: DateRange
    ) async throws -> RevenueReport {
        let revenueData = try await collectRevenueData(for: dateRange)
        let refundData = try await collectRefundData(for: dateRange)

        let totalRevenue = revenueData.values.reduce(0, +)
        let totalRefunds = refundData.values.reduce(0, +)
        let netRevenue = totalRevenue - totalRefunds

        return RevenueReport(
            reportType: reportType,
            startDate: dateRange.start,
            endDate: dateRange.end,
            totalRevenue: totalRevenue,
            revenueByTier: revenueData,
            refunds: totalRefunds,
            netRevenue: netRevenue
        )
    }

    // MARK: - Revenue by Subscription Tier

    /// Calculates revenue by subscription tier
    public func calculateRevenueByTier(
        dateRange: DateRange
    ) async throws -> [String: Double] {
        return try await collectRevenueData(for: dateRange)
    }

    private func collectRevenueData(for dateRange: DateRange) async throws -> [String: Double] {
        guard let repository = analyticsRepository else {
            throw RevenueReportingError.repositoryNotAvailable
        }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        var revenueByTier: [String: Double] = [:]

        for event in events {
            if case .subscriptionEvent(let eventType, let metadata) = event.eventType,
               (eventType == .purchase || eventType == .renewal),
               let tier = metadata["tier"],
               let priceString = metadata["price"],
               let price = Double(priceString) {
                revenueByTier[tier, default: 0.0] += price
            }
        }

        return revenueByTier
    }

    // MARK: - Refund Tracking

    /// Tracks refund events
    public func trackRefund(
        familyID: String,
        productID: String,
        refundAmount: Decimal,
        currency: String,
        tier: String,
        reason: RefundReason
    ) async {
        let metadata = [
            "product_id": productID,
            "refund_amount": refundAmount.description,
            "currency": currency,
            "tier": tier,
            "reason": reason.rawValue
        ]

        let event = AnalyticsEvent(
            eventType: .subscriptionEvent(
                eventType: .cancellation,
                metadata: metadata
            ),
            anonymizedUserID: anonymizeID(familyID),
            sessionID: UUID().uuidString,
            appVersion: getAppVersion(),
            osVersion: getOSVersion(),
            deviceModel: getDeviceModel(),
            metadata: metadata
        )

        try? await analyticsRepository?.saveEvent(event)
    }

    /// Collects refund data for a date range
    private func collectRefundData(for dateRange: DateRange) async throws -> [String: Double] {
        guard let repository = analyticsRepository else {
            throw RevenueReportingError.repositoryNotAvailable
        }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)
        var refundsByTier: [String: Double] = [:]

        for event in events {
            if case .subscriptionEvent(let eventType, let metadata) = event.eventType,
               eventType == .cancellation,
               let tier = metadata["tier"],
               let refundAmountString = metadata["refund_amount"],
               let refundAmount = Double(refundAmountString) {
                refundsByTier[tier, default: 0.0] += refundAmount
            }
        }

        return refundsByTier
    }

    // MARK: - Net Revenue Calculations

    /// Calculates net revenue (total revenue - refunds - chargebacks)
    public func calculateNetRevenue(dateRange: DateRange) async throws -> Double {
        let totalRevenue = try await calculateTotalRevenue(dateRange: dateRange)
        let totalRefunds = try await calculateTotalRefunds(dateRange: dateRange)
        let chargebacks = try await calculateChargebacks(dateRange: dateRange)

        return totalRevenue - totalRefunds - chargebacks
    }

    /// Calculates total revenue for a date range
    public func calculateTotalRevenue(dateRange: DateRange) async throws -> Double {
        let revenueByTier = try await collectRevenueData(for: dateRange)
        return revenueByTier.values.reduce(0, +)
    }

    /// Calculates total refunds for a date range
    public func calculateTotalRefunds(dateRange: DateRange) async throws -> Double {
        let refundsByTier = try await collectRefundData(for: dateRange)
        return refundsByTier.values.reduce(0, +)
    }

    /// Calculates chargebacks for a date range
    public func calculateChargebacks(dateRange: DateRange) async throws -> Double {
        // In a real implementation, this would track chargeback events
        // For now, we'll return 0 as chargebacks would be tracked separately
        return 0.0
    }

    // MARK: - Revenue Trends

    /// Calculates revenue growth rate
    public func calculateRevenueGrowthRate(
        currentPeriod: DateRange,
        previousPeriod: DateRange
    ) async throws -> Double {
        let currentRevenue = try await calculateTotalRevenue(dateRange: currentPeriod)
        let previousRevenue = try await calculateTotalRevenue(dateRange: previousPeriod)

        if previousRevenue > 0 {
            return ((currentRevenue - previousRevenue) / previousRevenue) * 100
        }

        return 0.0
    }

    /// Generates revenue trend analysis
    public func generateRevenueTrends(
        periods: [DateRange]
    ) async throws -> RevenueTrendAnalysis {
        var trends: [RevenueTrendPoint] = []

        for period in periods {
            let revenue = try await calculateTotalRevenue(dateRange: period)
            let netRevenue = try await calculateNetRevenue(dateRange: period)

            trends.append(RevenueTrendPoint(
                period: period,
                totalRevenue: revenue,
                netRevenue: netRevenue
            ))
        }

        return RevenueTrendAnalysis(trends: trends)
    }

    // MARK: - Revenue Forecasting

    /// Generates basic revenue forecast based on trends
    public func generateRevenueForecast(
        historicalPeriods: [DateRange],
        forecastPeriods: Int
    ) async throws -> RevenueForecast {
        let trends = try await generateRevenueTrends(periods: historicalPeriods)

        // Simple linear trend forecasting
        let revenueValues = trends.trends.map { $0.totalRevenue }
        let averageGrowth = calculateAverageGrowthRate(revenueValues)

        var forecastPoints: [RevenueForecastPoint] = []
        let lastRevenue = revenueValues.last ?? 0.0

        for i in 1...forecastPeriods {
            let forecastRevenue = lastRevenue * pow(1 + averageGrowth, Double(i))
            forecastPoints.append(RevenueForecastPoint(
                periodIndex: i,
                forecastRevenue: forecastRevenue,
                confidence: max(0.5, 1.0 - (Double(i) * 0.1)) // Decreasing confidence
            ))
        }

        return RevenueForecast(
            forecastPoints: forecastPoints,
            methodology: "Linear trend with average growth rate"
        )
    }

    // MARK: - Helper Methods

    private func calculateAverageGrowthRate(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }

        var growthRates: [Double] = []
        for i in 1..<values.count {
            if values[i-1] > 0 {
                let growthRate = (values[i] - values[i-1]) / values[i-1]
                growthRates.append(growthRate)
            }
        }

        if growthRates.isEmpty {
            return 0.0
        }

        return growthRates.reduce(0, +) / Double(growthRates.count)
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

public struct RevenueTrendPoint: Codable, Equatable {
    public let period: DateRange
    public let totalRevenue: Double
    public let netRevenue: Double

    public init(
        period: DateRange,
        totalRevenue: Double,
        netRevenue: Double
    ) {
        self.period = period
        self.totalRevenue = totalRevenue
        self.netRevenue = netRevenue
    }
}

public struct RevenueTrendAnalysis: Codable, Equatable {
    public let trends: [RevenueTrendPoint]

    public init(trends: [RevenueTrendPoint]) {
        self.trends = trends
    }
}

public struct RevenueForecastPoint: Codable, Equatable {
    public let periodIndex: Int
    public let forecastRevenue: Double
    public let confidence: Double

    public init(
        periodIndex: Int,
        forecastRevenue: Double,
        confidence: Double
    ) {
        self.periodIndex = periodIndex
        self.forecastRevenue = forecastRevenue
        self.confidence = confidence
    }
}

public struct RevenueForecast: Codable, Equatable {
    public let forecastPoints: [RevenueForecastPoint]
    public let methodology: String

    public init(
        forecastPoints: [RevenueForecastPoint],
        methodology: String
    ) {
        self.forecastPoints = forecastPoints
        self.methodology = methodology
    }
}

public enum RefundReason: String, Codable, CaseIterable {
    case userRequest = "user_request"
    case technicalIssue = "technical_issue"
    case billingError = "billing_error"
    case fraudulent = "fraudulent"
    case duplicateCharge = "duplicate_charge"
    case dissatisfaction = "dissatisfaction"
}

// MARK: - Extensions

extension DateRange {
    public static func singleDay(_ date: Date) -> DateRange {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        return DateRange(start: startOfDay, end: endOfDay)
    }
}

// MARK: - Repository Protocol

public protocol TransactionRepository: Sendable {
    func saveTransaction(_ transaction: RevenueTransaction) async throws
    func fetchTransactions(dateRange: DateRange) async throws -> [RevenueTransaction]
}

public struct RevenueTransaction: Codable, Equatable, Identifiable {
    public let id: UUID
    public let familyID: String
    public let productID: String
    public let amount: Decimal
    public let currency: String
    public let tier: String
    public let transactionDate: Date
    public let transactionType: TransactionType

    public init(
        id: UUID = UUID(),
        familyID: String,
        productID: String,
        amount: Decimal,
        currency: String,
        tier: String,
        transactionDate: Date,
        transactionType: TransactionType
    ) {
        self.id = id
        self.familyID = familyID
        self.productID = productID
        self.amount = amount
        self.currency = currency
        self.tier = tier
        self.transactionDate = transactionDate
        self.transactionType = transactionType
    }
}

public enum TransactionType: String, Codable, CaseIterable {
    case purchase = "purchase"
    case renewal = "renewal"
    case refund = "refund"
    case chargeback = "chargeback"
}

// MARK: - Errors

public enum RevenueReportingError: Error, LocalizedError {
    case repositoryNotAvailable
    case invalidDateRange
    case dataNotAvailable

    public var errorDescription: String? {
        switch self {
        case .repositoryNotAvailable:
            return "Analytics repository is not available"
        case .invalidDateRange:
            return "Invalid date range provided"
        case .dataNotAvailable:
            return "Revenue data is not available for the specified period"
        }
    }
}