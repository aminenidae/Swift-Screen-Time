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

            // Account Tab
            AccountTabView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Account")
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

    private let familyTabItems = [
        FamilyTabItem(title: "App Categories", icon: "square.grid.2x2.fill", color: .blue, destination: AnyView(ChildSpecificAppCategoriesView())),
        FamilyTabItem(title: "Learning Apps", icon: "graduationcap.fill", color: .green, destination: AnyView(LearningAppRewardsView())),
        FamilyTabItem(title: "Reward Apps", icon: "gift.fill", color: .purple, destination: AnyView(ChildSpecificRewardAppView())),
        FamilyTabItem(title: "Special Rewards", icon: "star.fill", color: .yellow, destination: AnyView(ChildSpecificRewardAppView())),
        FamilyTabItem(title: "Daily Time Limits", icon: "clock.fill", color: .orange, destination: AnyView(BedtimeSettingsView())),
        FamilyTabItem(title: "Detailed Reports", icon: "chart.bar.fill", color: .red, destination: AnyView(ReportsView())),
        FamilyTabItem(title: "Usage Trends", icon: "chart.line.uptrend.xyaxis", color: .indigo, destination: AnyView(UsageTrendsView()))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if !familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(familyTabItems) { item in
                            NavigationLink(destination: item.destination) {
                                FamilyTabCard(item: item)
                            }
                        }
                    }
                    .padding()
                } else {
                    // Empty state for no children
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

/// Model for family tab items
struct FamilyTabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView
}

/// Card view for family tab items
struct FamilyTabCard: View {
    let item: FamilyTabItem

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(item.color))

            Text(item.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .buttonStyle(.plain)
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