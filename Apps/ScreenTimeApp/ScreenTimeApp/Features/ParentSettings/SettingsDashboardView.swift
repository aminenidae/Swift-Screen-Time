import SwiftUI
import FamilyControlsKit

/// Dashboard view for settings with search and quick access
struct SettingsDashboardView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var searchText = ""
    @State private var selectedChild: FamilyMemberInfo?
    
    // Quick access settings
    private let quickAccessSettings = [
        QuickAccessSetting(
            title: "Daily Time Limits",
            description: "Set screen time limits for your children",
            icon: "clock.fill",
            color: .orange,
            destination: ChildSelectionView.ChildSettingDestination.timeLimits
        ),
        QuickAccessSetting(
            title: "Learning App Points",
            description: "Configure points for educational activities",
            icon: "graduationcap.fill",
            color: .green,
            destination: ChildSelectionView.ChildSettingDestination.learningAppSettings
        ),
        QuickAccessSetting(
            title: "Reward Apps",
            description: "Set up apps that require points to unlock",
            icon: "gift.fill",
            color: .purple,
            destination: ChildSelectionView.ChildSettingDestination.rewardAppSettings
        ),
        QuickAccessSetting(
            title: "Bedtime Settings",
            description: "Schedule bedtime restrictions",
            icon: "moon.fill",
            color: .indigo,
            destination: ChildSelectionView.ChildSettingDestination.bedtime
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "gear")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Configure your family's Screen Time Rewards experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Search bar
                    TextField("Search settings...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Quick Access Section
                    if searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Access")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(quickAccessSettings) { setting in
                                    QuickAccessCard(setting: setting) { destination in
                                        if selectedChild != nil {
                                            // Navigate to child-specific setting
                                        } else {
                                            // Show child selection first
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Child Selector
                    ChildSelectorSection(
                        familyMemberService: familyMemberService,
                        selectedChild: $selectedChild
                    )
                    
                    // All Settings Categories
                    if searchText.isEmpty {
                        AllSettingsCategories(selectedChild: selectedChild)
                    } else {
                        SearchResults(searchText: searchText, selectedChild: selectedChild)
                    }
                    
                    Spacer()
                }
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

/// Quick access setting model
struct QuickAccessSetting: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: ChildSelectionView.ChildSettingDestination
}

/// Quick access card view
struct QuickAccessCard: View {
    let setting: QuickAccessSetting
    let onTap: (ChildSelectionView.ChildSettingDestination) -> Void
    
    var body: some View {
        Button(action: {
            onTap(setting.destination)
        }) {
            VStack(spacing: 12) {
                Image(systemName: setting.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(setting.color)
                    )
                
                VStack(spacing: 4) {
                    Text(setting.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text(setting.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Child selector section
struct ChildSelectorSection: View {
    @ObservedObject var familyMemberService: FamilyMemberService
    @Binding var selectedChild: FamilyMemberInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Child Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                EmptyChildState()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(familyMemberService.familyMembers.filter({ $0.isChild }), id: \.id) { child in
                            ChildChipView(
                                child: child,
                                isSelected: selectedChild?.id == child.id
                            ) {
                                if selectedChild?.id == child.id {
                                    selectedChild = nil
                                } else {
                                    selectedChild = child
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let selectedChild = selectedChild {
                    HStack {
                        Text("Settings for \(selectedChild.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Clear") {
                            self.selectedChild = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

/// Empty child state view
struct EmptyChildState: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.2.slash")
                    .foregroundColor(.orange)
                
                Text("No children added")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink(destination: FamilySetupView()) {
                    Text("Add Child")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Child chip view for selection
struct ChildChipView: View {
    let child: FamilyMemberInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(child.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

/// All settings categories view
struct AllSettingsCategories: View {
    let selectedChild: FamilyMemberInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            SettingsCategoryRow(
                title: "General Settings",
                icon: "gear",
                color: .blue,
                itemCount: 4,
                destination: nil
            )
            
            SettingsCategoryRow(
                title: "Reward System",
                icon: "star.fill",
                color: .yellow,
                itemCount: 1,
                destination: nil
            )
            
            SettingsCategoryRow(
                title: "Child Settings",
                icon: "person.2.fill",
                color: .green,
                itemCount: selectedChild != nil ? 7 : 0,
                destination: nil
            )
            
            SettingsCategoryRow(
                title: "Account",
                icon: "person.crop.circle",
                color: .purple,
                itemCount: 2,
                destination: nil
            )
        }
        .padding(.horizontal)
    }
}

/// Settings category row
struct SettingsCategoryRow: View {
    let title: String
    let icon: String
    let color: Color
    let itemCount: Int
    let destination: AnyView?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if itemCount > 0 {
                    Text("\(itemCount) settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No children configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

/// Search results view
struct SearchResults: View {
    let searchText: String
    let selectedChild: FamilyMemberInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // This would be populated with actual search results in a real implementation
            Text("No results found for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
}

#Preview {
    SettingsDashboardView()
}
