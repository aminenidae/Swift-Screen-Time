import Foundation

enum RewardStatus: String, Codable {
    case pending
    case approved
    case rejected
    case completed
}

struct RedeemedReward: Codable, Identifiable {
    let id: UUID
    let name: String
    let cost: Int
    let redeemedAt: Date
    let status: RewardStatus
    let approvedAt: Date?
    let completedAt: Date?
    
    init(id: UUID = UUID(), name: String, cost: Int, redeemedAt: Date = Date(), status: RewardStatus = .pending, approvedAt: Date? = nil, completedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.cost = cost
        self.redeemedAt = redeemedAt
        self.status = status
        self.approvedAt = approvedAt
        self.completedAt = completedAt
    }
}