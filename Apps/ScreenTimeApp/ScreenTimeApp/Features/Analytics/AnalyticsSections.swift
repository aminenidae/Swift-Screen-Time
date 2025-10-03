import SwiftUI
import Charts

/// Key metrics overview section
@available(iOS 16.0, *)
struct KeyMetricsSection: View {
    let data: AnalyticsData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Overview", icon: "chart.bar.fill")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Total Screen Time",
                    value: formatMinutes(data.keyMetrics.totalScreenTime),
                    icon: "clock.fill",
                    color: .blue
                )

                MetricCard(
                    title: "Learning Time",
                    value: formatMinutes(data.keyMetrics.learningTime),
                    icon: "graduationcap.fill",
                    color: .green
                )

                MetricCard(
                    title: "Points Earned",
                    value: "\(data.keyMetrics.pointsEarned)",
                    icon: "star.fill",
                    color: .yellow
                )

                MetricCard(
                    title: "Goal Achievement",
                    value: "\(Int(data.keyMetrics.dailyGoalAchievement * 100))%",
                    icon: "target",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
}

/// Usage trends chart section
@available(iOS 16.0, *)
struct UsageTrendsSection: View {
    let data: AnalyticsData
    let timeRange: TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Usage Trends", icon: "chart.line.uptrend.xyaxis")

            Chart(data.usageTrends) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Screen Time", dataPoint.screenTime)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)

                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Learning Time", dataPoint.learningTime)
                )
                .foregroundStyle(.green)
                .symbol(.square)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatDate(date))
                        }
                    }
                }
            }
            .chartLegend {
                HStack(spacing: 20) {
                    Label("Screen Time", systemImage: "circle.fill")
                        .foregroundColor(.blue)
                    Label("Learning Time", systemImage: "square.fill")
                        .foregroundColor(.green)
                }
                .font(.caption)
            }
        }
        .padding(.horizontal)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

/// App category breakdown section
@available(iOS 16.0, *)
struct AppCategorySection: View {
    let data: AnalyticsData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "App Categories", icon: "square.grid.2x2.fill")

            Chart(data.appCategories) { category in
                BarMark(
                    x: .value("Category", category.category),
                    y: .value("Time", category.timeSpent)
                )
                .foregroundStyle(colorForCategory(category.category))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let minutes = value.as(Int.self) {
                            Text("\(minutes)m")
                        }
                    }
                }
            }

            // Category details list
            ForEach(data.appCategories) { category in
                HStack {
                    Circle()
                        .fill(colorForCategory(category.category))
                        .frame(width: 12, height: 12)

                    Text(category.category)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(category.timeSpent) min")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if category.pointsEarned > 0 {
                            Text("\(category.pointsEarned) pts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Educational": return .green
        case "Entertainment": return .blue
        case "Social": return .purple
        case "Games": return .orange
        default: return .gray
        }
    }
}

/// Learning progress section
@available(iOS 16.0, *)
struct LearningProgressSection: View {
    let data: AnalyticsData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Learning Progress", icon: "graduationcap.fill")

            ForEach(data.learningProgress) { progress in
                VStack(spacing: 8) {
                    HStack {
                        Text(progress.subject)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text("\(progress.timeSpent) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: progress.progress) {
                        HStack {
                            Text("\(Int(progress.progress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .tint(.green)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal)
    }
}

/// Screen time goals section
@available(iOS 16.0, *)
struct ScreenTimeGoalsSection: View {
    let data: AnalyticsData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Daily Goals", icon: "target")

            Chart(data.screenTimeGoals) { goal in
                BarMark(
                    x: .value("Day", goal.day),
                    y: .value("Goal", goal.goal)
                )
                .foregroundStyle(.gray.opacity(0.3))

                BarMark(
                    x: .value("Day", goal.day),
                    y: .value("Actual", min(goal.actual, goal.goal))
                )
                .foregroundStyle(goal.actual <= goal.goal ? .green : .red)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let minutes = value.as(Int.self) {
                            Text("\(minutes)m")
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Reward statistics section
@available(iOS 16.0, *)
struct RewardStatisticsSection: View {
    let data: AnalyticsData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Rewards", icon: "gift.fill")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Points Balance",
                    value: "\(data.rewardStatistics.totalPointsEarned - data.rewardStatistics.totalPointsSpent)",
                    subtitle: "Available"
                )

                StatCard(
                    title: "Current Streak",
                    value: "\(data.rewardStatistics.streakDays)",
                    subtitle: "Days"
                )

                StatCard(
                    title: "Most Redeemed",
                    value: data.rewardStatistics.mostRedeemed,
                    subtitle: "This month"
                )

                StatCard(
                    title: "Goal Rate",
                    value: "\(Int(data.rewardStatistics.goalAchievementRate * 100))%",
                    subtitle: "Achievement"
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct AnalyticsSections_Previews: PreviewProvider {
    static var previews: some View {
        let mockData = AnalyticsData(
            timeRange: .week,
            childFilter: "all",
            keyMetrics: KeyMetrics(
                totalScreenTime: 420,
                learningTime: 180,
                entertainmentTime: 240,
                pointsEarned: 450,
                pointsSpent: 320,
                dailyGoalAchievement: 0.85
            ),
            usageTrends: [],
            appCategories: [],
            learningProgress: [],
            screenTimeGoals: [],
            rewardStatistics: RewardStatistics(
                totalPointsEarned: 450,
                totalPointsSpent: 320,
                averagePointsPerDay: 64,
                mostRedeemed: "Netflix",
                streakDays: 5,
                goalAchievementRate: 0.85
            )
        )

        ScrollView {
            VStack(spacing: 24) {
                KeyMetricsSection(data: mockData)
                RewardStatisticsSection(data: mockData)
            }
        }
    }
}
#endif