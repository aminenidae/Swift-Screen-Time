import SwiftUI

/// Quick actions section with improved layout
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                NavigationLink(destination: FamilySetupView()) {
                    EnhancedQuickActionCard(
                        title: "Family Setup", 
                        icon: "house.circle.fill", 
                        color: .blue
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: ReportsView()) {
                    EnhancedQuickActionCard(
                        title: "Reports", 
                        icon: "chart.bar.fill", 
                        color: .green
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: BasicTimeLimitsView()) {
                    EnhancedQuickActionCard(
                        title: "Time Limits", 
                        icon: "clock.fill", 
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: ChildSpecificAppCategoriesView()) {
                    EnhancedQuickActionCard(
                        title: "App Categories", 
                        icon: "square.grid.2x2.fill", 
                        color: .purple
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Mock views for navigation links
struct ReportsView: View {
    var body: some View {
        Text("Reports View")
    }
}

struct BasicTimeLimitsView: View {
    var body: some View {
        Text("Time Limits View")
    }
}

struct ChildSpecificAppCategoriesView: View {
    var body: some View {
        Text("App Categories View")
    }
}