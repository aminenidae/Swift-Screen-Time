import Foundation

struct PointTransaction: Codable, Identifiable {
    let id: UUID
    let childID: String
    let points: Int
    let source: PointSource
    let timestamp: Date
    let description: String
    
    init(id: UUID = UUID(), childID: String, points: Int, source: PointSource, timestamp: Date = Date(), description: String) {
        self.id = id
        self.childID = childID
        self.points = points
        self.source = source
        self.timestamp = timestamp
        self.description = description
    }
}

enum PointSource: String, Codable {
    case learningApp
    case streakBonus
    case goalCompletion
    case manualAdjustment
}