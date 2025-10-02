import CloudKit
import Foundation
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public final class CloudKitSubscriptionEntitlementRepository: SubscriptionEntitlementRepository {

    // MARK: - Properties

    private let database: CKDatabase
    private let recordType = "SubscriptionEntitlement"

    // MARK: - Initialization

    public init(database: CKDatabase = CKContainer.default().privateCloudDatabase) {
        self.database = database
    }

    // MARK: - SubscriptionEntitlementRepository Implementation

    public func createEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        let record = try entitlementToRecord(entitlement)
        let savedRecord = try await database.save(record)
        return try recordToEntitlement(savedRecord)
    }

    public func fetchEntitlement(id: String) async throws -> SubscriptionEntitlement? {
        let recordID = CKRecord.ID(recordName: id)

        do {
            let record = try await database.record(for: recordID)
            return try recordToEntitlement(record)
        } catch let error as CKError {
            if error.code == .unknownItem {
                return nil
            }
            throw error
        }
    }

    public func fetchEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        let predicate = NSPredicate(format: "familyID == %@ AND isActive == 1", familyID)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        // Sort by lastValidatedAt descending to get the most recent active entitlement
        query.sortDescriptors = [NSSortDescriptor(key: "lastValidatedAt", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                return try recordToEntitlement(record)
            case .failure(let error):
                print("Failed to fetch entitlement record: \(error)")
                continue
            }
        }

        return nil
    }

    public func fetchEntitlements(for familyID: String) async throws -> [SubscriptionEntitlement] {
        let predicate = NSPredicate(format: "familyID == %@", familyID)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        // Sort by lastValidatedAt descending
        query.sortDescriptors = [NSSortDescriptor(key: "lastValidatedAt", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        var entitlements: [SubscriptionEntitlement] = []

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                let entitlement = try recordToEntitlement(record)
                entitlements.append(entitlement)
            case .failure(let error):
                print("Failed to fetch entitlement record: \(error)")
                continue
            }
        }

        return entitlements
    }

    public func fetchEntitlement(byTransactionID transactionID: String) async throws -> SubscriptionEntitlement? {
        let predicate = NSPredicate(format: "transactionID == %@", transactionID)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        let (matchResults, _) = try await database.records(matching: query)

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                return try recordToEntitlement(record)
            case .failure(let error):
                print("Failed to fetch entitlement by transaction ID: \(error)")
                continue
            }
        }

        return nil
    }

    public func fetchEntitlement(byOriginalTransactionID originalTransactionID: String) async throws -> SubscriptionEntitlement? {
        let predicate = NSPredicate(format: "originalTransactionID == %@", originalTransactionID)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        // Sort by lastValidatedAt descending to get the most recent
        query.sortDescriptors = [NSSortDescriptor(key: "lastValidatedAt", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query)

        for result in matchResults {
            switch result.1 {
            case .success(let record):
                return try recordToEntitlement(record)
            case .failure(let error):
                print("Failed to fetch entitlement by original transaction ID: \(error)")
                continue
            }
        }

        return nil
    }

    public func updateEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement {
        let record = try entitlementToRecord(entitlement)
        let savedRecord = try await database.save(record)
        return try recordToEntitlement(savedRecord)
    }

    public func deleteEntitlement(id: String) async throws {
        let recordID = CKRecord.ID(recordName: id)
        _ = try await database.deleteRecord(withID: recordID)
    }

    public func validateEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        // Fetch the most recent active entitlement
        guard let entitlement = try await fetchEntitlement(for: familyID) else {
            return nil
        }

        // Check if entitlement needs validation (hasn't been validated in the last hour)
        let needsValidation = Date().timeIntervalSince(entitlement.lastValidatedAt) > 3600

        if needsValidation {
            // Update the last validated timestamp
            var updatedEntitlement = entitlement
            updatedEntitlement.lastValidatedAt = Date()

            return try await updateEntitlement(updatedEntitlement)
        }

        return entitlement
    }

    // MARK: - Helper Methods

    private func entitlementToRecord(_ entitlement: SubscriptionEntitlement) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: entitlement.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["familyID"] = entitlement.familyID
        record["subscriptionTier"] = entitlement.subscriptionTier.rawValue
        record["receiptData"] = entitlement.receiptData
        record["originalTransactionID"] = entitlement.originalTransactionID
        record["transactionID"] = entitlement.transactionID
        record["purchaseDate"] = entitlement.purchaseDate
        record["expirationDate"] = entitlement.expirationDate
        record["isActive"] = entitlement.isActive ? 1 : 0
        record["isInTrial"] = entitlement.isInTrial ? 1 : 0
        record["autoRenewStatus"] = entitlement.autoRenewStatus ? 1 : 0
        record["lastValidatedAt"] = entitlement.lastValidatedAt
        record["gracePeriodExpiresAt"] = entitlement.gracePeriodExpiresAt

        // Store metadata as JSON string
        if !entitlement.metadata.isEmpty {
            if let metadataData = try? JSONSerialization.data(withJSONObject: entitlement.metadata),
               let metadataString = String(data: metadataData, encoding: .utf8) {
                record["metadata"] = metadataString
            }
        }

        // Add indices for efficient querying
        record["familyID_isActive"] = "\(entitlement.familyID)_\(entitlement.isActive ? 1 : 0)"
        record["familyID_expiration"] = "\(entitlement.familyID)_\(Int(entitlement.expirationDate.timeIntervalSince1970))"

        return record
    }

    private func recordToEntitlement(_ record: CKRecord) throws -> SubscriptionEntitlement {
        guard let familyID = record["familyID"] as? String,
              let subscriptionTierString = record["subscriptionTier"] as? String,
              let subscriptionTier = SubscriptionTier(rawValue: subscriptionTierString),
              let receiptData = record["receiptData"] as? String,
              let originalTransactionID = record["originalTransactionID"] as? String,
              let transactionID = record["transactionID"] as? String,
              let purchaseDate = record["purchaseDate"] as? Date,
              let expirationDate = record["expirationDate"] as? Date,
              let isActiveInt = record["isActive"] as? Int,
              let isInTrialInt = record["isInTrial"] as? Int,
              let autoRenewStatusInt = record["autoRenewStatus"] as? Int,
              let lastValidatedAt = record["lastValidatedAt"] as? Date else {
            throw CloudKitError.invalidRecord("Missing required fields in SubscriptionEntitlement record")
        }

        let isActive = isActiveInt == 1
        let isInTrial = isInTrialInt == 1
        let autoRenewStatus = autoRenewStatusInt == 1
        let gracePeriodExpiresAt = record["gracePeriodExpiresAt"] as? Date

        // Parse metadata
        var metadata: [String: String] = [:]
        if let metadataString = record["metadata"] as? String,
           let metadataData = metadataString.data(using: .utf8),
           let parsedMetadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: String] {
            metadata = parsedMetadata
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
            isActive: isActive,
            isInTrial: isInTrial,
            autoRenewStatus: autoRenewStatus,
            lastValidatedAt: lastValidatedAt,
            gracePeriodExpiresAt: gracePeriodExpiresAt,
            metadata: metadata
        )
    }
}

// MARK: - Error Types

public enum CloudKitError: LocalizedError {
    case invalidRecord(String)
    case networkUnavailable
    case quotaExceeded
    case permissionDenied

    public var errorDescription: String? {
        switch self {
        case .invalidRecord(let message):
            return "Invalid CloudKit record: \(message)"
        case .networkUnavailable:
            return "Network unavailable for CloudKit operations"
        case .quotaExceeded:
            return "CloudKit quota exceeded"
        case .permissionDenied:
            return "Permission denied for CloudKit operation"
        }
    }
}