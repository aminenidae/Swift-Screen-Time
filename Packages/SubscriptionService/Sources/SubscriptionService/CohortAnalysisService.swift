import Foundation
import SharedModels
import RewardCore

/// Service for cohort analysis and user segmentation
public class CohortAnalysisService: @unchecked Sendable {
    private let analyticsRepository: AnalyticsRepository?

    public init(analyticsRepository: AnalyticsRepository? = nil) {
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Trial Cohort Analysis

    /// Creates trial cohorts by start date
    public func createTrialCohorts(
        startDate: Date,
        endDate: Date,
        cohortPeriod: CohortPeriod = .weekly
    ) async throws -> [CohortAnalysis] {
        guard let repository = analyticsRepository else { return [] }

        let events = try await repository.fetchEvents(for: "", dateRange: DateRange(start: startDate, end: endDate))
        let trialEvents = events.filter { event in
            if case .subscriptionEvent(let eventType, _) = event.eventType {
                return eventType == .trialStart
            }
            return false
        }

        return groupEventsByPeriod(trialEvents, period: cohortPeriod)
    }

    /// Analyzes conversion rates by acquisition channel
    public func analyzeConversionByChannel(
        dateRange: DateRange
    ) async throws -> [String: Double] {
        guard let repository = analyticsRepository else { return [:] }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)

        var channelTrials: [String: Int] = [:]
        var channelConversions: [String: Int] = [:]

        for event in events {
            if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
                let channel = metadata["acquisition_channel"] ?? "organic"

                switch eventType {
                case .trialStart:
                    channelTrials[channel, default: 0] += 1
                case .purchase:
                    channelConversions[channel, default: 0] += 1
                default:
                    break
                }
            }
        }

        var conversionRates: [String: Double] = [:]
        for (channel, trials) in channelTrials {
            let conversions = channelConversions[channel] ?? 0
            if trials > 0 {
                conversionRates[channel] = Double(conversions) / Double(trials)
            }
        }

        return conversionRates
    }

    /// Analyzes retention by subscription tier
    public func analyzeRetentionByTier(
        dateRange: DateRange
    ) async throws -> [String: [String: Double]] {
        guard let repository = analyticsRepository else { return [:] }

        let events = try await repository.fetchEvents(for: "", dateRange: dateRange)

        var tierSubscriptions: [String: Set<String>] = [:]
        var tierRetained: [String: [String: Set<String>]] = [:]

        // Group events by tier and track retention periods
        for event in events {
            if case .subscriptionEvent(let eventType, let metadata) = event.eventType {
                let tier = metadata["tier"] ?? "unknown"
                let userID = event.anonymizedUserID

                switch eventType {
                case .purchase, .renewal:
                    tierSubscriptions[tier, default: Set()].insert(userID)

                    // Calculate retention periods
                    let daysSinceStart = Calendar.current.dateComponents([.day], from: dateRange.start, to: event.timestamp).day ?? 0

                    if daysSinceStart >= 1 {
                        if tierRetained[tier] == nil {
                            tierRetained[tier] = [:]
                        }
                        tierRetained[tier]!["day_1", default: Set()].insert(userID)
                    }
                    if daysSinceStart >= 7 {
                        if tierRetained[tier] == nil {
                            tierRetained[tier] = [:]
                        }
                        tierRetained[tier]!["day_7", default: Set()].insert(userID)
                    }
                    if daysSinceStart >= 30 {
                        if tierRetained[tier] == nil {
                            tierRetained[tier] = [:]
                        }
                        tierRetained[tier]!["day_30", default: Set()].insert(userID)
                    }
                default:
                    break
                }
            }
        }

        // Calculate retention rates
        var retentionRates: [String: [String: Double]] = [:]
        for (tier, totalUsers) in tierSubscriptions {
            retentionRates[tier] = [:]
            let total = Double(totalUsers.count)

            if let retainedUsers = tierRetained[tier] {
                for (period, users) in retainedUsers {
                    if total > 0 {
                        retentionRates[tier]?[period] = Double(users.count) / total
                    }
                }
            }
        }

        return retentionRates
    }

    /// Creates comprehensive cohort analysis
    public func generateCohortAnalysis(
        startDate: Date,
        endDate: Date,
        cohortPeriod: CohortPeriod = .weekly
    ) async throws -> [CohortAnalysis] {
        let conversionByChannel = try await analyzeConversionByChannel(
            dateRange: DateRange(start: startDate, end: endDate)
        )
        let retentionByTier = try await analyzeRetentionByTier(
            dateRange: DateRange(start: startDate, end: endDate)
        )

        guard let repository = analyticsRepository else { return [] }
        let events = try await repository.fetchEvents(for: "", dateRange: DateRange(start: startDate, end: endDate))

        let cohorts = groupEventsByPeriod(events, period: cohortPeriod)
        return cohorts.map { cohort in
            CohortAnalysis(
                cohortStartDate: cohort.cohortStartDate,
                cohortSize: cohort.cohortSize,
                conversionRateByChannel: conversionByChannel,
                retentionByTier: retentionByTier,
                acquisitionChannel: cohort.acquisitionChannel
            )
        }
    }

    // MARK: - Helper Methods

    private func groupEventsByPeriod(
        _ events: [AnalyticsEvent],
        period: CohortPeriod
    ) -> [CohortAnalysis] {
        let calendar = Calendar.current
        var cohorts: [Date: [AnalyticsEvent]] = [:]

        for event in events {
            let cohortStart: Date

            switch period {
            case .daily:
                cohortStart = calendar.startOfDay(for: event.timestamp)
            case .weekly:
                let weekOfYear = calendar.component(.weekOfYear, from: event.timestamp)
                let year = calendar.component(.year, from: event.timestamp)
                cohortStart = calendar.date(from: DateComponents(year: year, weekOfYear: weekOfYear)) ?? event.timestamp
            case .monthly:
                let month = calendar.component(.month, from: event.timestamp)
                let year = calendar.component(.year, from: event.timestamp)
                cohortStart = calendar.date(from: DateComponents(year: year, month: month)) ?? event.timestamp
            }

            cohorts[cohortStart, default: []].append(event)
        }

        return cohorts.map { (startDate, events) in
            let uniqueUsers = Set(events.map { $0.anonymizedUserID })
            let acquisitionChannels = events.compactMap { event -> String? in
                if case .subscriptionEvent(_, let metadata) = event.eventType {
                    return metadata["acquisition_channel"]
                }
                return nil
            }
            let primaryChannel = acquisitionChannels.max { a, b in
                acquisitionChannels.filter { $0 == a }.count < acquisitionChannels.filter { $0 == b }.count
            }

            return CohortAnalysis(
                cohortStartDate: startDate,
                cohortSize: uniqueUsers.count,
                conversionRateByChannel: [:], // Will be filled by the calling method
                retentionByTier: [:], // Will be filled by the calling method
                acquisitionChannel: primaryChannel
            )
        }.sorted { $0.cohortStartDate < $1.cohortStartDate }
    }
}

// MARK: - Cohort Period

public enum CohortPeriod: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}