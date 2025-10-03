import SwiftUI
import FamilyControlsKit

/// Main parent settings view with general and child-specific configurations
struct ParentSettingsView: View {
    @State private var selectedChild: FamilyMemberInfo?
    @StateObject private var familyMemberService = FamilyMemberService()

    var body: some View {
        NavigationStack {
            List {
                // General App Settings
                Section("General Settings") {
                    NavigationLink(destination: FamilySetupView()) {
                        Label("Family Setup", systemImage: "house.fill")
                    }

                    NavigationLink(destination: FamilyControlsSetupView()) {
                        Label("Family Controls", systemImage: "shield.fill")
                    }

                    NavigationLink(destination: FamilyMembersView()) {
                        Label("Family Members", systemImage: "person.2.fill")
                    }

                    NavigationLink(destination: SubscriptionView()) {
                        Label("Subscription", systemImage: "star.fill")
                    }
                }

                // Child-Related Settings
                if !familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    Section("Child Settings") {
                        NavigationLink(destination: ChildSpecificLearningAppView()) {
                            Label("Learning App Settings", systemImage: "graduationcap.fill")
                        }

                        NavigationLink(destination: ChildSpecificActivityView()) {
                            Label("Activity Settings", systemImage: "gift.fill")
                        }

                        NavigationLink(destination: ChildSpecificRewardAppView()) {
                            Label("Reward App Settings", systemImage: "iphone")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .timeLimits
                        )) {
                            Label("Daily Time Limits", systemImage: "clock.fill")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .bedtime
                        )) {
                            Label("Bedtime Settings", systemImage: "moon.fill")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .reports
                        )) {
                            Label("Detailed Reports", systemImage: "chart.bar.fill")
                        }

                        NavigationLink(destination: ChildSelectionView(
                            onChildSelected: { child in
                                selectedChild = child
                            },
                            destinationType: .trends
                        )) {
                            Label("Usage Trends", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }
                } else {
                    Section("Child Settings") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.slash")
                                    .foregroundColor(.orange)
                                Text("No children found in Family Sharing")
                                    .foregroundColor(.secondary)
                            }

                            NavigationLink(destination: FamilySetupView()) {
                                Text("Set up Family Sharing →")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Account") {
                    Button(action: {
                        // Switch to child profile
                        UserDefaults.standard.set("child", forKey: "userRole")
                    }) {
                        Label("Switch to Child Profile", systemImage: "person.fill")
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        // Reset onboarding
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    }) {
                        Label("Reset App", systemImage: "arrow.clockwise")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }
}

// Forward declarations for views that will be modularized later
struct FamilyControlsSetupView: View {
    var body: some View {
        Text("Family Controls Setup View - To be modularized")
    }
}

struct FamilyMembersView: View {
    var body: some View {
        Text("Family Members View - To be modularized")
    }
}

struct SubscriptionView: View {
    var body: some View {
        SubscriptionManagementView()
    }
}

struct ChildSpecificLearningAppView: View {
    var body: some View {
        Text("Child Specific Learning App View - To be modularized")
    }
}

struct ChildSpecificActivityView: View {
    var body: some View {
        Text("Child Specific Activity View - To be modularized")
    }
}

struct ChildSpecificRewardAppView: View {
    var body: some View {
        Text("Child Specific Reward App View - To be modularized")
    }
}

struct TimeLimitsView: View {
    var body: some View {
        Text("Time Limits View - To be modularized")
    }
}

struct BedtimeSettingsView: View {
    var body: some View {
        Text("Bedtime Settings View - To be modularized")
    }
}

struct ReportsView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            AnalyticsDashboardView()
        } else {
            Text("Analytics requires iOS 16.0 or later")
                .foregroundColor(.secondary)
        }
    }
}

struct UsageTrendsView: View {
    var body: some View {
        Text("Usage Trends View - To be modularized")
    }
}

struct LearningAppRewardsView: View {
    var body: some View {
        Text("Learning App Rewards View - To be modularized")
    }
}

struct RewardCostConfigurationView: View {
    var body: some View {
        Text("Reward Cost Configuration View - To be modularized")
    }
}

struct EntertainmentAppCostConfigurationView: View {
    var body: some View {
        Text("Entertainment App Cost Configuration View - To be modularized")
    }
}

#if DEBUG
struct ParentSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ParentSettingsView()
    }
}
#endif