import SwiftUI
import FamilyControlsKit

/// Container view that manages the settings navigation and state
struct SettingsContainerView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var showingChildSelection = false
    @State private var pendingDestination: ChildSelectionView.ChildSettingDestination?
    
    var body: some View {
        TabView {
            // Dashboard Tab
            SettingsDashboardView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Dashboard")
                }
            
            // All Settings Tab
            ParentSettingsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("All Settings")
                }
            
            // Preferences Tab
            NavigationStack {
                SettingsPreferencesView()
            }
            .tabItem {
                Image(systemName: "gearshape.2")
                Text("Preferences")
            }
        }
    }
    
    /// Navigate to a child-specific setting, showing child selection if needed
    private func navigateToChildSetting(_ destination: ChildSelectionView.ChildSettingDestination) {
        if let child = selectedChild {
            // Navigate directly if child is already selected
            // In a real implementation, this would push the appropriate view
        } else {
            // Show child selection first
            pendingDestination = destination
            showingChildSelection = true
        }
    }
}

/// Extension to add child selection functionality
extension SettingsContainerView {
    /// View for child selection sheet
    private func childSelectionSheet() -> some View {
        ChildSelectionView(
            onChildSelected: { child in
                selectedChild = child
                showingChildSelection = false
                if let destination = pendingDestination {
                    // Navigate to the pending destination
                    pendingDestination = nil
                }
            },
            destinationType: pendingDestination ?? .timeLimits
        )
    }
}

#Preview {
    SettingsContainerView()
}