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

// Family Setup View - Initial family configuration and onboarding
struct FamilySetupView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var parentName = ""
    @State private var familyName = ""
    @State private var setupStep = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Indicator
                    VStack(spacing: 8) {
                        Text("Family Setup")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Step \(setupStep) of 3")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ProgressView(value: Double(setupStep), total: 3.0)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                    }
                    .padding(.horizontal)

                    // Setup Content
                    switch setupStep {
                    case 1:
                        familyBasicsStep
                    case 2:
                        addChildrenStep
                    case 3:
                        setupCompleteStep
                    default:
                        familyBasicsStep
                    }

                    Spacer()

                    // Navigation Buttons
                    VStack(spacing: 12) {
                        if setupStep < 3 {
                            Button("Continue") {
                                withAnimation {
                                    setupStep += 1
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(setupStep == 1 && (parentName.isEmpty || familyName.isEmpty))
                        }

                        if setupStep > 1 {
                            Button("Back") {
                                withAnimation {
                                    setupStep -= 1
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Setup Steps

    private var familyBasicsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to ScreenTime Rewards!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Let's set up your family to start earning rewards for learning time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parent Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Your name", text: $parentName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Family Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("The Johnson Family", text: $familyName)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var addChildrenStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Family Members")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Sync your existing family members from Apple Family Sharing.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Current Children List
            if !familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Added Children")
                        .font(.headline)
                        .fontWeight(.medium)

                    ForEach(familyMemberService.familyMembers.filter { $0.isChild }) { child in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text(child.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(child.hasAppInstalled ? "App Installed" : "Setup Required")
                                    .font(.caption)
                                    .foregroundColor(child.hasAppInstalled ? .green : .orange)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }

            Button("Sync Family Members") {
                Task {
                    do {
                        let members = try await familyMemberService.fetchFamilyMembers()
                        await MainActor.run {
                            familyMemberService.familyMembers = members
                        }
                    } catch {
                        print("Error syncing family members: \(error)")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private var setupCompleteStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Setup Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your family is ready to start earning rewards for learning time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Next Steps:")
                    .font(.headline)
                    .fontWeight(.semibold)

                SetupStepRow(
                    icon: "shield.fill",
                    title: "Set up Family Controls",
                    description: "Enable screen time monitoring"
                )

                SetupStepRow(
                    icon: "graduationcap.fill",
                    title: "Configure Learning Apps",
                    description: "Choose which apps earn rewards"
                )

                SetupStepRow(
                    icon: "gift.fill",
                    title: "Set Reward Goals",
                    description: "Define daily learning targets"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Supporting Views

struct SetupStepRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}


#if DEBUG
struct FamilyOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyOverviewView()
    }
}
#endif