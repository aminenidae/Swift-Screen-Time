import SwiftUI
import FamilyControlsKit

/// Main parent interface with Dashboard, Family, and Settings tabs
struct ParentMainView: View {
    var body: some View {
        TabView {
            // Dashboard Tab - Landing view with child progress overview
            ParentDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }

            // Family Tab - Child-specific settings and configurations
            ParentFamilyView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Family")
                }

            // Settings Tab - System-level settings
            ParentSystemSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}

// MARK: - Dashboard Tab

/// Dashboard tab showing child progress overview and family statistics
struct ParentDashboardView: View {
    @StateObject private var familyMemberService = FamilyMemberService()

    // Mock data for children progress - replace with real data later
    let mockChildrenData = [
        ("Alex", 125, 85, 3),
        ("Sam", 95, 60, 1)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Subscription Status Indicator
                    SubscriptionStatusIndicator()

                    // Today's Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Summary")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            let children = familyMemberService.familyMembers.filter { $0.isChild }
                            OverviewStatCard(title: "Children", value: "\(children.count)", icon: "person.2.fill", color: .blue)
                            OverviewStatCard(title: "Total Points", value: "\(mockChildrenData.reduce(0) { $0 + $1.1 }))", icon: "star.fill", color: .yellow)
                            OverviewStatCard(title: "Active Today", value: "\(mockChildrenData.filter { $0.3 > 0 }.count)", icon: "checkmark.circle.fill", color: .green)
                        }
                    }

                    // Children Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Children's Progress")
                            .font(.title2)
                            .fontWeight(.bold)

                        let children = familyMemberService.familyMembers.filter { $0.isChild }
                        if children.isEmpty {
                            // Empty state when no children found
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.slash.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)

                                Text("No children found in Family Sharing")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                NavigationLink(destination: FamilySetupView()) {
                                    Text("Set up Family Sharing")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        } else {
                            // Show children progress using mock data for now
                            ForEach(Array(mockChildrenData.enumerated()), id: \.offset) { index, child in
                                ChildProgressCard(
                                    name: child.0,
                                    points: child.1,
                                    learningMinutes: child.2,
                                    streak: child.3
                                )
                            }
                        }
                    }

                    // Quick Settings
                    SettingsSummaryView()
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 12) {
                            RecentActivityRow(
                                childName: "Alex",
                                activity: "Completed 30 min of Khan Academy",
                                points: "+30",
                                time: "2 hours ago",
                                color: .green
                            )
                            RecentActivityRow(
                                childName: "Sam",
                                activity: "Unlocked YouTube Kids for 15 min",
                                points: "-15",
                                time: "3 hours ago",
                                color: .orange
                            )
                            RecentActivityRow(
                                childName: "Alex",
                                activity: "Achieved 3-day learning streak",
                                points: "+10",
                                time: "Yesterday",
                                color: .blue
                            )
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.bold)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            NavigationLink(destination: FamilySetupView()) {
                                QuickActionCard(title: "Family Setup", icon: "house.circle.fill", action: {})
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ReportsView()) {
                                QuickActionCard(title: "Reports", icon: "chart.bar.fill", action: {})
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                loadFamilyMembers()
            }
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

// MARK: - Family Tab

/// Family tab with child-specific settings and configurations
struct ParentFamilyView: View {
    @StateObject private var familyMemberService = FamilyMemberService()

    var body: some View {
        NavigationStack {
            List {
                // Child Settings
                if !familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    Section("CHILD SETTINGS") {
                        NavigationLink(destination: ChildSpecificAppCategoriesView()) {
                            Label("App Categories", systemImage: "square.grid.2x2.fill")
                        }
                        NavigationLink(destination: ChildSpecificLearningAppView()) {
                            Label("Learning Apps", systemImage: "graduationcap.fill")
                        }
                        NavigationLink(destination: ChildSpecificRewardAppView()) {
                            Label("Reward Apps", systemImage: "gift.fill")
                        }
                        NavigationLink(destination: ChildSpecificSpecialRewardsView()) {
                            Label("Special Rewards", systemImage: "star.fill")
                        }
                        NavigationLink(destination: BasicTimeLimitsView()) {
                            Label("Daily Time Limits", systemImage: "clock.fill")
                        }
                        NavigationLink(destination: ReportsView()) {
                            Label("Detailed Reports", systemImage: "chart.bar.fill")
                        }
                        NavigationLink(destination: UsageTrendsView()) {
                            Label("Usage Trends", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }
                } else {
                    // Empty state for no children
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)

                            Text("No children found")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Set up Family Sharing to manage your children's screen time and rewards.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            NavigationLink(destination: FamilySetupView()) {
                                Text("Set up Family Sharing")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Family")
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

// MARK: - Settings Tab

/// Settings tab with system-level configuration
struct ParentSystemSettingsView: View {
    var body: some View {
        SettingsContainerView()
    }
}

// MARK: - Supporting Views

struct RecentActivityRow: View {
    let childName: String
    let activity: String
    let points: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(childName.prefix(1))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(childName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(points)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }

                Text(activity)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(time)
                    .font(.caption2)
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
struct ParentMainView_Previews: PreviewProvider {
    static var previews: some View {
        ParentMainView()
    }
}
#endif