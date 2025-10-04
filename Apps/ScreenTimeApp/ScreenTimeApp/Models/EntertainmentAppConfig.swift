import Foundation

struct EntertainmentAppConfig: Codable, Identifiable {
    let id = UUID()
    let bundleID: String
    let displayName: String
    let pointsCostPer30Min: Int
    let pointsCostPer60Min: Int
    let isEnabled: Bool
    let parentConfiguredAt: Date
    
    func pointsCost(for durationMinutes: Int) -> Int {
        if durationMinutes <= 30 {
            return pointsCostPer30Min
        } else {
            return pointsCostPer60Min
        }
    }
}