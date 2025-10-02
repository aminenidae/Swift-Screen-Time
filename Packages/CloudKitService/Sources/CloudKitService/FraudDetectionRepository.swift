import CloudKit
import Foundation
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public final class CloudKitFraudDetectionRepository: FraudDetectionRepository {

    // MARK: - Properties

    private let database: CKDatabase
    private let fraudEventRecordType = "FraudDetectionEvent"

    // MARK: - Initialization

    public init(database: CKDatabase = CKContainer.default().privateCloudDatabase) {
        self.database = database
    }

    // MARK: - FraudDetectionRepository Implementation

    public func createFraudEvent(_ event: FraudDetectionEvent) async throws -> FraudDetectionEvent {
        let record = try fraudEventToRecord(event)
        let savedRecord = try await database.save(record)
        return try recordToFraudEvent(savedRecord)
    }

    public func fetchFraudEvents(for familyID: String) async throws -> [FraudDetectionEvent] {
        return try await fetchFraudEvents(for: familyID, since: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
    }

    public func fetchHighRiskEvents() async throws -> [FraudDetectionEvent] {
        let predicate = NSPredicate(format: "severity == %@", FraudSeverity.high.rawValue)
        let query = CKQuery(recordType: fraudEventRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var events: [FraudDetectionEvent] = []
        for result in matchResults {
            switch result.1 {
            case .success(let record):
                let event = try recordToFraudEvent(record)
                events.append(event)
            case .failure(let error):
                print("Failed to fetch high risk fraud event: \(error)")
                continue
            }
        }

        return events
    }

    public func fetchFraudEvents(for familyID: String, since date: Date) async throws -> [FraudDetectionEvent] {
        let predicate = NSPredicate(
            format: "familyID == %@ AND timestamp >= %@",
            familyID,
            date as NSDate
        )
        let query = CKQuery(recordType: fraudEventRecordType, predicate: predicate)

        // Sort by timestamp descending
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var events: [FraudDetectionEvent] = []

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                let event = try recordToFraudEvent(record)
                events.append(event)
            case .failure(let error):
                print("Failed to fetch fraud event record: \(error)")
                continue
            }
        }

        return events
    }

    public func findEntitlementsByTransactionID(_ transactionID: String) async throws -> [SubscriptionEntitlement] {
        // This method needs to query the SubscriptionEntitlement records
        let predicate = NSPredicate(format: "transactionID == %@", transactionID)
        let query = CKQuery(recordType: "SubscriptionEntitlement", predicate: predicate)

        let (matchResults, _) = try await database.records(matching: query)

        var entitlements: [SubscriptionEntitlement] = []

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                // Convert CloudKit record to SubscriptionEntitlement
                let entitlement = try recordToSubscriptionEntitlement(record)
                entitlements.append(entitlement)
            case .failure(let error):
                print("Failed to fetch entitlement record: \(error)")
                continue
            }
        }

        return entitlements
    }

    // MARK: - Helper Methods

    private func fraudEventToRecord(_ event: FraudDetectionEvent) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: event.id)
        let record = CKRecord(recordType: fraudEventRecordType, recordID: recordID)

        record["familyID"] = event.familyID
        record["detectionType"] = event.detectionType.rawValue
        record["severity"] = event.severity.rawValue
        record["timestamp"] = event.timestamp

        // Store device info as JSON string
        if let deviceInfoData = try? JSONSerialization.data(withJSONObject: event.deviceInfo),
           let deviceInfoString = String(data: deviceInfoData, encoding: .utf8) {
            record["deviceInfo"] = deviceInfoString
        }

        // Store transaction info as JSON string
        if let transactionInfo = event.transactionInfo,
           let transactionInfoData = try? JSONSerialization.data(withJSONObject: transactionInfo),
           let transactionInfoString = String(data: transactionInfoData, encoding: .utf8) {
            record["transactionInfo"] = transactionInfoString
        }

        // Store metadata as JSON string
        if !event.metadata.isEmpty,
           let metadataData = try? JSONSerialization.data(withJSONObject: event.metadata),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            record["metadata"] = metadataString
        }

        // Add indices for efficient querying
        record["familyID_timestamp"] = "\(event.familyID)_\(Int(event.timestamp.timeIntervalSince1970))"
        record["familyID_detectionType"] = "\(event.familyID)_\(event.detectionType.rawValue)"

        return record
    }

    private func recordToFraudEvent(_ record: CKRecord) throws -> FraudDetectionEvent {
        guard let familyID = record["familyID"] as? String,
              let detectionTypeString = record["detectionType"] as? String,
              let detectionType = FraudDetectionType(rawValue: detectionTypeString),
              let severityString = record["severity"] as? String,
              let severity = FraudSeverity(rawValue: severityString),
              let timestamp = record["timestamp"] as? Date else {
            throw CloudKitError.invalidRecord("Missing required fields in FraudDetectionEvent record")
        }

        // Parse device info
        var deviceInfo: [String: String] = [:]
        if let deviceInfoString = record["deviceInfo"] as? String,
           let deviceInfoData = deviceInfoString.data(using: .utf8),
           let parsedDeviceInfo = try? JSONSerialization.jsonObject(with: deviceInfoData) as? [String: String] {
            deviceInfo = parsedDeviceInfo
        }

        // Parse transaction info
        var transactionInfo: [String: String]?
        if let transactionInfoString = record["transactionInfo"] as? String,
           let transactionInfoData = transactionInfoString.data(using: .utf8),
           let parsedTransactionInfo = try? JSONSerialization.jsonObject(with: transactionInfoData) as? [String: String] {
            transactionInfo = parsedTransactionInfo
        }

        // Parse metadata
        var metadata: [String: String] = [:]
        if let metadataString = record["metadata"] as? String,
           let metadataData = metadataString.data(using: .utf8),
           let parsedMetadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: String] {
            metadata = parsedMetadata
        }

        return FraudDetectionEvent(
            id: record.recordID.recordName,
            familyID: familyID,
            detectionType: detectionType,
            severity: severity,
            timestamp: timestamp,
            deviceInfo: deviceInfo,
            transactionInfo: transactionInfo,
            metadata: metadata
        )
    }

    private func recordToSubscriptionEntitlement(_ record: CKRecord) throws -> SubscriptionEntitlement {
        // This is a simplified version - would need full implementation
        guard let familyID = record["familyID"] as? String,
              let subscriptionTierString = record["subscriptionTier"] as? String,
              let subscriptionTier = SubscriptionTier(rawValue: subscriptionTierString),
              let receiptData = record["receiptData"] as? String,
              let originalTransactionID = record["originalTransactionID"] as? String,
              let transactionID = record["transactionID"] as? String,
              let purchaseDate = record["purchaseDate"] as? Date,
              let expirationDate = record["expirationDate"] as? Date,
              let isActiveInt = record["isActive"] as? Int,
              let lastValidatedAt = record["lastValidatedAt"] as? Date else {
            throw CloudKitError.invalidRecord("Missing required fields in SubscriptionEntitlement record")
        }

        return SubscriptionEntitlement(
            id: record.recordID.recordName,
            familyID: familyID,
            subscriptionTier: subscriptionTier,
            receiptData: receiptData,
            originalTransactionID: originalTransactionID,
            transactionID: transactionID,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            isActive: isActiveInt == 1,
            lastValidatedAt: lastValidatedAt
        )
    }
}