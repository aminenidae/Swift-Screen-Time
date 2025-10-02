import Foundation
import SharedModels
import CloudKitService
import Combine

@available(iOS 15.0, macOS 12.0, *)
public class ChangeDetectionService {
    public static let shared = ChangeDetectionService()
    
    private let coordinationService: ParentCoordinationService
    private let cloudKitService: CloudKitService
    private var cancellables: Set<AnyCancellable> = []
    
    private init() {
        self.coordinationService = ParentCoordinationService.shared
        self.cloudKitService = CloudKitService.shared
    }
    
    /// Sets up change detection for a family
    public func setupChangeDetection(for familyID: UUID, userID: String) {
        // In a real implementation, this would subscribe to various
        // repository changes using Combine publishers
        print("Setting up change detection for family: \(familyID)")
    }
    
    /// Publishes an app categorization change event
    public func publishAppCategorizationChange(
        _ categorization: AppCategorization,
        familyID: UUID,
        userID: String
    ) async throws {
        let changes: [String: String] = [
            "category": categorization.category.rawValue,
            "pointsPerHour": String(categorization.pointsPerHour)
        ]
        
        let event = ParentCoordinationEvent(
            id: UUID(),
            familyID: familyID,
            triggeringUserID: userID,
            eventType: .appCategorizationChanged,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(uuidString: categorization.id) ?? UUID(),
            changes: CodableDictionary(changes),
            timestamp: Date(),
            deviceID: getCurrentDeviceID()
        )
        
        try await coordinationService.publishCoordinationEvent(event)
    }
    
    /// Publishes a child profile modification event
    public func publishChildProfileChange(
        _ childProfile: ChildProfile,
        familyID: UUID,
        userID: String
    ) async throws {
        let changes: [String: String] = [
            "name": childProfile.name,
            "pointBalance": String(childProfile.pointBalance)
        ]
        
        let event = ParentCoordinationEvent(
            id: UUID(),
            familyID: familyID,
            triggeringUserID: userID,
            eventType: .childProfileModified,
            targetEntity: "ChildProfile",
            targetEntityID: UUID(uuidString: childProfile.id) ?? UUID(),
            changes: CodableDictionary(changes),
            timestamp: Date(),
            deviceID: getCurrentDeviceID()
        )
        
        try await coordinationService.publishCoordinationEvent(event)
    }
    
    /// Publishes a points adjustment event
    public func publishPointsAdjustment(
        childID: String,
        newBalance: Int,
        oldBalance: Int,
        familyID: UUID,
        userID: String
    ) async throws {
        let changes: [String: String] = [
            "childID": childID,
            "newBalance": String(newBalance),
            "oldBalance": String(oldBalance)
        ]
        
        let event = ParentCoordinationEvent(
            id: UUID(),
            familyID: familyID,
            triggeringUserID: userID,
            eventType: .pointsAdjusted,
            targetEntity: "PointBalance",
            targetEntityID: UUID(uuidString: childID) ?? UUID(),
            changes: CodableDictionary(changes),
            timestamp: Date(),
            deviceID: getCurrentDeviceID()
        )
        
        try await coordinationService.publishCoordinationEvent(event)
    }
    
    /// Publishes a reward redemption event
    public func publishRewardRedemption(
        redemption: PointToTimeRedemption,
        familyID: UUID,
        userID: String
    ) async throws {
        let changes: [String: String] = [
            "childID": redemption.childProfileID,
            "pointsSpent": String(redemption.pointsSpent)
        ]
        
        let event = ParentCoordinationEvent(
            id: UUID(),
            familyID: familyID,
            triggeringUserID: userID,
            eventType: .rewardRedeemed,
            targetEntity: "PointToTimeRedemption",
            targetEntityID: UUID(uuidString: redemption.id) ?? UUID(),
            changes: CodableDictionary(changes),
            timestamp: Date(),
            deviceID: getCurrentDeviceID()
        )
        
        try await coordinationService.publishCoordinationEvent(event)
    }
    
    /// Gets the current device ID
    private func getCurrentDeviceID() -> String {
        // In a real implementation, this would get the actual device ID
        return "current-device-id"
    }
}