import Foundation
import SharedModels
import CloudKitService
import CloudKit
import Combine

@available(iOS 15.0, macOS 12.0, *)
public class ParentCoordinationService: ObservableObject {
    public static let shared = ParentCoordinationService()
    
    private let container: CKContainer
    private let database: CKDatabase
    private var subscriptions: Set<AnyCancellable> = []
    private var coordinationSubscriptions: [UUID: CKSubscription] = [:]
    private let coordinationRepository: ParentCoordinationRepository
    
    private init() {
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        self.coordinationRepository = CloudKitService.shared
    }
    
    // MARK: - Zone Management
    
    /// Creates the parent coordination zone for real-time sync
    public func createParentCoordinationZone(for familyID: UUID) async throws {
        let zoneID = CKRecordZone.ID(zoneName: "parent-coordination-\(familyID)")
        let zone = CKRecordZone(zoneID: zoneID)
        
        do {
            _ = try await database.save(zone)
            print("Parent coordination zone created for family: \(familyID)")
        } catch {
            // Zone might already exist, which is fine
            print("Zone creation error (may already exist): \(error)")
        }
    }
    
    // MARK: - Event Publishing
    
    /// Publishes coordination events for real-time sync
    public func publishCoordinationEvent(_ event: ParentCoordinationEvent) async throws {
        let record = CKRecord(recordType: "ParentCoordinationEvent")
        
        record["familyID"] = event.familyID.uuidString as CKRecordValue
        record["triggeringUserID"] = event.triggeringUserID as CKRecordValue
        record["eventType"] = event.eventType.rawValue as CKRecordValue
        record["targetEntity"] = event.targetEntity as CKRecordValue
        record["targetEntityID"] = event.targetEntityID.uuidString as CKRecordValue
        record["changes"] = try? JSONSerialization.data(withJSONObject: event.changes.dictionary) as CKRecordValue
        record["timestamp"] = event.timestamp as CKRecordValue
        record["deviceID"] = event.deviceID as CKRecordValue?
        
        // Save to the parent coordination zone
        let zoneID = CKRecordZone.ID(zoneName: "parent-coordination-\(event.familyID)")
        record.parent = CKRecord.Reference(recordID: CKRecord.ID(recordName: event.familyID.uuidString, zoneID: zoneID), action: .none)
        
        _ = try await database.save(record)
        print("Coordination event published: \(event.eventType)")
    }
    
    // MARK: - Event Fetching
    
    /// Fetches coordination events for a family
    public func fetchCoordinationEvents(for familyID: UUID) async throws -> [ParentCoordinationEvent] {
        return try await coordinationRepository.fetchCoordinationEvents(for: familyID)
    }
    
    /// Fetches coordination events for a family with a date range filter
    public func fetchCoordinationEvents(for familyID: UUID, dateRange: DateRange?) async throws -> [ParentCoordinationEvent] {
        return try await coordinationRepository.fetchCoordinationEvents(for: familyID, dateRange: dateRange)
    }
    
    // MARK: - Subscriptions
    
    /// Creates a subscription for parent coordination events
    public func createCoordinationSubscription(for familyID: UUID, excluding userID: String) async throws {
        let predicate = NSPredicate(
            format: "familyID == %@ AND triggeringUserID != %@",
            familyID.uuidString,
            userID
        )
        
        let subscription = CKQuerySubscription(
            recordType: "ParentCoordinationEvent",
            predicate: predicate,
            subscriptionID: "parent-coordination-\(familyID)-\(userID)",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push
        subscription.notificationInfo = notificationInfo
        
        _ = try await database.save(subscription)
        coordinationSubscriptions[familyID] = subscription
        print("Coordination subscription created for family: \(familyID)")
    }
    
    /// Removes a coordination subscription
    public func removeCoordinationSubscription(for familyID: UUID) async throws {
        let subscriptionID = "parent-coordination-\(familyID)-\(currentUserID())"
        try await database.deleteSubscription(withID: subscriptionID)
        coordinationSubscriptions.removeValue(forKey: familyID)
        print("Coordination subscription removed for family: \(familyID)")
    }
    
    /// Gets the current user ID
    private func currentUserID() -> String {
        // In a real implementation, this would get the actual user ID
        return "current-user-id"
    }
    
    // MARK: - Event Handling
    
    /// Handles background fetch for coordination events
    public func handleBackgroundFetch(for familyID: UUID) async throws -> [ParentCoordinationEvent] {
        let predicate = NSPredicate(format: "familyID == %@", familyID.uuidString)
        let query = CKQuery(recordType: "ParentCoordinationEvent", predicate: predicate)
        
        let records = try await database.records(matching: query)
        var events: [ParentCoordinationEvent] = []
        
        for (_, result) in records.matchResults {
            switch result {
            case .success(let record):
                if let event = convertToCoordinationEvent(record) {
                    events.append(event)
                }
            case .failure(let error):
                print("Failed to fetch coordination record: \(error)")
            }
        }
        
        return events
    }
    
    /// Converts CKRecord to ParentCoordinationEvent
    private func convertToCoordinationEvent(_ record: CKRecord) -> ParentCoordinationEvent? {
        guard let familyIDString = record["familyID"] as? String,
              let familyID = UUID(uuidString: familyIDString),
              let triggeringUserID = record["triggeringUserID"] as? String,
              let eventTypeString = record["eventType"] as? String,
              let eventType = ParentCoordinationEventType(rawValue: eventTypeString),
              let targetEntity = record["targetEntity"] as? String,
              let targetEntityIDString = record["targetEntityID"] as? String,
              let targetEntityID = UUID(uuidString: targetEntityIDString),
              let changesData = record["changes"] as? Data,
              let changesDict = try? JSONSerialization.jsonObject(with: changesData) as? [String: String],
              let timestamp = record["timestamp"] as? Date
        else {
            return nil
        }
        
        let deviceID = record["deviceID"] as? String
        
        return ParentCoordinationEvent(
            id: UUID(),
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            eventType: eventType,
            targetEntity: targetEntity,
            targetEntityID: targetEntityID,
            changes: CodableDictionary(changesDict),
            timestamp: timestamp,
            deviceID: deviceID
        )
    }
    
    // MARK: - Publishers
    
    /// Provides a Combine publisher for coordination events
    public func coordinationEventsPublisher(for familyID: UUID) -> AnyPublisher<ParentCoordinationEvent, Error> {
        // This would be implemented to emit events as they arrive
        // For now, returning an empty publisher
        return PassthroughSubject<ParentCoordinationEvent, Error>().eraseToAnyPublisher()
    }
}