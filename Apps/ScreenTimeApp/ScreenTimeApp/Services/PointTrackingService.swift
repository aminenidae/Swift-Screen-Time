import Foundation
import Combine

class PointTrackingService: ObservableObject {
    static let shared = PointTrackingService()
    
    @Published var pointsEarned: PointTransaction? = nil
    
    private init() {}
    
    func startTracking(for childID: String) async throws {
        // In a real implementation, this would start monitoring Screen Time
        // For now, we'll just simulate
        print("Started tracking points for child: \(childID)")
    }
    
    func recordPoints(for childID: String, points: Int, source: PointSource, description: String) {
        let transaction = PointTransaction(
            childID: childID,
            points: points,
            source: source,
            description: description
        )
        
        DispatchQueue.main.async {
            self.pointsEarned = transaction
        }
    }
}