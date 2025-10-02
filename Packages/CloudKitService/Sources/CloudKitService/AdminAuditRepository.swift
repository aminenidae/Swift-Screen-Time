import CloudKit
import Foundation
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public final class CloudKitAdminAuditRepository: AdminAuditRepository {

    // MARK: - Properties

    private let database: CKDatabase
    private let adminActionRecordType = "AdminAction"

    // MARK: - Initialization

    public init(database: CKDatabase = CKContainer.default().privateCloudDatabase) {
        self.database = database
    }

    // MARK: - AdminAuditRepository Implementation

    public func createAdminAction(_ action: AdminAction) async throws -> AdminAction {
        let record = try adminActionToRecord(action)
        let savedRecord = try await database.save(record)
        return try recordToAdminAction(savedRecord)
    }

    public func fetchAllActions() async throws -> [AdminAction] {
        let predicate = NSPredicate(value: true) // Fetch all
        let query = CKQuery(recordType: adminActionRecordType, predicate: predicate)

        // Sort by timestamp descending
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var actions: [AdminAction] = []

        for result in matchResults {

            switch result.1 {
            case .success(let record):
                let action = try recordToAdminAction(record)
                actions.append(action)
            case .failure(let error):
                print("Failed to fetch admin action record: \(error)")
                continue
            }
        }

        return actions
    }

    public func fetchActionsForFamily(_ familyID: String) async throws -> [AdminAction] {
        let predicate = NSPredicate(format: "targetFamilyID == %@", familyID)
        let query = CKQuery(recordType: adminActionRecordType, predicate: predicate)

        // Sort by timestamp descending
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var actions: [AdminAction] = []

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                let action = try recordToAdminAction(record)
                actions.append(action)
            case .failure(let error):
                print("Failed to fetch admin action record: \(error)")
                continue
            }
        }

        return actions
    }

    public func fetchActionsByAdmin(_ adminUserID: String) async throws -> [AdminAction] {
        let predicate = NSPredicate(format: "adminUserID == %@", adminUserID)
        let query = CKQuery(recordType: adminActionRecordType, predicate: predicate)

        // Sort by timestamp descending
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var actions: [AdminAction] = []

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                let action = try recordToAdminAction(record)
                actions.append(action)
            case .failure(let error):
                print("Failed to fetch admin action record: \(error)")
                continue
            }
        }

        return actions
    }

    // MARK: - Helper Methods

    private func adminActionToRecord(_ action: AdminAction) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: action.id)
        let record = CKRecord(recordType: adminActionRecordType, recordID: recordID)

        record["adminUserID"] = action.adminUserID
        record["action"] = action.action.rawValue
        record["targetFamilyID"] = action.targetFamilyID
        record["reason"] = action.reason
        record["timestamp"] = action.timestamp

        // Store metadata as JSON string
        if !action.metadata.isEmpty,
           let metadataData = try? JSONSerialization.data(withJSONObject: action.metadata),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            record["metadata"] = metadataString
        }

        // Add indices for efficient querying
        record["adminUserID_timestamp"] = "\(action.adminUserID)_\(Int(action.timestamp.timeIntervalSince1970))"
        record["targetFamilyID_timestamp"] = "\(action.targetFamilyID)_\(Int(action.timestamp.timeIntervalSince1970))"
        record["action_timestamp"] = "\(action.action.rawValue)_\(Int(action.timestamp.timeIntervalSince1970))"

        return record
    }

    private func recordToAdminAction(_ record: CKRecord) throws -> AdminAction {
        guard let adminUserID = record["adminUserID"] as? String,
              let actionString = record["action"] as? String,
              let action = AdminActionType(rawValue: actionString),
              let targetFamilyID = record["targetFamilyID"] as? String,
              let reason = record["reason"] as? String,
              let timestamp = record["timestamp"] as? Date else {
            throw CloudKitError.invalidRecord("Missing required fields in AdminAction record")
        }

        // Parse metadata
        var metadata: [String: String] = [:]
        if let metadataString = record["metadata"] as? String,
           let metadataData = metadataString.data(using: .utf8),
           let parsedMetadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: String] {
            metadata = parsedMetadata
        }

        return AdminAction(
            id: record.recordID.recordName,
            adminUserID: adminUserID,
            targetFamilyID: targetFamilyID,
            action: action,
            reason: reason,
            timestamp: timestamp,
            metadata: metadata
        )
    }
}