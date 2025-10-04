import SwiftUI
import FamilyControlsKit

/// Container view that manages the settings navigation and state
struct SettingsContainerView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var showingChildSelection = false
    @State private var pendingDestination: ChildSelectionView.ChildSettingDestination?
    
    var body: some View {
        ParentSettingsView()
    }
    
    /// Navigate to a child-specific setting, showing child selection if needed
    private func navigateToChildSetting(_ destination: ChildSelectionView.ChildSettingDestination) {
        if selectedChild != nil {
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
                if pendingDestination != nil {
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