import Foundation
import CloudKit
import SharedModels

/// Handler for CloudKit conflict resolution
@available(iOS 15.0, macOS 12.0, *)
public class CloudKitConflictHandler {
    private let conflictResolver: ConflictResolver
    private let conflictDetector: ConflictDetector
    
    public init(
        conflictResolver: ConflictResolver,
        conflictDetector: ConflictDetector
    ) {
        self.conflictResolver = conflictResolver
        self.conflictDetector = conflictDetector
    }
    
    /// Handles conflicts detected by CloudKit
    /// - Parameters:
    ///   - conflicts: Array of CKRecord conflicts
    ///   - recordType: The type of record with conflicts
    /// - Returns: Resolved CKRecord
    public func handleConflicts(
        _ conflicts: [CKRecord],
        recordType: String
    ) async throws -> CKRecord {
        // For now, we'll use a simple last-write-wins strategy
        // In a real implementation, this would be more sophisticated
        
        guard let winningRecord = conflicts.first else {
            throw ConflictError.noRecordsToResolve
        }
        
        // Create conflict metadata for auditing
        let conflictMetadata = ConflictMetadata(
            familyID: "unknown", // This would be extracted from the record
            recordType: recordType,
            recordID: winningRecord.recordID.recordName,
            conflictingChanges: [], // This would be populated with actual changes
            resolutionStrategy: .automaticLastWriteWins,
            metadata: [
                "conflictCount": "\(conflicts.count)",
                "resolutionTime": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        try await conflictResolver.storeConflictMetadata(conflictMetadata)
        
        return winningRecord
    }
    
    /// Converts CloudKit records to conflict change models
    /// - Parameter records: Array of CKRecords
    /// - Returns: Array of ConflictChange models
    public func convertRecordsToConflictChanges(_ records: [CKRecord]) -> [ConflictChange] {
        var changes: [ConflictChange] = []
        
        for record in records {
            // Extract user ID from record metadata
            let userID = record.creatorUserRecordID?.recordName ?? "unknown"
            
            // Extract modification date
            let modificationDate = record.modificationDate ?? Date()
            
            // Extract field changes (simplified for this example)
            var fieldChanges: [FieldChange] = []
            for key in record.allKeys() {
                let value = record.value(forKey: key)
                let stringValue = value.map { "\($0)" } ?? "nil"
                fieldChanges.append(FieldChange(
                    fieldName: key,
                    oldValue: nil, // Would need previous version to populate this
                    newValue: stringValue
                ))
            }
            
            let change = ConflictChange(
                userID: userID,
                changeType: .update, // Would be determined by record state
                fieldChanges: fieldChanges,
                timestamp: modificationDate,
                deviceInfo: "CloudKit Record"
            )
            
            changes.append(change)
        }
        
        return changes
    }
}

/// Custom error types for conflict handling
public enum ConflictError: Error, LocalizedError {
    case noRecordsToResolve
    case invalidConflictData
    
    public var errorDescription: String? {
        switch self {
        case .noRecordsToResolve:
            return "No records provided to resolve conflict"
        case .invalidConflictData:
            return "Invalid conflict data provided"
        }
    }
}