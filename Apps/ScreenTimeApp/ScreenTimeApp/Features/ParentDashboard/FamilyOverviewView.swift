import SwiftUI
import FamilyControlsKit



/// Main family overview showing children's progress and family statistics
struct FamilyOverviewView: View {
    @State private var showingAppCategories = false
    @State private var showingTimeLimits = false
    @State private var showingReports = false
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

                    // Family Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Family Overview")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            let children = familyMemberService.familyMembers.filter { $0.isChild }
                            OverviewStatCard(title: "Children", value: "\(children.count)", icon: "person.2.fill", color: .blue)
                            OverviewStatCard(title: "Total Points", value: "\(mockChildrenData.reduce(0) { $0 + $1.1 })", icon: "star.fill", color: .yellow)
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

                            QuickActionCard(title: "Time Limits", icon: "clock.fill", action: {})

                            QuickActionCard(title: "Reports", icon: "chart.bar.fill", action: {})
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Family Dashboard")
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

// Forward declarations for views that will be modularized later
struct FamilySetupView: View {
    var body: some View {
        Text("Family Setup View - To be modularized")
    }
}

#if DEBUG
struct FamilyOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyOverviewView()
    }
}
#endif