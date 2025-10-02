import CloudKit
import Foundation
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public final class CloudKitValidationAuditRepository: ValidationAuditRepository {

    // MARK: - Properties

    private let database: CKDatabase
    private let auditLogRecordType = "ValidationAuditLog"

    // MARK: - Initialization

    public init(database: CKDatabase = CKContainer.default().privateCloudDatabase) {
        self.database = database
    }

    // MARK: - ValidationAuditRepository Implementation

    public func createAuditLog(_ log: ValidationAuditLog) async throws -> ValidationAuditLog {
        let record = try auditLogToRecord(log)
        let savedRecord = try await database.save(record)
        return try recordToAuditLog(savedRecord)
    }

    public func fetchAuditLogs(
        for familyID: String,
        eventType: ValidationEventType? = nil
    ) async throws -> [ValidationAuditLog] {

        var predicateFormat = "familyID == %@"
        var arguments: [Any] = [familyID]

        if let eventType = eventType {
            predicateFormat += " AND eventType == %@"
            arguments.append(eventType.rawValue)
        }

        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        let query = CKQuery(recordType: auditLogRecordType, predicate: predicate)

        // Sort by timestamp descending
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var auditLogs: [ValidationAuditLog] = []

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                let auditLog = try recordToAuditLog(record)
                auditLogs.append(auditLog)
            case .failure(let error):
                print("Failed to fetch audit log record: \(error)")
                continue
            }
        }

        return auditLogs
    }

    public func fetchAuditLogs(
        for familyID: String,
        since date: Date
    ) async throws -> [ValidationAuditLog] {
        return try await fetchAuditLogs(for: familyID, since: date, limit: 100)
    }

    public func fetchAuditLogs(
        for familyID: String,
        since date: Date,
        limit: Int = 100
    ) async throws -> [ValidationAuditLog] {

        let predicate = NSPredicate(
            format: "familyID == %@ AND timestamp >= %@",
            familyID,
            date as NSDate
        )
        let query = CKQuery(recordType: auditLogRecordType, predicate: predicate)

        // Sort by timestamp descending
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var auditLogs: [ValidationAuditLog] = []
        var count = 0

        for result in matchResults {
            guard count < limit else { break }

            switch result.1 {
            case .success(let record):
                let auditLog = try recordToAuditLog(record)
                auditLogs.append(auditLog)
                count += 1
            case .failure(let error):
                print("Failed to fetch audit log record: \(error)")
                continue
            }
        }

        return auditLogs
    }

    public func fetchAuditStats(for familyID: String, days: Int = 30) async throws -> AuditStats {
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let logs = try await fetchAuditLogs(for: familyID, since: since)

        var stats = AuditStats()

        for log in logs {
            stats.totalEvents += 1

            switch log.eventType {
            case .receiptValidated:
                stats.validationCount += 1
            case .fraudDetected:
                stats.fraudEventCount += 1
            case .entitlementCreated:
                stats.entitlementCreatedCount += 1
            case .entitlementUpdated:
                stats.entitlementUpdatedCount += 1
            case .entitlementExpired:
                stats.entitlementExpiredCount += 1
            case .gracePeriodStarted:
                stats.gracePeriodStartedCount += 1
            case .gracePeriodEnded:
                stats.gracePeriodEndedCount += 1
            case .validationFailed:
                stats.validationFailedCount += 1
            }
        }

        return stats
    }

    // MARK: - Helper Methods

    private func auditLogToRecord(_ log: ValidationAuditLog) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: log.id)
        let record = CKRecord(recordType: auditLogRecordType, recordID: recordID)

        record["familyID"] = log.familyID
        record["productID"] = log.productID
        record["eventType"] = log.eventType.rawValue
        record["timestamp"] = log.timestamp

        if let transactionID = log.transactionID {
            record["transactionID"] = transactionID
        }

        // Store metadata as JSON string
        if !log.metadata.isEmpty,
           let metadataData = try? JSONSerialization.data(withJSONObject: log.metadata),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            record["metadata"] = metadataString
        }

        // Add indices for efficient querying
        record["familyID_timestamp"] = "\(log.familyID)_\(Int(log.timestamp.timeIntervalSince1970))"
        record["familyID_eventType"] = "\(log.familyID)_\(log.eventType.rawValue)"

        return record
    }

    private func recordToAuditLog(_ record: CKRecord) throws -> ValidationAuditLog {
        guard let familyID = record["familyID"] as? String,
              let productID = record["productID"] as? String,
              let eventTypeString = record["eventType"] as? String,
              let eventType = ValidationEventType(rawValue: eventTypeString),
              let timestamp = record["timestamp"] as? Date else {
            throw CloudKitError.invalidRecord("Missing required fields in ValidationAuditLog record")
        }

        let transactionID = record["transactionID"] as? String

        // Parse metadata
        var metadata: [String: String] = [:]
        if let metadataString = record["metadata"] as? String,
           let metadataData = metadataString.data(using: .utf8),
           let parsedMetadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: String] {
            metadata = parsedMetadata
        }

        return ValidationAuditLog(
            id: record.recordID.recordName,
            familyID: familyID,
            transactionID: transactionID,
            productID: productID,
            eventType: eventType,
            timestamp: timestamp,
            metadata: metadata
        )
    }
}

// MARK: - Supporting Types

public struct AuditStats {
    public var totalEvents: Int = 0
    public var validationCount: Int = 0
    public var fraudEventCount: Int = 0
    public var entitlementCreatedCount: Int = 0
    public var entitlementUpdatedCount: Int = 0
    public var entitlementExpiredCount: Int = 0
    public var gracePeriodStartedCount: Int = 0
    public var gracePeriodEndedCount: Int = 0
    public var validationFailedCount: Int = 0

    public init() {}

    public var fraudRate: Double {
        guard totalEvents > 0 else { return 0.0 }
        return Double(fraudEventCount) / Double(totalEvents)
    }

    public var validationSuccessRate: Double {
        let totalValidationAttempts = validationCount + validationFailedCount
        guard totalValidationAttempts > 0 else { return 1.0 }
        return Double(validationCount) / Double(totalValidationAttempts)
    }
}