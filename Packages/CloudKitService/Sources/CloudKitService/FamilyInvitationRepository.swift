import CloudKit
import Foundation
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
public class CloudKitFamilyInvitationRepository: FamilyInvitationRepository {
    private let database: CKDatabase
    private let recordType = "FamilyInvitation"

    public init(database: CKDatabase = CKContainer.default().privateCloudDatabase) {
        self.database = database
    }

    public func createInvitation(_ invitation: FamilyInvitation) async throws -> FamilyInvitation {
        let record = try createCKRecord(from: invitation)
        let savedRecord = try await database.save(record)
        return try createFamilyInvitation(from: savedRecord)
    }

    public func fetchInvitation(by token: UUID) async throws -> FamilyInvitation? {
        let predicate = NSPredicate(format: "token == %@", token.uuidString)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query)

        for (_, result) in results {
            switch result {
            case .success(let record):
                return try createFamilyInvitation(from: record)
            case .failure(let error):
                throw error
            }
        }

        return nil
    }

    public func fetchInvitations(for familyID: String) async throws -> [FamilyInvitation] {
        let predicate = NSPredicate(format: "familyID == %@", familyID)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let (results, _) = try await database.records(matching: query)
        var invitations: [FamilyInvitation] = []

        for (_, result) in results {
            switch result {
            case .success(let record):
                invitations.append(try createFamilyInvitation(from: record))
            case .failure(let error):
                throw error
            }
        }

        return invitations
    }

    public func fetchInvitations(by invitingUserID: String) async throws -> [FamilyInvitation] {
        let predicate = NSPredicate(format: "invitingUserID == %@", invitingUserID)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let (results, _) = try await database.records(matching: query)
        var invitations: [FamilyInvitation] = []

        for (_, result) in results {
            switch result {
            case .success(let record):
                invitations.append(try createFamilyInvitation(from: record))
            case .failure(let error):
                throw error
            }
        }

        return invitations
    }

    public func updateInvitation(_ invitation: FamilyInvitation) async throws -> FamilyInvitation {
        let recordID = CKRecord.ID(recordName: invitation.id.uuidString)

        do {
            let existingRecord = try await database.record(for: recordID)
            updateCKRecord(existingRecord, from: invitation)
            let savedRecord = try await database.save(existingRecord)
            return try createFamilyInvitation(from: savedRecord)
        } catch {
            throw FamilyInvitationCloudKitError.recordNotFound
        }
    }

    public func deleteInvitation(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        _ = try await database.deleteRecord(withID: recordID)
    }

    public func deleteExpiredInvitations() async throws {
        let predicate = NSPredicate(format: "expiresAt < %@", Date() as NSDate)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query)
        var recordIDsToDelete: [CKRecord.ID] = []

        for (recordID, result) in results {
            switch result {
            case .success(_):
                recordIDsToDelete.append(recordID)
            case .failure(let error):
                throw error
            }
        }

        if !recordIDsToDelete.isEmpty {
            let (_, errors) = try await database.modifyRecords(
                saving: [],
                deleting: recordIDsToDelete
            )

            // Check if there were any errors during deletion
            for (_, result) in errors {
                switch result {
                case .failure(let error):
                    throw error
                case .success:
                    continue
                }
            }
        }
    }

    // MARK: - Private Helper Methods

    private func createCKRecord(from invitation: FamilyInvitation) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: invitation.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["familyID"] = invitation.familyID
        record["invitingUserID"] = invitation.invitingUserID
        record["inviteeEmail"] = invitation.inviteeEmail
        record["token"] = invitation.token.uuidString
        record["createdAt"] = invitation.createdAt
        record["expiresAt"] = invitation.expiresAt
        record["isUsed"] = invitation.isUsed ? 1 : 0
        record["deepLinkURL"] = invitation.deepLinkURL

        return record
    }

    private func updateCKRecord(_ record: CKRecord, from invitation: FamilyInvitation) {
        record["familyID"] = invitation.familyID
        record["invitingUserID"] = invitation.invitingUserID
        record["inviteeEmail"] = invitation.inviteeEmail
        record["token"] = invitation.token.uuidString
        record["createdAt"] = invitation.createdAt
        record["expiresAt"] = invitation.expiresAt
        record["isUsed"] = invitation.isUsed ? 1 : 0
        record["deepLinkURL"] = invitation.deepLinkURL
    }

    private func createFamilyInvitation(from record: CKRecord) throws -> FamilyInvitation {
        guard
            let familyID = record["familyID"] as? String,
            let invitingUserID = record["invitingUserID"] as? String,
            let tokenString = record["token"] as? String,
            let token = UUID(uuidString: tokenString),
            let createdAt = record["createdAt"] as? Date,
            let expiresAt = record["expiresAt"] as? Date,
            let isUsedInt = record["isUsed"] as? Int,
            let deepLinkURL = record["deepLinkURL"] as? String
        else {
            throw FamilyInvitationCloudKitError.invalidRecord
        }

        let inviteeEmail = record["inviteeEmail"] as? String
        let isUsed = isUsedInt == 1

        guard let recordID = UUID(uuidString: record.recordID.recordName) else {
            throw FamilyInvitationCloudKitError.invalidRecord
        }

        return FamilyInvitation(
            id: recordID,
            familyID: familyID,
            invitingUserID: invitingUserID,
            inviteeEmail: inviteeEmail,
            token: token,
            createdAt: createdAt,
            expiresAt: expiresAt,
            isUsed: isUsed,
            deepLinkURL: deepLinkURL
        )
    }
}

// MARK: - Family Invitation CloudKit Error Types

enum FamilyInvitationCloudKitError: Error, LocalizedError {
    case invalidRecord
    case recordNotFound
    case networkError
    case quotaExceeded
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidRecord:
            return "Invalid CloudKit record format"
        case .recordNotFound:
            return "Record not found"
        case .networkError:
            return "Network connection error"
        case .quotaExceeded:
            return "CloudKit storage quota exceeded"
        case .authenticationFailed:
            return "CloudKit authentication failed"
        }
    }
}