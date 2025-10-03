import SwiftUI
import UniformTypeIdentifiers

/// Export functionality for analytics data
@available(iOS 16.0, *)
struct AnalyticsExportView: View {
    let data: AnalyticsData?
    @Environment(\.dismiss) private var dismiss

    @State private var exportFormat: ExportFormat = .csv
    @State private var includeRawData = true
    @State private var includeSummary = true
    @State private var includeCharts = false
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Content") {
                    Toggle("Include Summary", isOn: $includeSummary)
                    Toggle("Include Raw Data", isOn: $includeRawData)

                    if exportFormat == .pdf {
                        Toggle("Include Charts", isOn: $includeCharts)
                    }
                }

                Section("Date Range") {
                    if let data = data {
                        LabeledContent("Period", value: data.timeRange.rawValue)
                        LabeledContent("Child", value: data.childFilter == "all" ? "All Children" : data.childFilter)
                    }
                }

                if let data = data {
                    Section("Preview") {
                        ExportPreviewSection(
                            data: data,
                            format: exportFormat,
                            includeSummary: includeSummary,
                            includeRawData: includeRawData
                        )
                    }
                }
            }
            .navigationTitle("Export Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportData()
                    }
                    .disabled(data == nil || isExporting)
                }
            }
        }
        .overlay {
            if isExporting {
                ProgressView("Exporting...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func exportData() {
        guard let data = data else { return }

        Task {
            await performExport(data: data)
        }
    }

    @MainActor
    private func performExport(data: AnalyticsData) async {
        isExporting = true
        defer { isExporting = false }

        do {
            let exporter = AnalyticsExporter()
            let fileURL = try await exporter.export(
                data: data,
                format: exportFormat,
                options: ExportOptions(
                    includeSummary: includeSummary,
                    includeRawData: includeRawData,
                    includeCharts: includeCharts
                )
            )

            exportedFileURL = fileURL
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case json = "json"
    case pdf = "pdf"

    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF"
        }
    }

    var fileExtension: String {
        return rawValue
    }

    var contentType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        case .pdf: return .pdf
        }
    }
}

// MARK: - Export Options

struct ExportOptions {
    let includeSummary: Bool
    let includeRawData: Bool
    let includeCharts: Bool
}

// MARK: - Export Preview Section

struct ExportPreviewSection: View {
    let data: AnalyticsData
    let format: ExportFormat
    let includeSummary: Bool
    let includeRawData: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export will include:")
                .font(.subheadline)
                .fontWeight(.medium)

            if includeSummary {
                Label("Summary metrics and key insights", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if includeRawData {
                Label("Raw usage data and timestamps", systemImage: "table")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if format == .pdf {
                Label("Formatted report with visualizations", systemImage: "doc.richtext")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Text("Estimated file size:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(estimatedFileSize)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }

    private var estimatedFileSize: String {
        let baseSize = includeSummary ? 50 : 0 // KB
        let dataSize = includeRawData ? data.usageTrends.count * 2 : 0 // KB
        let chartSize = format == .pdf ? 200 : 0 // KB

        let totalKB = baseSize + dataSize + chartSize
        if totalKB < 1024 {
            return "\(totalKB) KB"
        } else {
            return String(format: "%.1f MB", Double(totalKB) / 1024.0)
        }
    }
}

// MARK: - Analytics Exporter

@available(iOS 16.0, *)
class AnalyticsExporter {
    func export(data: AnalyticsData, format: ExportFormat, options: ExportOptions) async throws -> URL {
        let fileName = generateFileName(for: data, format: format)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)

        switch format {
        case .csv:
            try await exportCSV(data: data, to: fileURL, options: options)
        case .json:
            try await exportJSON(data: data, to: fileURL, options: options)
        case .pdf:
            try await exportPDF(data: data, to: fileURL, options: options)
        }

        return fileURL
    }

    private func generateFileName(for data: AnalyticsData, format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let childFilter = data.childFilter == "all" ? "AllChildren" : data.childFilter
        return "ScreenTimeAnalytics_\(childFilter)_\(data.timeRange.rawValue.replacingOccurrences(of: " ", with: ""))_\(dateString).\(format.fileExtension)"
    }

    private func exportCSV(data: AnalyticsData, to url: URL, options: ExportOptions) async throws {
        var csvContent = ""

        if options.includeSummary {
            csvContent += "Summary Metrics\n"
            csvContent += "Metric,Value\n"
            csvContent += "Total Screen Time,\(data.keyMetrics.totalScreenTime) minutes\n"
            csvContent += "Learning Time,\(data.keyMetrics.learningTime) minutes\n"
            csvContent += "Entertainment Time,\(data.keyMetrics.entertainmentTime) minutes\n"
            csvContent += "Points Earned,\(data.keyMetrics.pointsEarned)\n"
            csvContent += "Points Spent,\(data.keyMetrics.pointsSpent)\n"
            csvContent += "Goal Achievement,\(Int(data.keyMetrics.dailyGoalAchievement * 100))%\n\n"
        }

        if options.includeRawData {
            csvContent += "Daily Usage Data\n"
            csvContent += "Date,Screen Time (minutes),Learning Time (minutes),Points Earned\n"

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            for dataPoint in data.usageTrends {
                csvContent += "\(formatter.string(from: dataPoint.date)),\(Int(dataPoint.screenTime)),\(Int(dataPoint.learningTime)),\(dataPoint.pointsEarned)\n"
            }

            csvContent += "\nApp Category Breakdown\n"
            csvContent += "Category,Time Spent (minutes),Points Earned\n"

            for category in data.appCategories {
                csvContent += "\(category.category),\(category.timeSpent),\(category.pointsEarned)\n"
            }
        }

        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }

    private func exportJSON(data: AnalyticsData, to url: URL, options: ExportOptions) async throws {
        var exportData: [String: Any] = [:]

        exportData["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportData["timeRange"] = data.timeRange.rawValue
        exportData["childFilter"] = data.childFilter

        if options.includeSummary {
            exportData["summary"] = [
                "totalScreenTime": data.keyMetrics.totalScreenTime,
                "learningTime": data.keyMetrics.learningTime,
                "entertainmentTime": data.keyMetrics.entertainmentTime,
                "pointsEarned": data.keyMetrics.pointsEarned,
                "pointsSpent": data.keyMetrics.pointsSpent,
                "goalAchievement": data.keyMetrics.dailyGoalAchievement
            ]
        }

        if options.includeRawData {
            let formatter = ISO8601DateFormatter()

            exportData["usageTrends"] = data.usageTrends.map { dataPoint in
                [
                    "date": formatter.string(from: dataPoint.date),
                    "screenTime": dataPoint.screenTime,
                    "learningTime": dataPoint.learningTime,
                    "pointsEarned": dataPoint.pointsEarned
                ]
            }

            exportData["appCategories"] = data.appCategories.map { category in
                [
                    "category": category.category,
                    "timeSpent": category.timeSpent,
                    "pointsEarned": category.pointsEarned
                ]
            }

            exportData["learningProgress"] = data.learningProgress.map { progress in
                [
                    "subject": progress.subject,
                    "timeSpent": progress.timeSpent,
                    "progress": progress.progress
                ]
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: url)
    }

    private func exportPDF(data: AnalyticsData, to url: URL, options: ExportOptions) async throws {
        // PDF generation would require more complex implementation
        // For now, we'll create a simple text-based PDF
        let pdfContent = generatePDFContent(data: data, options: options)
        try pdfContent.write(to: url, atomically: true, encoding: .utf8)
    }

    private func generatePDFContent(data: AnalyticsData, options: ExportOptions) -> String {
        var content = """
        SCREEN TIME ANALYTICS REPORT
        ============================

        Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))
        Time Period: \(data.timeRange.rawValue)
        Child Filter: \(data.childFilter == "all" ? "All Children" : data.childFilter)

        """

        if options.includeSummary {
            content += """

            SUMMARY METRICS
            ===============

            Total Screen Time: \(data.keyMetrics.totalScreenTime) minutes
            Learning Time: \(data.keyMetrics.learningTime) minutes
            Entertainment Time: \(data.keyMetrics.entertainmentTime) minutes
            Points Earned: \(data.keyMetrics.pointsEarned)
            Points Spent: \(data.keyMetrics.pointsSpent)
            Goal Achievement: \(Int(data.keyMetrics.dailyGoalAchievement * 100))%

            """
        }

        if options.includeRawData {
            content += """

            DETAILED DATA
            =============

            App Category Breakdown:
            """

            for category in data.appCategories {
                content += "\n• \(category.category): \(category.timeSpent) minutes"
                if category.pointsEarned > 0 {
                    content += " (\(category.pointsEarned) points earned)"
                }
            }

            content += "\n\nLearning Progress:"
            for progress in data.learningProgress {
                content += "\n• \(progress.subject): \(progress.timeSpent) minutes (\(Int(progress.progress * 100))% complete)"
            }
        }

        return content
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#if DEBUG
@available(iOS 16.0, *)
struct AnalyticsExportView_Previews: PreviewProvider {
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

        AnalyticsExportView(data: mockData)
    }
}
#endif