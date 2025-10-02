import Foundation
import CloudKit
import SharedModels

/// CloudKit repository for conflict metadata
@available(iOS 15.0, macOS 12.0, *)
public class CloudKitConflictMetadataRepository: ConflictMetadataRepository {
    private let database: CKDatabase
    private let zoneID: CKRecordZone.ID
    
    public init(
        database: CKDatabase = CKContainer.default().privateCloudDatabase,
        zoneID: CKRecordZone.ID = CKRecordZone.default().zoneID
    ) {
        self.database = database
        self.zoneID = zoneID
    }
    
    public func createConflictMetadata(_ metadata: ConflictMetadata) async throws -> ConflictMetadata {
        let record = try conflictMetadataToRecord(metadata)
        let savedRecord = try await database.save(record)
        return try recordToConflictMetadata(savedRecord)
    }
    
    public func fetchConflictMetadata(id: String) async throws -> ConflictMetadata? {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = try await database.record(for: recordID)
        return try recordToConflictMetadata(record)
    }
    
    public func fetchConflicts(for familyID: String) async throws -> [ConflictMetadata] {
        let predicate = NSPredicate(format: "familyID == %@", familyID)
        let query = CKQuery(recordType: "ConflictMetadata", predicate: predicate)
        let records = try await database.records(matching: query).matchResults.map { try $0.1.get() }
        return try records.map { try recordToConflictMetadata($0) }
    }
    
    public func updateConflictMetadata(_ metadata: ConflictMetadata) async throws -> ConflictMetadata {
        // In CloudKit, updates are done by saving the record again
        return try await createConflictMetadata(metadata)
    }
    
    public func deleteConflictMetadata(id: String) async throws {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        try await database.deleteRecord(withID: recordID)
    }
    
    // MARK: - Private Methods
    
    private func conflictMetadataToRecord(_ metadata: ConflictMetadata) throws -> CKRecord {
        let record = CKRecord(recordType: "ConflictMetadata", recordID: CKRecord.ID(recordName: metadata.id, zoneID: zoneID))
        
        record["familyID"] = metadata.familyID
        record["recordType"] = metadata.recordType
        record["recordID"] = metadata.recordID
        record["resolutionStrategy"] = metadata.resolutionStrategy.rawValue
        record["resolvedBy"] = metadata.resolvedBy
        record["resolvedAt"] = metadata.resolvedAt
        // Convert metadata dictionary to JSON string for CKRecord storage
        if let metadataData = try? JSONSerialization.data(withJSONObject: metadata.metadata, options: []),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            record["metadata"] = metadataString
        }
        
        // Convert conflicting changes to JSON data
        let changesData = try JSONEncoder().encode(metadata.conflictingChanges)
        record["conflictingChanges"] = changesData
        
        return record
    }
    
    /// Parse metadata string back to dictionary
    private func parseMetadata(from metadataString: String?) -> [String: String] {
        guard let metadataString = metadataString,
              let metadataData = metadataString.data(using: .utf8),
              let metadataDict = try? JSONSerialization.jsonObject(with: metadataData) as? [String: String] else {
            return [:]
        }
        return metadataDict
    }
    
    private func recordToConflictMetadata(_ record: CKRecord) throws -> ConflictMetadata {
        guard let familyID = record["familyID"] as? String,
              let recordType = record["recordType"] as? String,
              let recordID = record["recordID"] as? String,
              let strategyRaw = record["resolutionStrategy"] as? String,
              let strategy = ResolutionStrategy(rawValue: strategyRaw),
              let changesData = record["conflictingChanges"] as? Data else {
            throw ConflictRepositoryError.invalidRecord
        }
        
        let conflictingChanges = try JSONDecoder().decode([ConflictChange].self, from: changesData)
        
        return ConflictMetadata(
            id: record.recordID.recordName,
            familyID: familyID,
            recordType: recordType,
            recordID: recordID,
            conflictingChanges: conflictingChanges,
            resolutionStrategy: strategy,
            resolvedBy: record["resolvedBy"] as? String,
            resolvedAt: record["resolvedAt"] as? Date,
            metadata: self.parseMetadata(from: record["metadata"] as? String)
        )
    }
}

/// Custom error types for conflict repository
public enum ConflictRepositoryError: Error, LocalizedError {
    case invalidRecord
    
    public var errorDescription: String? {
        switch self {
        case .invalidRecord:
            return "Invalid conflict metadata record"
        }
    }
}