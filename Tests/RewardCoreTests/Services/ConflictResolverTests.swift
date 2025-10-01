import XCTest
@testable import RewardCore
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
class ConflictResolverTests: XCTestCase {
    var conflictResolver: ConflictResolver!
    var mockPermissionService: MockPermissionService!
    var mockConflictMetadataRepository: MockConflictMetadataRepository!
    
    override func setUp() {
        super.setUp()
        
        mockPermissionService = MockPermissionService()
        mockConflictMetadataRepository = MockConflictMetadataRepository()
        
        conflictResolver = ConflictResolver(
            permissionService: mockPermissionService,
            conflictMetadataRepository: mockConflictMetadataRepository
        )
    }
    
    override func tearDown() {
        conflictResolver = nil
        mockPermissionService = nil
        mockConflictMetadataRepository = nil
        
        super.tearDown()
    }
    
    func testResolveWithLastWriteWins() throws {
        let conflict = ConflictMetadata(
            familyID: "test-family",
            recordType: "Family",
            recordID: "test-record",
            conflictingChanges: [],
            resolutionStrategy: .manualSelection
        )
        
        let changes = [
            ConflictChange(
                userID: "user1",
                changeType: .update,
                fieldChanges: [],
                timestamp: Date().addingTimeInterval(-100),
                deviceInfo: "device1"
            ),
            ConflictChange(
                userID: "user2",
                changeType: .update,
                fieldChanges: [],
                timestamp: Date().addingTimeInterval(-50),
                deviceInfo: "device2"
            ),
            ConflictChange(
                userID: "user3",
                changeType: .update,
                fieldChanges: [],
                timestamp: Date().addingTimeInterval(-75),
                deviceInfo: "device3"
            )
        ]
        
        let resolvedChange = conflictResolver.resolveWithLastWriteWins(conflict: conflict, changes: changes)
        
        // The change with timestamp -50 (user2) should be the most recent
        XCTAssertNotNil(resolvedChange)
        XCTAssertEqual(resolvedChange?.userID, "user2")
    }
    
    func testMergeChangesWithNoConflicts() throws {
        let conflict = ConflictMetadata(
            familyID: "test-family",
            recordType: "Family",
            recordID: "test-record",
            conflictingChanges: [],
            resolutionStrategy: .manualSelection
        )
        
        let changes = [
            ConflictChange(
                userID: "user1",
                changeType: .update,
                fieldChanges: [
                    FieldChange(fieldName: "name", oldValue: "Old Name", newValue: "New Name"),
                    FieldChange(fieldName: "description", oldValue: nil, newValue: "Description")
                ],
                timestamp: Date(),
                deviceInfo: "device1"
            ),
            ConflictChange(
                userID: "user2",
                changeType: .update,
                fieldChanges: [
                    FieldChange(fieldName: "points", oldValue: "100", newValue: "200")
                ],
                timestamp: Date(),
                deviceInfo: "device2"
            )
        ]
        
        let mergedChange = conflictResolver.mergeChanges(conflict: conflict, changes: changes)
        
        // Should be able to merge these non-conflicting changes
        XCTAssertNotNil(mergedChange)
        XCTAssertEqual(mergedChange?.fieldChanges.count, 3)
    }
    
    func testMergeChangesWithConflicts() throws {
        let conflict = ConflictMetadata(
            familyID: "test-family",
            recordType: "Family",
            recordID: "test-record",
            conflictingChanges: [],
            resolutionStrategy: .manualSelection
        )
        
        let changes = [
            ConflictChange(
                userID: "user1",
                changeType: .update,
                fieldChanges: [
                    FieldChange(fieldName: "name", oldValue: "Old Name", newValue: "New Name 1")
                ],
                timestamp: Date(),
                deviceInfo: "device1"
            ),
            ConflictChange(
                userID: "user2",
                changeType: .update,
                fieldChanges: [
                    FieldChange(fieldName: "name", oldValue: "Old Name", newValue: "New Name 2")
                ],
                timestamp: Date(),
                deviceInfo: "device2"
            )
        ]
        
        let mergedChange = conflictResolver.mergeChanges(conflict: conflict, changes: changes)
        
        // Should not be able to merge these conflicting changes
        XCTAssertNil(mergedChange)
    }
    
    func testStoreConflictMetadata() async throws {
        let conflictMetadata = ConflictMetadata(
            familyID: "test-family",
            recordType: "Family",
            recordID: "test-record",
            conflictingChanges: [],
            resolutionStrategy: .automaticLastWriteWins,
            metadata: ["test": "data"]
        )
        
        try await conflictResolver.storeConflictMetadata(conflictMetadata)
        
        // Verify the metadata was stored
        XCTAssertTrue(mockConflictMetadataRepository.wasCreateCalled)
    }
}

// MARK: - Mock Services

class MockPermissionService: PermissionService {
    private let userRoles: [String: PermissionRole]
    
    init() {
        // Set up some default roles for testing
        userRoles = [
            "owner": .owner,
            "coparent": .coParent,
            "viewer": .viewer
        ]
    }
    
    override func getUserRole(userID: String, familyID: String) async throws -> PermissionRole {
        return userRoles[userID] ?? .viewer
    }
    
    override func checkPermission(_ permission: PermissionCheck) async throws -> Bool {
        return true // Allow all permissions for testing
    }
}

class MockConflictMetadataRepository: ConflictMetadataRepository {
    var wasCreateCalled = false
    
    func createConflictMetadata(_ metadata: SharedModels.ConflictMetadata) async throws -> SharedModels.ConflictMetadata {
        wasCreateCalled = true
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