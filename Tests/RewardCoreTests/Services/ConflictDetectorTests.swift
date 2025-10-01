import XCTest
@testable import RewardCore
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
class ConflictDetectorTests: XCTestCase {
    var conflictDetector: ConflictDetector!
    var mockFamilyRepository: MockFamilyRepository!
    var mockChildProfileRepository: MockChildProfileRepository!
    var mockAppCategorizationRepository: MockAppCategorizationRepository!
    var mockFamilySettingsRepository: MockFamilySettingsRepository!
    
    override func setUp() {
        super.setUp()
        
        mockFamilyRepository = MockFamilyRepository()
        mockChildProfileRepository = MockChildProfileRepository()
        mockAppCategorizationRepository = MockAppCategorizationRepository()
        mockFamilySettingsRepository = MockFamilySettingsRepository()
        
        conflictDetector = ConflictDetector(
            familyRepository: mockFamilyRepository,
            childProfileRepository: mockChildProfileRepository,
            appCategorizationRepository: mockAppCategorizationRepository,
            familySettingsRepository: mockFamilySettingsRepository
        )
    }
    
    override func tearDown() {
        conflictDetector = nil
        mockFamilyRepository = nil
        mockChildProfileRepository = nil
        mockAppCategorizationRepository = nil
        mockFamilySettingsRepository = nil
        
        super.tearDown()
    }
    
    func testDetectConflictWithinTimeWindow() async throws {
        let recordID = "test-record"
        let recordType = "Family"
        let familyID = "test-family"
        let lastModified = Date().addingTimeInterval(-2) // 2 seconds ago
        
        let hasConflict = try await conflictDetector.detectConflict(
            recordID: recordID,
            recordType: recordType,
            familyID: familyID,
            lastModified: lastModified
        )
        
        // With our 5-second window, this should detect a conflict
        XCTAssertTrue(hasConflict)
    }
    
    func testDetectConflictOutsideTimeWindow() async throws {
        let recordID = "test-record"
        let recordType = "Family"
        let familyID = "test-family"
        let lastModified = Date().addingTimeInterval(-10) // 10 seconds ago
        
        let hasConflict = try await conflictDetector.detectConflict(
            recordID: recordID,
            recordType: recordType,
            familyID: familyID,
            lastModified: lastModified
        )
        
        // Outside the 5-second window, this should not detect a conflict
        XCTAssertFalse(hasConflict)
    }
    
    func testDetectFamilyConflict() async throws {
        let family = Family(
            id: "test-family",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "owner",
            sharedWithUserIDs: [],
            childProfileIDs: []
        )
        
        let hasConflict = try await conflictDetector.detectFamilyConflict(family)
        
        // Placeholder implementation returns false
        XCTAssertFalse(hasConflict)
    }
    
    func testDetectChildProfileConflict() async throws {
        let childProfile = ChildProfile(
            id: "test-child",
            familyID: "test-family",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100
        )
        
        let hasConflict = try await conflictDetector.detectChildProfileConflict(childProfile)
        
        // Placeholder implementation returns false
        XCTAssertFalse(hasConflict)
    }
}

// MARK: - Mock Repositories

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