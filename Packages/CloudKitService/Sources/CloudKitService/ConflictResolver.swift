import Foundation
import SharedModels

/// Service responsible for resolving conflicts in family-related data
@available(iOS 15.0, macOS 12.0, *)
public class ConflictResolver {
    private let conflictMetadataRepository: ConflictMetadataRepository
    
    public init(
        conflictMetadataRepository: ConflictMetadataRepository
    ) {
        self.conflictMetadataRepository = conflictMetadataRepository
    }
    
    /// Resolves a conflict using the last-write-wins strategy
    /// - Parameters:
    ///   - conflict: The conflict metadata
    ///   - changes: Array of conflicting changes
    /// - Returns: The resolved change
    public func resolveWithLastWriteWins(
        conflict: ConflictMetadata,
        changes: [ConflictChange]
    ) -> ConflictChange? {
        // Sort changes by timestamp, newest first
        let sortedChanges = changes.sorted { $0.timestamp > $1.timestamp }
        return sortedChanges.first
    }
    
    /// Attempts to merge non-conflicting changes
    /// - Parameters:
    ///   - conflict: The conflict metadata
    ///   - changes: Array of conflicting changes
    /// - Returns: Merged change if possible, nil if conflicts cannot be merged
    public func mergeChanges(
        conflict: ConflictMetadata,
        changes: [ConflictChange]
    ) -> ConflictChange? {
        // Group field changes by field name
        var fieldChanges: [String: [FieldChange]] = [:]
        
        for change in changes {
            for fieldChange in change.fieldChanges {
                if fieldChanges[fieldChange.fieldName] == nil {
                    fieldChanges[fieldChange.fieldName] = []
                }
                fieldChanges[fieldChange.fieldName]?.append(fieldChange)
            }
        }
        
        // Check for conflicts in field changes
        var mergedFieldChanges: [FieldChange] = []
        var hasConflicts = false
        
        for (_, changes) in fieldChanges {
            // If only one change to this field, it can be merged
            if changes.count == 1 {
                mergedFieldChanges.append(changes[0])
            } else {
                // Check if all changes to this field are the same
                let firstChange = changes[0]
                let allSame = changes.allSatisfy {
                    $0.oldValue == firstChange.oldValue && $0.newValue == firstChange.newValue
                }
                
                if allSame {
                    mergedFieldChanges.append(firstChange)
                } else {
                    // Conflicting changes to the same field
                    hasConflicts = true
                    break
                }
            }
        }
        
        // If no conflicts, create merged change
        if !hasConflicts, let firstChange = changes.first {
            let mergedChange = ConflictChange(
                userID: firstChange.userID, // This would need to be determined
                changeType: firstChange.changeType,
                fieldChanges: mergedFieldChanges,
                timestamp: Date(),
                deviceInfo: "Merged"
            )
            return mergedChange
        }
        
        return nil
    }
    
    /// Stores conflict metadata for auditing purposes
    /// - Parameter metadata: The conflict metadata to store
    public func storeConflictMetadata(_ metadata: ConflictMetadata) async throws {
        _ = try await conflictMetadataRepository.createConflictMetadata(metadata)
    }
}