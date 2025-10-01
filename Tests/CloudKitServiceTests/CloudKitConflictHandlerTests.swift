import XCTest
import CloudKit
@testable import CloudKitService
@testable import RewardCore
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
class CloudKitConflictHandlerTests: XCTestCase {
    var conflictHandler: CloudKitConflictHandler!
    var mockConflictResolver: MockConflictResolver!
    var mockConflictDetector: MockConflictDetector!
    
    override func setUp() {
        super.setUp()
        
        mockConflictResolver = MockConflictResolver()
        mockConflictDetector = MockConflictDetector()
        
        conflictHandler = CloudKitConflictHandler(
            conflictResolver: mockConflictResolver,
            conflictDetector: mockConflictDetector
        )
    }
    
    override func tearDown() {
        conflictHandler = nil
        mockConflictResolver = nil
        mockConflictDetector = nil
        
        super.tearDown()
    }
    
    func testHandleConflictsWithRecords() async throws {
        // Create mock CKRecords
        let record1 = CKRecord(recordType: "Family")
        record1["name"] = "Family 1"
        
        let record2 = CKRecord(recordType: "Family")
        record2["name"] = "Family 2"
        
        let conflicts = [record1, record2]
        let recordType = "Family"
        
        let resolvedRecord = try await conflictHandler.handleConflicts(conflicts, recordType: recordType)
        
        // Should return the first record as the winner
        XCTAssertNotNil(resolvedRecord)
        XCTAssertEqual(resolvedRecord.recordType, "Family")
        
        // Should have stored conflict metadata
        XCTAssertTrue(mockConflictResolver.wasStoreConflictMetadataCalled)
    }
    
    func testHandleConflictsWithNoRecords() async throws {
        let conflicts: [CKRecord] = []
        let recordType = "Family"
        
        do {
            _ = try await conflictHandler.handleConflicts(conflicts, recordType: recordType)
            XCTFail("Expected ConflictError.noRecordsToResolve to be thrown")
        } catch {
            XCTAssertTrue(error is ConflictError)
            XCTAssertEqual(error as? ConflictError, .noRecordsToResolve)
        }
    }
    
    func testConvertRecordsToConflictChanges() throws {
        let record = CKRecord(recordType: "Family")
        record["name"] = "Test Family"
        record["description"] = "A test family"
        
        let records = [record]
        let changes = conflictHandler.convertRecordsToConflictChanges(records)
        
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes[0].fieldChanges.count, 2)
        
        let fieldNames = changes[0].fieldChanges.map { $0.fieldName }
        XCTAssertTrue(fieldNames.contains("name"))
        XCTAssertTrue(fieldNames.contains("description"))
    }
}

// MARK: - Mock Classes

class MockConflictResolver: ConflictResolver {
    var wasStoreConflictMetadataCalled = false
    
    init() {
        super.init(
            permissionService: MockPermissionService(),
            conflictMetadataRepository: MockConflictMetadataRepository()
        )
    }
    
    override func storeConflictMetadata(_ metadata: SharedModels.ConflictMetadata) async throws {
        wasStoreConflictMetadataCalled = true
    }
}

class MockConflictDetector: ConflictDetector {
    init() {
        super.init(
            familyRepository: MockFamilyRepository(),
            childProfileRepository: MockChildProfileRepository(),
            appCategorizationRepository: MockAppCategorizationRepository(),
            familySettingsRepository: MockFamilySettingsRepository()
        )
    }
}

class MockPermissionService: PermissionService {
    override func getUserRole(userID: String, familyID: String) async throws -> PermissionRole {
        return .owner
    }
    
    override func checkPermission(_ permission: PermissionCheck) async throws -> Bool {
        return true
    }
}

class MockConflictMetadataRepository: ConflictMetadataRepository {
    func createConflictMetadata(_ metadata: SharedModels.ConflictMetadata) async throws -> SharedModels.ConflictMetadata {
        return metadata
    }
    
    func fetchConflictMetadata(id: String) async throws -> SharedModels.ConflictMetadata? {
        return nil
    }
    
    func fetchConflicts(for familyID: String) async throws -> [SharedModels.ConflictMetadata] {
        return []
    }
    
    func updateConflictMetadata(_ metadata: SharedModels.ConflictMetadata) async throws -> SharedModels.ConflictMetadata {
        return metadata
    }
    
    func deleteConflictMetadata(id: String) async throws {
        // No-op
    }
}

class MockFamilyRepository: FamilyRepository {
    func createFamily(_ family: SharedModels.Family) async throws -> SharedModels.Family {
        return family
    }
    
    func fetchFamily(id: String) async throws -> SharedModels.Family? {
        return nil
    }
    
    func fetchFamilies(for userID: String) async throws -> [SharedModels.Family] {
        return []
    }
    
    func updateFamily(_ family: SharedModels.Family) async throws -> SharedModels.Family {
        return family
    }
    
    func deleteFamily(id: String) async throws {
        // No-op
    }
}

class MockChildProfileRepository: ChildProfileRepository {
    func createChild(_ child: SharedModels.ChildProfile) async throws -> SharedModels.ChildProfile {
        return child
    }
    
    func fetchChild(id: String) async throws -> SharedModels.ChildProfile? {
        return nil
    }
    
    func fetchChildren(for familyID: String) async throws -> [SharedModels.ChildProfile] {
        return []
    }
    
    func updateChild(_ child: SharedModels.ChildProfile) async throws -> SharedModels.ChildProfile {
        return child
    }
    
    func deleteChild(id: String) async throws {
        // No-op
    }
}

class MockAppCategorizationRepository: AppCategorizationRepository {
    func createAppCategorization(_ categorization: SharedModels.AppCategorization) async throws -> SharedModels.AppCategorization {
        return categorization
    }
    
    func fetchAppCategorization(id: String) async throws -> SharedModels.AppCategorization? {
        return nil
    }
    
    func fetchAppCategorizations(for childID: String) async throws -> [SharedModels.AppCategorization] {
        return []
    }
    
    func updateAppCategorization(_ categorization: SharedModels.AppCategorization) async throws -> SharedModels.AppCategorization {
        return categorization
    }
    
    func deleteAppCategorization(id: String) async throws {
        // No-op
    }
}

class MockFamilySettingsRepository: FamilySettingsRepository {
    func createSettings(_ settings: SharedModels.FamilySettings) async throws -> SharedModels.FamilySettings {
        return settings
    }
    
    func fetchSettings(for familyID: String) async throws -> SharedModels.FamilySettings? {
        return nil
    }
    
    func updateSettings(_ settings: SharedModels.FamilySettings) async throws -> SharedModels.FamilySettings {
        return settings
    }
    
    func deleteSettings(id: String) async throws {
        // No-op
    }
}