import Foundation

struct AppUnlockInfo: Codable, Identifiable {
    let id = UUID()
    let bundleID: String
    let appName: String
    let unlockedAt: Date
    let expiresAt: Date
    let pointsCost: Int
    let childID: String
    
    var isActive: Bool {
        Date() < expiresAt
    }
    
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }
}