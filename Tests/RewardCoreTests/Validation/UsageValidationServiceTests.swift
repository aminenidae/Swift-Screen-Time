import XCTest
@testable import RewardCore
@testable import SharedModels

final class UsageValidationServiceTests: XCTestCase {
    var validationService: UsageValidationService!
    var mockFamilySettingsRepository: MockFamilySettingsRepository!
    
    override func setUp() {
        super.setUp()
        mockFamilySettingsRepository = MockFamilySettingsRepository()
        validationService = UsageValidationService(familySettingsRepository: mockFamilySettingsRepository)
    }
    
    override func tearDown() {
        validationService = nil
        mockFamilySettingsRepository = nil
        super.tearDown()
    }
    
    func testValidateSessionWithNormalUsage() async throws {
        // Create a normal usage session
        let session = UsageSession(
            id: "test-session-1",
            childProfileID: "child-1",
            appBundleID: "com.example.learning",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800), // 30 minutes
            duration: 1800,
            isValidated: false,
            validationDetails: nil
        )
        
        // Set family settings to moderate validation
        mockFamilySettingsRepository.mockSettings = FamilySettings(
            id: "settings-1",
            familyID: "family-1",
            validationStrictness: .moderate
        )
        
        let result = try await validationService.validateSession(session, forFamilyID: "family-1")
        
        // Should be valid with high score for normal usage
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.validationScore > 0.7)
        XCTAssertTrue(result.adjustmentFactor >= 0.75)
        XCTAssertEqual(result.detectedPatterns.count, 0)
    }
    
    func testValidateSessionWithSuspiciousRapidSwitching() async throws {
        // Create a suspiciously short usage session (rapid switching)
        let session = UsageSession(
            id: "test-session-2",
            childProfileID: "child-1",
            appBundleID: "com.example.learning",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(15), // 15 seconds
            duration: 15,
            isValidated: false,
            validationDetails: nil
        )
        
        // Set family settings to strict validation
        mockFamilySettingsRepository.mockSettings = FamilySettings(
            id: "settings-1",
            familyID: "family-1",
            validationStrictness: .strict
        )
        
        let result = try await validationService.validateSession(session, forFamilyID: "family-1")
        
        // May be flagged as suspicious with strict validation
        XCTAssertLessThan(result.adjustmentFactor, 1.0)
    }
    
    func testValidateSessionWithPassiveUsage() async throws {
        // Create a long session with low interaction (passive usage)
        let session = UsageSession(
            id: "test-session-3",
            childProfileID: "child-1",
            appBundleID: "com.example.learning",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200), // 2 hours
            duration: 7200,
            isValidated: false,
            validationDetails: nil
        )
        
        // Set family settings to moderate validation
        mockFamilySettingsRepository.mockSettings = FamilySettings(
            id: "settings-1",
            familyID: "family-1",
            validationStrictness: .moderate
        )
        
        let result = try await validationService.validateSession(session, forFamilyID: "family-1")
        
        // May be flagged as passive usage
        XCTAssertLessThan(result.adjustmentFactor, 1.0)
    }
    
    func testValidationWithDifferentStrictnessLevels() async throws {
        let session = UsageSession(
            id: "test-session-4",
            childProfileID: "child-1",
            appBundleID: "com.example.learning",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(30), // 30 seconds (suspicious)
            duration: 30,
            isValidated: false,
            validationDetails: nil
        )
        
        // Test lenient mode
        mockFamilySettingsRepository.mockSettings = FamilySettings(
            id: "settings-1",
            familyID: "family-1",
            validationStrictness: .lenient
        )
        
        let lenientResult = try await validationService.validateSession(session, forFamilyID: "family-1")
        
        // Test strict mode
        mockFamilySettingsRepository.mockSettings = FamilySettings(
            id: "settings-1",
            familyID: "family-1",
            validationStrictness: .strict
        )
        
        let strictResult = try await validationService.validateSession(session, forFamilyID: "family-1")
        
        // Strict mode should be less forgiving
        XCTAssertLessThanOrEqual(strictResult.adjustmentFactor, lenientResult.adjustmentFactor)
    }
}

// Mock repository for testing
class MockFamilySettingsRepository: FamilySettingsRepository {
    var mockSettings: FamilySettings?
    
    func createSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        return settings
    }
    
    func fetchSettings(for familyID: String) async throws -> FamilySettings? {
        return mockSettings
    }
    
    func updateSettings(_ settings: FamilySettings) async throws -> FamilySettings {
        return settings
    }
    
    func deleteSettings(id: String) async throws {
        // No-op for mock
    }
}