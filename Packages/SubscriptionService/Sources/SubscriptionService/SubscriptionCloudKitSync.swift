import Foundation
import CloudKit
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public final class SubscriptionCloudKitSync {
    private let container: CKContainer
    private let database: CKDatabase

    public init(container: CKContainer = CKContainer.default()) {
        self.container = container
        self.database = container.sharedCloudDatabase
    }

    /// Sync subscription status to CloudKit Family record
    public func syncSubscriptionStatus(
        _ status: SharedModels.SubscriptionStatus,
        forFamily familyID: String
    ) async throws {
        let recordID = CKRecord.ID(recordName: familyID)

        do {
            // Try to fetch existing record
            let existingRecord = try await database.record(for: recordID)
            existingRecord["subscriptionStatus"] = status.rawValue

            _ = try await database.modifyRecords(saving: [existingRecord], deleting: [])
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, we'll need to create it elsewhere
            // For now, just log the error - Family record creation should happen in family setup
            print("Family record not found for subscription status sync: \(familyID)")
            throw error
        }
    }

    /// Fetch current subscription status from CloudKit Family record
    public func fetchSubscriptionStatus(forFamily familyID: String) async throws -> SharedModels.SubscriptionStatus? {
        let recordID = CKRecord.ID(recordName: familyID)

        do {
            let record = try await database.record(for: recordID)
            guard let statusString = record["subscriptionStatus"] as? String else {
                return nil
            }
            return SharedModels.SubscriptionStatus(rawValue: statusString)
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet
            return nil
        }
    }

    /// Subscribe to CloudKit changes for subscription status updates
    public func subscribeToSubscriptionStatusChanges(familyID: String) async throws -> CKSubscription {
        let predicate = NSPredicate(format: "recordName == %@", familyID)
        let subscription = CKQuerySubscription(
            recordType: "Family",
            predicate: predicate,
            subscriptionID: "subscription_status_\(familyID)"
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = ["subscriptionStatus"]
        subscription.notificationInfo = notificationInfo

        return try await database.save(subscription)
    }
}