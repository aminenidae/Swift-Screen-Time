import Foundation
import SharedModels
import CloudKit

@available(iOS 15.0, macOS 12.0, *)
public class CloudKitParentActivityRepository: SharedModels.ParentActivityRepository {

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    private let recordType = "ParentActivity"
    private let maxFetchLimit = 100

    public init(container: CKContainer = CKContainer.default()) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
    }

    /// Creates a new parent activity in CloudKit
    public func createActivity(_ activity: ParentActivity) async throws -> ParentActivity {
        let record = try createCKRecord(from: activity)

        let savedRecord = try await privateDatabase.save(record)
        return try createParentActivity(from: savedRecord)
    }

    /// Fetches a specific parent activity by ID
    public func fetchActivity(id: UUID) async throws -> ParentActivity? {
        let recordID = CKRecord.ID(recordName: id.uuidString)

        do {
            let record = try await privateDatabase.record(for: recordID)
            return try createParentActivity(from: record)
        } catch CKError.unknownItem {
            return nil
        }
    }

    /// Fetches parent activities for a family, optionally limited
    public func fetchActivities(for familyID: UUID, limit: Int?) async throws -> [ParentActivity] {
        // Apply 30-day limit for privacy and performance
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let familyPredicate = NSPredicate(format: "familyID == %@", familyID.uuidString)
        let datePredicate = NSPredicate(format: "timestamp >= %@", thirtyDaysAgo as NSDate)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [familyPredicate, datePredicate])

        let query = CKQuery(recordType: recordType, predicate: compound)

        // Sort by timestamp descending (newest first) - optimized with CloudKit index
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let effectiveLimit = min(limit ?? maxFetchLimit, maxFetchLimit)

        let (matchResults, _) = try await privateDatabase.records(
            matching: query,
            resultsLimit: effectiveLimit
        )

        var activities: [ParentActivity] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let activity = try? createParentActivity(from: record) {
                    // Additional privacy check: ensure activity is from family members only
                    if await isFromFamilyMember(activity, familyID: familyID) {
                        activities.append(activity)
                    }
                }
            case .failure:
                continue // Skip failed records
            }
        }

        return activities
    }

    /// Fetches parent activities since a specific date (with privacy and performance limits)
    public func fetchActivities(for familyID: UUID, since date: Date) async throws -> [ParentActivity] {
        // Enforce 30-day maximum lookback for privacy
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let effectiveDate = max(date, thirtyDaysAgo)

        let familyPredicate = NSPredicate(format: "familyID == %@", familyID.uuidString)
        let datePredicate = NSPredicate(format: "timestamp >= %@", effectiveDate as NSDate)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [familyPredicate, datePredicate])

        let query = CKQuery(recordType: recordType, predicate: compound)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await privateDatabase.records(
            matching: query,
            resultsLimit: maxFetchLimit
        )

        var activities: [ParentActivity] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let activity = try? createParentActivity(from: record) {
                    // Privacy check: ensure activity is from family members only
                    if await isFromFamilyMember(activity, familyID: familyID) {
                        activities.append(activity)
                    }
                }
            case .failure:
                continue
            }
        }

        return activities
    }

    /// Fetches parent activities within a date range
    public func fetchActivities(for familyID: UUID, dateRange: DateRange) async throws -> [ParentActivity] {
        let familyPredicate = NSPredicate(format: "familyID == %@", familyID.uuidString)
        let startPredicate = NSPredicate(format: "timestamp >= %@", dateRange.start as NSDate)
        let endPredicate = NSPredicate(format: "timestamp <= %@", dateRange.end as NSDate)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [familyPredicate, startPredicate, endPredicate])

        let query = CKQuery(recordType: recordType, predicate: compound)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await privateDatabase.records(
            matching: query,
            resultsLimit: maxFetchLimit
        )

        var activities: [ParentActivity] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let activity = try? createParentActivity(from: record) {
                    activities.append(activity)
                }
            case .failure:
                continue
            }
        }

        return activities
    }

    /// Deletes a parent activity from CloudKit
    public func deleteActivity(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        _ = try await privateDatabase.deleteRecord(withID: recordID)
    }

    /// Deletes old activities (older than specified date)
    public func deleteOldActivities(olderThan date: Date) async throws {
        let predicate = NSPredicate(format: "timestamp < %@", date as NSDate)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        let (matchResults, _) = try await privateDatabase.records(
            matching: query,
            resultsLimit: maxFetchLimit
        )

        var recordIDsToDelete: [CKRecord.ID] = []
        for (recordID, result) in matchResults {
            switch result {
            case .success:
                recordIDsToDelete.append(recordID)
            case .failure:
                continue
            }
        }

        if !recordIDsToDelete.isEmpty {
            // Delete records in batches
            for batchRecordIDs in recordIDsToDelete.chunked(into: 50) {
                let (_, deleteResults) = try await privateDatabase.modifyRecords(
                    saving: [],
                    deleting: Array(batchRecordIDs)
                )

                // Check for any deletion errors
                for (recordID, result) in deleteResults {
                    switch result {
                    case .success:
                        continue
                    case .failure(let error):
                        print("Failed to delete record \(recordID): \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Private Helper Methods

    private func createCKRecord(from activity: ParentActivity) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: activity.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["familyID"] = activity.familyID.uuidString
        record["triggeringUserID"] = activity.triggeringUserID
        record["activityType"] = activity.activityType.rawValue
        record["targetEntity"] = activity.targetEntity
        record["targetEntityID"] = activity.targetEntityID.uuidString
        record["timestamp"] = activity.timestamp
        record["deviceID"] = activity.deviceID

        // Store changes as JSON data
        let changesData = try JSONEncoder().encode(activity.changes)
        record["changes"] = changesData

        return record
    }

    private func createParentActivity(from record: CKRecord) throws -> ParentActivity {
        guard
            let familyIDString = record["familyID"] as? String,
            let familyID = UUID(uuidString: familyIDString),
            let triggeringUserID = record["triggeringUserID"] as? String,
            let activityTypeRaw = record["activityType"] as? String,
            let activityType = ParentActivityType(rawValue: activityTypeRaw),
            let targetEntity = record["targetEntity"] as? String,
            let targetEntityIDString = record["targetEntityID"] as? String,
            let targetEntityID = UUID(uuidString: targetEntityIDString),
            let timestamp = record["timestamp"] as? Date,
            let changesData = record["changes"] as? Data
        else {
            throw ParentActivityCloudKitError.invalidRecord
        }

        let changes = try JSONDecoder().decode(CodableDictionary.self, from: changesData)
        let deviceID = record["deviceID"] as? String

        guard let activityID = UUID(uuidString: record.recordID.recordName) else {
            throw ParentActivityCloudKitError.invalidRecord
        }

        return ParentActivity(
            id: activityID,
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: activityType,
            targetEntity: targetEntity,
            targetEntityID: targetEntityID,
            changes: changes,
            timestamp: timestamp,
            deviceID: deviceID
        )
    }

    /// Privacy check: ensures the activity is from a verified family member
    private func isFromFamilyMember(_ activity: ParentActivity, familyID: UUID) async -> Bool {
        // TODO: Implement actual family membership verification
        // This would check against the Family model's sharedWithUserIDs + ownerUserID
        // For now, we'll do basic validation

        // Ensure the activity's familyID matches the requested familyID
        guard activity.familyID == familyID else {
            return false
        }

        // Ensure the triggering user ID is not empty or suspicious
        guard !activity.triggeringUserID.isEmpty,
              activity.triggeringUserID.count >= 5, // Basic length check
              !activity.triggeringUserID.contains(" ") else { // No spaces in user IDs
            return false
        }

        return true
    }

    /// Creates optimal CloudKit indexes for performance
    public func configureCloudKitIndexes() async throws {
        // Note: CloudKit indexes are typically configured via CloudKit Dashboard
        // This method documents the required indexes for optimal performance

        /*
         Required CloudKit Indexes for ParentActivity record type:

         1. familyID + timestamp (DESC) - For fetching recent activities by family
         2. familyID + triggeringUserID + timestamp (DESC) - For filtering activities
         3. timestamp (DESC) - For general activity queries
         4. familyID + activityType + timestamp (DESC) - For filtering by activity type

         These indexes should be configured in CloudKit Dashboard for optimal query performance.
         */

        print("CloudKit indexes should be configured in CloudKit Dashboard:")
        print("1. familyID + timestamp (DESC)")
        print("2. familyID + triggeringUserID + timestamp (DESC)")
        print("3. timestamp (DESC)")
        print("4. familyID + activityType + timestamp (DESC)")
    }
}

// MARK: - CloudKit Error Extensions

enum ParentActivityCloudKitError: Error {
    case invalidRecord
    case encodingError
    case decodingError

    var localizedDescription: String {
        switch self {
        case .invalidRecord:
            return "Invalid CloudKit record format"
        case .encodingError:
            return "Failed to encode data for CloudKit"
        case .decodingError:
            return "Failed to decode data from CloudKit"
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}