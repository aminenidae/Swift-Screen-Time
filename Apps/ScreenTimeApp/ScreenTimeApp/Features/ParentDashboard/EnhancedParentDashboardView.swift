import SwiftUI
import SharedModels
import CloudKitService
import DesignSystem
import FamilyControlsKit

/// Enhanced dashboard tab showing child progress overview and family statistics
struct EnhancedParentDashboardView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var isLoading = false
    
    // Real data placeholders - to be replaced with actual data sources
    @State private var todayPoints = 245
    @State private var activeChildrenCount = 2
    @State private var totalLearningMinutes = 185
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Subscription Status Indicator
                    SubscriptionStatusIndicator()
                        .padding(.top, 8)
                    
                    // Today's Summary with enhanced visuals
                    TodaySummaryView(
                        childrenCount: familyMemberService.familyMembers.filter { $0.isChild }.count,
                        totalPoints: todayPoints,
                        activeChildren: activeChildrenCount
                    )
                    
                    // Children Progress with improved cards
                    ChildrenProgressSection(
                        familyMemberService: familyMemberService,
                        isLoading: isLoading
                    )
                    
                    // Recent Activity with enhanced styling
                    RecentActivitySection()
                    
                    // Quick Actions with improved layout
                    QuickActionsSection()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await refreshData()
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        Task {
            await refreshData()
        }
    }
    
    private func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let members = try await familyMemberService.fetchFamilyMembers()
            await MainActor.run {
                familyMemberService.familyMembers = members
            }
        } catch {
            print("Error loading family members: \(error)")
        }
    }
}

#Preview {
    EnhancedParentDashboardView()
}