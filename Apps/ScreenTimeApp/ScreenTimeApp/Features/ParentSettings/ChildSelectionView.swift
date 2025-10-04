import SwiftUI
import FamilyControlsKit

/// Child selection view for navigating to child-specific settings
struct ChildSelectionView: View {
    let onChildSelected: (FamilyMemberInfo) -> Void
    let destinationType: ChildSettingDestination
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?

    enum ChildSettingDestination {
        case timeLimits, bedtime, reports, trends, learningAppSettings, activitySettings, rewardAppSettings

        var title: String {
            switch self {
            case .timeLimits: return "Daily Time Limits"
            case .bedtime: return "Bedtime Settings"
            case .reports: return "Detailed Reports"
            case .trends: return "Usage Trends"
            case .learningAppSettings: return "Learning App Settings"
            case .activitySettings: return "Activity Settings"
            case .rewardAppSettings: return "Reward App Settings"
            }
        }

        var description: String {
            switch self {
            case .timeLimits: return "Set daily screen time limits for your child"
            case .bedtime: return "Configure bedtime schedules and restrictions"
            case .reports: return "View detailed screen time and learning reports"
            case .trends: return "Analyze usage patterns and trends over time"
            case .learningAppSettings: return "Configure learning app points for this child"
            case .activitySettings: return "Configure activity reward costs for this child"
            case .rewardAppSettings: return "Configure entertainment app unlock costs for this child"
            }
        }

        func destinationView(for child: FamilyMemberInfo) -> some View {
            switch self {
            case .timeLimits:
                return AnyView(BedtimeSettingsView())
            case .bedtime:
                return AnyView(BedtimeSettingsView())
            case .reports:
                return AnyView(ReportsView())
            case .trends:
                return AnyView(UsageTrendsView())
            case .learningAppSettings:
                return AnyView(LearningAppRewardsView())
            case .activitySettings:
                return AnyView(ChildSpecificRewardAppView())
            case .rewardAppSettings:
                return AnyView(ChildSpecificRewardAppView())
            }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header with improved styling
            VStack(spacing: 16) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Select Child")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(destinationType.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Search bar for filtering children
            TextField("Search children...", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Children List with improved organization
            if familyMemberService.isLoading {
                ProgressView("Loading family members...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let children = familyMemberService.familyMembers.filter { $0.isChild }
                
                if children.isEmpty {
                    // Empty State
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(children, id: \.id) { child in
                                ChildSelectionCard(child: child)
                                    .onTapGesture {
                                        onChildSelected(child)
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            Spacer()
        }
        .navigationTitle(destinationType.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFamilyMembers()
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

/// Card component for selecting a child from the family with improved styling
struct ChildSelectionCard: View {
    let child: FamilyMemberInfo
    
    var body: some View {
        HStack(spacing: 16) {
            // Child Avatar with status indicator
            ZStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                // Status indicator
                Circle()
                    .fill(child.hasAppInstalled ? Color.green : Color.orange)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 16, y: 16)
                    .alignmentGuide(.trailing) { _ in 0 }
                    .alignmentGuide(.bottom) { _ in 0 }
            }
            
            // Child Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if child.hasAppInstalled {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("App Installed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("App needed on child's device")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .contentShape(Rectangle()) // Make the entire card tappable
    }
}

/// Empty state view for when no children are found
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("No Children Found")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Set up Family Sharing to add children to your family group.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: FamilySetupView()) {
                Text("Family Setup Guide")
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

#if DEBUG
struct ChildSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ChildSelectionView(
            onChildSelected: { _ in },
            destinationType: .timeLimits
        )
    }
}
#endif