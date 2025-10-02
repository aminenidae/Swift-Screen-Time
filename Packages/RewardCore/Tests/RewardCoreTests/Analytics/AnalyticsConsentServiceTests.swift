import XCTest
@testable import RewardCore
@testable import SharedModels

final class AnalyticsConsentServiceTests: XCTestCase {
    var consentService: AnalyticsConsentService!
    var mockRepository: MockAnalyticsConsentRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAnalyticsConsentRepository()
        consentService = AnalyticsConsentService(repository: mockRepository)
    }
    
    override func tearDown() {
        consentService = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Consent Management Tests
    
    func testSetConsentLevel_UpdatesConsent() async throws {
        // Given
        let familyID = "family-123"
        let consentLevel = AnalyticsConsentLevel.standard
        
        // When
        try await consentService.setConsentLevel(consentLevel, for: familyID)
        
        // Then
        XCTAssertNotNil(mockRepository.savedConsent)
        XCTAssertEqual(mockRepository.savedConsent?.familyID, familyID)
        XCTAssertEqual(mockRepository.savedConsent?.consentLevel, consentLevel)
    }
    
    func testGetConsentLevel_ReturnsSetLevel() async throws {
        // Given
        let familyID = "family-123"
        let consentLevel = AnalyticsConsentLevel.detailed
        try await consentService.setConsentLevel(consentLevel, for: familyID)
        
        // When
        let retrievedLevel = try await consentService.getConsentLevel(for: familyID)
        
        // Then
        XCTAssertEqual(retrievedLevel, consentLevel)
    }
    
    func testGetConsentLevel_WhenNotSet_ReturnsNone() async {
        // Given
        let familyID = "family-123"

        // When
        do {
            let retrievedLevel = try await consentService.getConsentLevel(for: familyID)

            // Then
            XCTAssertEqual(retrievedLevel, .none)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Collection Permission Tests
    
    func testIsCollectionAllowed_WhenConsentIsNone_ReturnsFalse() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.none, for: familyID)
        
        // When
        let allowed = await consentService.isCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertFalse(allowed)
    }
    
    func testIsCollectionAllowed_WhenConsentIsEssential_ReturnsTrue() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.essential, for: familyID)
        
        // When
        let allowed = await consentService.isCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertTrue(allowed)
    }
    
    func testIsCollectionAllowed_WhenConsentIsStandard_ReturnsTrue() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.standard, for: familyID)
        
        // When
        let allowed = await consentService.isCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertTrue(allowed)
    }
    
    func testIsCollectionAllowed_WhenConsentIsDetailed_ReturnsTrue() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.detailed, for: familyID)
        
        // When
        let allowed = await consentService.isCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertTrue(allowed)
    }
    
    // MARK: - Detailed Collection Tests
    
    func testIsDetailedCollectionAllowed_WhenConsentIsDetailed_ReturnsTrue() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.detailed, for: familyID)
        
        // When
        let allowed = await consentService.isDetailedCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertTrue(allowed)
    }
    
    func testIsDetailedCollectionAllowed_WhenConsentIsStandard_ReturnsFalse() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.standard, for: familyID)
        
        // When
        let allowed = await consentService.isDetailedCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertFalse(allowed)
    }
    
    func testIsDetailedCollectionAllowed_WhenConsentIsEssential_ReturnsFalse() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.essential, for: familyID)
        
        // When
        let allowed = await consentService.isDetailedCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertFalse(allowed)
    }
    
    // MARK: - Essential Collection Tests
    
    func testIsEssentialCollectionAllowed_WhenConsentIsEssential_ReturnsTrue() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.essential, for: familyID)
        
        // When
        let allowed = await consentService.isEssentialCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertTrue(allowed)
    }
    
    func testIsEssentialCollectionAllowed_WhenConsentIsNone_ReturnsFalse() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.none, for: familyID)
        
        // When
        let allowed = await consentService.isEssentialCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertFalse(allowed)
    }
    
    // MARK: - Standard Collection Tests
    
    func testIsStandardCollectionAllowed_WhenConsentIsStandard_ReturnsTrue() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.standard, for: familyID)
        
        // When
        let allowed = await consentService.isStandardCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertTrue(allowed)
    }
    
    func testIsStandardCollectionAllowed_WhenConsentIsEssential_ReturnsFalse() async {
        // Given
        let familyID = "family-123"
        _ = try? await consentService.setConsentLevel(.essential, for: familyID)
        
        // When
        let allowed = await consentService.isStandardCollectionAllowed(for: familyID)
        
        // Then
        XCTAssertFalse(allowed)
    }
}