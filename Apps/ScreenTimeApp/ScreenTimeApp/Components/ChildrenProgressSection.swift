import SwiftUI

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