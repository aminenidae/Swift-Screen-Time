import Foundation
import Combine

// Family member model
struct FamilyMember: Identifiable, Codable {
    let id = UUID()
    let name: String
    let isChild: Bool
    let hasAppInstalled: Bool
    let lastActive: Date?
    
    init(name: String, isChild: Bool, hasAppInstalled: Bool = false, lastActive: Date? = nil) {
        self.name = name
        self.isChild = isChild
        self.hasAppInstalled = hasAppInstalled
        self.lastActive = lastActive
    }
}

// Family member service
class FamilyMemberService: ObservableObject {
    @Published var familyMembers: [FamilyMember] = []
    
    func fetchFamilyMembers() async throws -> [FamilyMember] {
        // Simulate fetching family members
        // In a real app, this would connect to Family Controls or CloudKit
        let mockMembers = [
            FamilyMember(name: "Alex", isChild: true, hasAppInstalled: true, lastActive: Date()),
            FamilyMember(name: "Sam", isChild: true, hasAppInstalled: false, lastActive: Date().addingTimeInterval(-3600)),
            FamilyMember(name: "Parent", isChild: false, hasAppInstalled: true)
        ]
        
        return mockMembers
    }
}