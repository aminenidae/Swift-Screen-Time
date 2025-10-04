import SwiftUI

/// View for managing app-wide preferences
struct SettingsPreferencesView: View {
    @ObservedObject private var settingsService = SettingsService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Form {
            // Appearance Section
            Section {
                Toggle("Dark Mode", isOn: $settingsService.isDarkModeEnabled)
                
                Picker("App Icon", selection: .constant(0)) {
                    Text("Default").tag(0)
                    Text("Blue").tag(1)
                    Text("Green").tag(2)
                }
            } header: {
                Text("Appearance")
            }
            
            // Notifications Section
            Section {
                Toggle("Daily Summary", isOn: .constant(true))
                Toggle("Achievement Notifications", isOn: .constant(true))
                Toggle("Reminder Notifications", isOn: .constant(true))
                
                NavigationLink(destination: NotificationSettingsDetailView()) {
                    Text("Notification Settings")
                }
            } header: {
                Text("Notifications")
            }
            
            // Privacy Section
            Section {
                Toggle("Share Usage Data", isOn: .constant(false))
                Toggle("Analytics", isOn: .constant(false))
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    Text("Privacy Policy")
                }
            } header: {
                Text("Privacy")
            }
            
            // Data Section
            Section {
                Button("Export Data") {
                    // Handle data export
                }
                
                Button("Import Data") {
                    // Handle data import
                }
                
                Button("Reset All Settings", role: .destructive) {
                    // Show confirmation dialog
                }
            } header: {
                Text("Data Management")
            }
            
            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink(destination: Text("Acknowledgements")) {
                    Text("Acknowledgements")
                }
                
                NavigationLink(destination: Text("Licenses")) {
                    Text("Open Source Licenses")
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Preferences")
        .onDisappear {
            settingsService.saveSettings()
        }
    }
}

/// Detail view for notification settings
struct NotificationSettingsDetailView: View {
    @State private var dailySummaryEnabled = true
    @State private var achievementNotificationsEnabled = true
    @State private var reminderNotificationsEnabled = true
    @State private var dailySummaryTime = Date()
    
    var body: some View {
        Form {
            Section {
                Toggle("Daily Summary", isOn: $dailySummaryEnabled)
                
                if dailySummaryEnabled {
                    DatePicker("Time", selection: $dailySummaryTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            } header: {
                Text("Daily Summary")
            }
            
            Section {
                Toggle("Achievement Notifications", isOn: $achievementNotificationsEnabled)
            } header: {
                Text("Achievements")
            }
            
            Section {
                Toggle("Reminder Notifications", isOn: $reminderNotificationsEnabled)
            } header: {
                Text("Reminders")
            }
        }
        .navigationTitle("Notifications")
    }
}

/// View for privacy policy
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: October 3, 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("""
                ScreenTime Rewards is committed to protecting your privacy. This privacy policy explains how we collect, use, and protect your information.
                
                Information We Collect:
                - Family Sharing information to identify family members
                - Usage data to track educational app usage
                - Point transactions for reward management
                
                How We Use Your Information:
                - To provide and improve our service
                - To track your children's educational progress
                - To manage reward systems
                
                Data Protection:
                - All data is stored locally on your device
                - No personal information is shared with third parties
                - Family Sharing data is only used within the app
                
                Your Rights:
                - You can delete all data at any time through the app settings
                - You can opt out of data collection in the privacy settings
                """)
                .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    NavigationStack {
        SettingsPreferencesView()
    }
}