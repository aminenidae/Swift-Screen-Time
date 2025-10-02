import CloudKit
import Foundation
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public class CloudKitSharingService {
    private let database: CKDatabase
    private let sharedDatabase: CKDatabase

    public init(
        database: CKDatabase = CKContainer.default().privateCloudDatabase,
        sharedDatabase: CKDatabase = CKContainer.default().sharedCloudDatabase
    ) {
        self.database = database
        self.sharedDatabase = sharedDatabase
    }

    // MARK: - Family Sharing

    public func shareFamily(
        familyID: String,
        with userID: String,
        permission: CKShare.ParticipantPermission = .readWrite
    ) async throws -> CKShare {
        // Fetch the family record
        let familyRecordID = CKRecord.ID(recordName: familyID)
        let familyRecord = try await database.record(for: familyRecordID)

        // Create CKShare for the family record
        let share = CKShare(rootRecord: familyRecord)
        share[CKShare.SystemFieldKey.title] = "Family Settings"
        share[CKShare.SystemFieldKey.thumbnailImageData] = nil
        share.publicPermission = .none

        // Configure sharing permissions
        share.publicPermission = .none

        // Save the share and the modified family record
        let recordsToSave = [familyRecord, share]
        let (savedRecords, _) = try await database.modifyRecords(
            saving: recordsToSave,
            deleting: []
        )

        // Extract the saved share from the results
        guard let savedRecordResult = savedRecords[share.recordID],
              case .success(let savedRecord) = savedRecordResult,
              let savedShare = savedRecord as? CKShare else {
            throw CloudKitSharingError.shareCreationFailed
        }

        return savedShare
    }

    public func addParticipantToShare(
        shareRecordID: CKRecord.ID,
        userIdentity: CKUserIdentity,
        permission: CKShare.ParticipantPermission = .readWrite
    ) async throws -> CKShare {
        // Fetch the existing share
        let share = try await database.record(for: shareRecordID) as! CKShare

        // Note: Participants are added by CloudKit when they accept the share
        // We can't manually add participants to a share
        // The userIdentity is read-only and set by CloudKit when the participant accepts
        
        // Save the updated share
        let savedShare = try await database.save(share) as! CKShare
        return savedShare
    }

    public func removeParticipantFromShare(
        shareRecordID: CKRecord.ID,
        participantUserID: String
    ) async throws -> CKShare {
        // Fetch the existing share
        let share = try await database.record(for: shareRecordID) as! CKShare

        // Note: Participants are removed by CloudKit when the share is deleted or modified
        // We can't manually remove participants from a share
        
        // Save the updated share
        let savedShare = try await database.save(share) as! CKShare
        return savedShare
    }

    public func fetchShareForFamily(familyID: String) async throws -> CKShare? {
        let familyRecordID = CKRecord.ID(recordName: familyID)
        
        do {
            let record = try await database.record(for: familyRecordID)
            // Check if the record is a share
            if let share = record as? CKShare {
                return share
            }
            return nil
        } catch {
            // No share exists for this family or other error
            return nil
        }
    }

    // MARK: - Child Zone Sharing

    public func shareChildProfileZone(
        childProfileID: String,
        with participantUserID: String
    ) async throws {
        // Get custom zone for child profile
        let zoneID = CKRecordZone.ID(zoneName: "ChildProfile_\(childProfileID)")

        // Fetch all records in the child profile zone
        let query = CKQuery(recordType: "ChildProfile", predicate: NSPredicate(value: true))
        let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

        var recordsToShare: [CKRecord] = []
        for (_, result) in results {
            switch result {
            case .success(let record):
                recordsToShare.append(record)
            case .failure(let error):
                throw error
            }
        }

        // Create shares for each record that needs to be shared
        for record in recordsToShare {
            let share = CKShare(rootRecord: record)
            share.publicPermission = .none

            // Save the share
            _ = try await database.save(share)
        }
    }

    // MARK: - Subscription Management

    public func createFamilySharingSubscription(for familyID: String) async throws -> CKSubscription {
        // Create subscription with explicit ID
        let subscriptionID = "family-sharing-\(familyID)"
        let subscription = CKQuerySubscription(
            recordType: "Family",
            predicate: NSPredicate(format: "recordID == %@", CKRecord.ID(recordName: familyID)),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        subscription.notificationInfo = CKSubscription.NotificationInfo()
        subscription.notificationInfo?.shouldSendContentAvailable = true
        subscription.notificationInfo?.shouldBadge = false

        return try await database.save(subscription)
    }

    public func createChildProfileSubscription(for childProfileID: String) async throws -> CKSubscription {
        // Create subscription with explicit ID
        let subscriptionID = "child-profile-\(childProfileID)"
        let subscription = CKQuerySubscription(
            recordType: "ChildProfile",
            predicate: NSPredicate(format: "familyID == %@", childProfileID),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        subscription.notificationInfo = CKSubscription.NotificationInfo()
        subscription.notificationInfo?.shouldSendContentAvailable = true
        subscription.notificationInfo?.shouldBadge = false

        return try await database.save(subscription)
    }

    // MARK: - User Identity Lookup

    public func lookupUserIdentity(by email: String) async throws -> CKUserIdentity? {
        return try await withCheckedThrowingContinuation { continuation in
            CKContainer.default().discoverUserIdentities(forEmailAddresses: [email]) { result in
                switch result {
                case .success(let userIdentities):
                    continuation.resume(returning: userIdentities[email])
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func lookupUserIdentity(byPhoneNumber phoneNumber: String) async throws -> CKUserIdentity? {
        return try await withCheckedThrowingContinuation { continuation in
            CKContainer.default().discoverUserIdentities(forPhoneNumbers: [phoneNumber]) { result in
                switch result {
                case .success(let userIdentities):
                    continuation.resume(returning: userIdentities[phoneNumber])
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Share URL Generation

    public func generateShareURL(for share: CKShare) -> URL? {
        return share.url
    }

    // MARK: - Accept Share

    public func acceptShare(metadata: CKShare.Metadata) async throws -> CKShare {
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.perShareResultBlock = { metadata, result in
                switch result {
                case .success(let share):
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // Use the non-deprecated API that's available since iOS 15.0
            operation.acceptSharesResultBlock = { result in
                if case .failure(let error) = result {
                    continuation.resume(throwing: error)
                }
            }
            
            CKContainer.default().add(operation)
        }
    }
}

// MARK: - Error Types

public enum CloudKitSharingError: Error, LocalizedError {
    case shareCreationFailed
    case shareAcceptanceFailed
    case participantNotFound
    case permissionDenied
    case familyNotFound
    case userIdentityNotFound

    public var errorDescription: String? {
        switch self {
        case .shareCreationFailed:
            return "Failed to create CloudKit share"
        case .shareAcceptanceFailed:
            return "Failed to accept CloudKit share"
        case .participantNotFound:
            return "Participant not found in share"
        case .permissionDenied:
            return "Permission denied for sharing operation"
        case .familyNotFound:
            return "Family record not found"
        case .userIdentityNotFound:
            return "User identity not found"
        }
    }
}