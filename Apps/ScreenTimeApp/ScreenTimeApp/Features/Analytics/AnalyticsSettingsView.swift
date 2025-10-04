import SwiftUI
import RewardCore
import SharedModels

/// Settings view for analytics preferences and privacy controls
@available(iOS 16.0, *)
struct AnalyticsSettingsView: View {
    @StateObject private var consentService = AnalyticsConsentService()
    @State private var consentLevel: AnalyticsConsentLevel = .standard
    @State private var dataRetentionDays: Int = 90
    @State private var shareWithFamily = true
    @State private var includeInReports = true
    @State private var showDataDeletionAlert = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy & Consent") {
                    Picker("Data Collection Level", selection: $consentLevel) {
                        ForEach(AnalyticsConsentLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }.tag(level)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: consentLevel) { newLevel in
                        updateConsentLevel(newLevel)
                    }

                    ConsentLevelDescription(level: consentLevel)
                }

                Section("Data Management") {
                    Picker("Data Retention", selection: $dataRetentionDays) {
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("1 year").tag(365)
                        Text("2 years").tag(730)
                    }

                    Toggle("Share with Family Members", isOn: $shareWithFamily)
                    Toggle("Include in Family Reports", isOn: $includeInReports)
                }

                Section("Export & Backup") {
                    NavigationLink("Export My Data") {
                        DataExportView()
                    }

                    NavigationLink("Data Summary") {
                        PersonalDataSummaryView()
                    }
                }

                Section("Advanced") {
                    Button("Delete All Analytics Data", role: .destructive) {
                        showDataDeletionAlert = true
                    }
                    .foregroundColor(.red)

                    NavigationLink("Technical Details") {
                        AnalyticsTechnicalDetailsView()
                    }
                }

                Section("Information") {
                    NavigationLink("Privacy Policy") {
                        AnalyticsPrivacyPolicyView()
                    }

                    NavigationLink("How We Use Analytics") {
                        AnalyticsInfoView()
                    }
                }
            }
            .navigationTitle("Analytics Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadCurrentSettings()
            }
            .alert("Delete Analytics Data", isPresented: $showDataDeletionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your analytics data. This action cannot be undone.")
            }
            .overlay {
                if isLoading {
                    ProgressView("Updating settings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }

    private func loadCurrentSettings() async {
        isLoading = true
        defer { isLoading = false }

        // Load current consent level and settings
        // In a real implementation, this would fetch from AnalyticsConsentService
        consentLevel = .standard
        dataRetentionDays = 90
        shareWithFamily = true
        includeInReports = true
    }

    private func updateConsentLevel(_ level: AnalyticsConsentLevel) {
        Task {
            isLoading = true
            defer { isLoading = false }

            // Update consent level through service
            // In a real implementation, this would call consentService.updateConsent()
            print("Updated consent level to: \(level)")
        }
    }

    private func deleteAllData() {
        Task {
            isLoading = true
            defer { isLoading = false }

            // Delete all analytics data
            // In a real implementation, this would call the analytics service
            print("Deleted all analytics data")
        }
    }
}

// MARK: - Consent Level Extensions

extension AnalyticsConsentLevel {
    var displayName: String {
        switch self {
        case .none: return "No Analytics"
        case .essential: return "Essential Only"
        case .standard: return "Standard"
        case .detailed: return "Detailed"
        }
    }

    var description: String {
        switch self {
        case .none: return "No data collection"
        case .essential: return "Crash reports and critical metrics only"
        case .standard: return "Feature usage and performance"
        case .detailed: return "Comprehensive analytics for insights"
        }
    }
}

// MARK: - Consent Level Description

struct ConsentLevelDescription: View {
    let level: AnalyticsConsentLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What this includes:")
                .font(.subheadline)
                .fontWeight(.medium)

            ForEach(dataTypesForLevel(level), id: \.self) { dataType in
                Label(dataType, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            if level != .detailed {
                Text("Not included:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 8)

                ForEach(excludedDataTypesForLevel(level), id: \.self) { dataType in
                    Label(dataType, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func dataTypesForLevel(_ level: AnalyticsConsentLevel) -> [String] {
        switch level {
        case .none:
            return []
        case .essential:
            return ["Crash reports", "Critical errors", "Performance metrics"]
        case .standard:
            return ["Feature usage", "App performance", "Basic usage patterns", "Crash reports"]
        case .detailed:
            return ["Detailed usage analytics", "Feature engagement", "User flows", "Performance data", "Anonymized behavioral patterns"]
        }
    }

    private func excludedDataTypesForLevel(_ level: AnalyticsConsentLevel) -> [String] {
        switch level {
        case .none:
            return ["All analytics data"]
        case .essential:
            return ["Feature usage tracking", "Detailed behavioral data", "Usage patterns"]
        case .standard:
            return ["Detailed behavioral patterns", "Advanced user journey tracking"]
        case .detailed:
            return []
        }
    }
}

// MARK: - Supporting Views

struct DataExportView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Export Your Data")
                .font(.title2)
                .fontWeight(.bold)

            Text("Download a copy of all your analytics data in JSON format.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Export Data") {
                // Implement data export
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonalDataSummaryView: View {
    var body: some View {
        Form {
            Section("Data Overview") {
                LabeledContent("Analytics Events", value: "1,247")
                LabeledContent("Data Points", value: "3,891")
                LabeledContent("Storage Used", value: "2.3 MB")
                LabeledContent("Oldest Data", value: "3 months ago")
            }

            Section("Data Types") {
                LabeledContent("Usage Sessions", value: "156")
                LabeledContent("Feature Interactions", value: "892")
                LabeledContent("Performance Metrics", value: "234")
                LabeledContent("Error Reports", value: "12")
            }
        }
        .navigationTitle("Data Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnalyticsTechnicalDetailsView: View {
    var body: some View {
        Form {
            Section("Data Processing") {
                LabeledContent("Anonymization", value: "SHA-256 hashing")
                LabeledContent("Encryption", value: "AES-256")
                LabeledContent("Retention Policy", value: "90 days default")
                LabeledContent("Data Location", value: "iCloud Private")
            }

            Section("Collection Methods") {
                LabeledContent("Event Tracking", value: "Local processing")
                LabeledContent("Aggregation", value: "Privacy-preserving")
                LabeledContent("Consent Management", value: "Granular controls")
                LabeledContent("Data Minimization", value: "Enabled")
            }

            Section("Third-Party Sharing") {
                LabeledContent("Analytics Providers", value: "None")
                LabeledContent("Advertising Networks", value: "None")
                LabeledContent("Data Brokers", value: "None")
                LabeledContent("Family Sharing", value: "Opt-in only")
            }
        }
        .navigationTitle("Technical Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnalyticsPrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your privacy is important to us. This section explains how we collect, use, and protect your analytics data.")
                    .font(.body)

                Group {
                    Text("Data Collection")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("We collect analytics data to improve the app experience and provide insights into your family's screen time usage. All data is processed locally and anonymized before any aggregation.")

                    Text("Data Usage")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Analytics data is used exclusively to generate usage reports and improve app functionality. We never share personal data with third parties.")

                    Text("Data Security")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("All data is encrypted and stored securely. You have full control over your data and can export or delete it at any time.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnalyticsInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                InfoSection(
                    title: "How Analytics Help",
                    description: "Analytics data helps us understand how families use screen time features, allowing us to improve the app and provide better insights.",
                    icon: "chart.bar.fill"
                )

                InfoSection(
                    title: "Privacy-First Design",
                    description: "All data is anonymized and processed locally. We use privacy-preserving techniques to generate insights without compromising your family's privacy.",
                    icon: "shield.fill"
                )

                InfoSection(
                    title: "Your Control",
                    description: "You have complete control over what data is collected. You can adjust settings, export your data, or delete everything at any time.",
                    icon: "hand.raised.fill"
                )

                InfoSection(
                    title: "Transparency",
                    description: "We believe in full transparency about our data practices. All analytics methods and data usage are clearly documented and explained.",
                    icon: "eye.fill"
                )
            }
            .padding()
        }
        .navigationTitle("Analytics Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoSection: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
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
struct AnalyticsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsSettingsView()
    }
}
#endif