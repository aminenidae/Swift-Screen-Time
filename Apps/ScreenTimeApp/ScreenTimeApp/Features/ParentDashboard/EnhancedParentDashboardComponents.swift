import SwiftUI
import FamilyControlsKit

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

/// Children progress section with improved layout
struct ChildrenProgressSection: View {
    @ObservedObject var familyMemberService: FamilyMemberService
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Children's Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            let children = familyMemberService.familyMembers.filter { $0.isChild }
            if children.isEmpty {
                EmptyChildrenState()
            } else {
                LazyVStack(spacing: 16) {
                    // Using mock data for now - replace with real data
                    ForEach(0..<min(children.count, 3), id: \.self) { index in
                        let mockData = [
                            ("Alex", 125, 85, 3),
                            ("Sam", 95, 60, 1),
                            ("Jordan", 140, 95, 5)
                        ][index]
                        
                        EnhancedChildProgressCard(
                            name: mockData.0,
                            points: mockData.1,
                            learningMinutes: mockData.2,
                            streak: mockData.3
                        )
                    }
                }
            }
        }
    }
}

/// Enhanced child progress card with better visual design
struct EnhancedChildProgressCard: View {
    let name: String
    let points: Int
    let learningMinutes: Int
    let streak: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Child avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(name.prefix(1))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            // Progress information
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(points) pts")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(learningMinutes) min")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(streak) days")
                            .font(.subheadline)
                    }
                }
            }
            
            Spacer()
            
            // Quick action button
            Button(action: {
                // Navigate to child settings
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

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

/// Enhanced recent activity row with better styling
struct EnhancedRecentActivityRow: View {
    let childName: String
    let activity: String
    let points: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(childName.prefix(1))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(childName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(points)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                
                Text(activity)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

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
                
                NavigationLink(destination: DashboardReportsView()) {
                    EnhancedQuickActionCard(
                        title: "Reports", 
                        icon: "chart.bar.fill", 
                        color: .green
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: DashboardTimeLimitsView()) {
                    EnhancedQuickActionCard(
                        title: "Time Limits", 
                        icon: "clock.fill", 
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: DashboardAppCategoriesView()) {
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

/// Enhanced quick action card with better visual design
struct EnhancedQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color)
                )
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

/// Empty state for when no children are found
struct EmptyChildrenState: View {
    var body: some View {
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
    }
}

// Mock views for navigation links
struct DashboardReportsView: View {
    var body: some View {
        Text("Reports View")
    }
}

struct DashboardTimeLimitsView: View {
    var body: some View {
        Text("Time Limits View")
    }
}

struct DashboardAppCategoriesView: View {
    var body: some View {
        Text("App Categories View")
    }
}