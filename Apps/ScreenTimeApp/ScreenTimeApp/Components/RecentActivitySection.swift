import SwiftUI

/// Recent activity section with enhanced styling
struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                EnhancedRecentActivityRow(
                    childName: "Alex",
                    activity: "Completed 30 min of Khan Academy",
                    points: "+30",
                    time: "2 hours ago",
                    color: .green
                )
                
                EnhancedRecentActivityRow(
                    childName: "Sam",
                    activity: "Unlocked YouTube Kids for 15 min",
                    points: "-15",
                    time: "3 hours ago",
                    color: .orange
                )
                
                EnhancedRecentActivityRow(
                    childName: "Alex",
                    activity: "Achieved 3-day learning streak",
                    points: "+10",
                    time: "Yesterday",
                    color: .blue
                )
            }
        }
    }
}