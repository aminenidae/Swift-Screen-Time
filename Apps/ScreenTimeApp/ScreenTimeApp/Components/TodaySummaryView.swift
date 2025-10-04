import SwiftUI

/// Today's summary view with enhanced visual design
struct TodaySummaryView: View {
    let childrenCount: Int
    let totalPoints: Int
    let activeChildren: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Summary")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                OverviewStatCard(
                    title: "Children", 
                    value: "\(childrenCount)", 
                    icon: "person.2.fill", 
                    color: .blue
                )
                
                OverviewStatCard(
                    title: "Total Points", 
                    value: "\(totalPoints)", 
                    icon: "star.fill", 
                    color: .yellow
                )
                
                OverviewStatCard(
                    title: "Active Today", 
                    value: "\(activeChildren)", 
                    icon: "checkmark.circle.fill", 
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}