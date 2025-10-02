import XCTest
@testable import RewardCore
@testable import SharedModels

final class DataAnonymizationServiceTests: XCTestCase {
    var anonymizationService: DataAnonymizationService!
    
    override func setUp() {
        super.setUp()
        anonymizationService = DataAnonymizationService()
    }
    
    override func tearDown() {
        anonymizationService = nil
        super.tearDown()
    }
    
    // MARK: - User ID Anonymization Tests
    
    func testAnonymizeUserID_ReturnsConsistentHash() {
        // Given
        let familyID = "family-123"
        
        // When
        let anonymizedID1 = anonymizationService.anonymize(userID: familyID)
        let anonymizedID2 = anonymizationService.anonymize(userID: familyID)
        
        // Then
        XCTAssertEqual(anonymizedID1, anonymizedID2)
        XCTAssertNotEqual(anonymizedID1, familyID)
        XCTAssertTrue(anonymizedID1.hasPrefix("anon_"))
    }
    
    func testAnonymizeUserID_DifferentInputs_ReturnsDifferentHashes() {
        // Given
        let familyID1 = "family-123"
        let familyID2 = "family-456"
        
        // When
        let anonymizedID1 = anonymizationService.anonymize(userID: familyID1)
        let anonymizedID2 = anonymizationService.anonymize(userID: familyID2)
        
        // Then
        XCTAssertNotEqual(anonymizedID1, anonymizedID2)
    }
    
    // MARK: - Device Model Anonymization Tests
    
    func testAnonymizeDeviceModel_ReturnsGenericModel() {
        // Given
        let deviceModel = "iPhone13,2"
        
        // When
        let anonymizedModel = anonymizationService.anonymize(deviceModel: deviceModel)
        
        // Then
        XCTAssertEqual(anonymizedModel, "iPhone")
    }
    
    func testAnonymizeDeviceModel_WithiPad_ReturnsGenericModel() {
        // Given
        let deviceModel = "iPad8,1"
        
        // When
        let anonymizedModel = anonymizationService.anonymize(deviceModel: deviceModel)
        
        // Then
        XCTAssertEqual(anonymizedModel, "iPad")
    }
    
    func testAnonymizeDeviceModel_WithUnknownDevice_ReturnsUnknown() {
        // Given
        let deviceModel = "UnknownDevice"
        
        // When
        let anonymizedModel = anonymizationService.anonymize(deviceModel: deviceModel)
        
        // Then
        XCTAssertEqual(anonymizedModel, "Other")
    }
    
    // MARK: - Event Anonymization Tests
    
    func testAnonymizeEvent_PreservesStructure() async {
        // Given
        let originalEvent = AnalyticsEvent(
            eventType: .featureUsage(feature: "testFeature"),
            anonymizedUserID: "user-123",
            sessionID: "session-456",
            appVersion: "1.0.0",
            osVersion: "15.0",
            deviceModel: "iPhone13,2",
            metadata: ["key": "value"]
        )
        
        // When
        let anonymizedEvent = await anonymizationService.anonymize(event: originalEvent)
        
        // Then
        XCTAssertEqual(anonymizedEvent.eventType, originalEvent.eventType)
        XCTAssertEqual(anonymizedEvent.sessionID, originalEvent.sessionID)
        XCTAssertEqual(anonymizedEvent.appVersion, originalEvent.appVersion)
        XCTAssertEqual(anonymizedEvent.osVersion, originalEvent.osVersion)
        XCTAssertEqual(anonymizedEvent.metadata, originalEvent.metadata)
        // User ID and device model should be anonymized
        XCTAssertNotEqual(anonymizedEvent.anonymizedUserID, originalEvent.anonymizedUserID)
        XCTAssertNotEqual(anonymizedEvent.deviceModel, originalEvent.deviceModel)
    }
    
    // MARK: - Session ID Tests
    
    func testGetCurrentSessionID_ReturnsNonEmptyString() {
        // When
        let sessionID = anonymizationService.getCurrentSessionID()
        
        // Then
        XCTAssertFalse(sessionID.isEmpty)
    }
    
    func testGetCurrentSessionID_ReturnsConsistentValue() {
        // When
        let sessionID1 = anonymizationService.getCurrentSessionID()
        let sessionID2 = anonymizationService.getCurrentSessionID()
        
        // Then
        XCTAssertEqual(sessionID1, sessionID2)
    }
    
    // MARK: - App Version Tests
    
    func testGetAppVersion_ReturnsNonEmptyString() async {
        // When
        let appVersion = await anonymizationService.getAppVersion()
        
        // Then
        XCTAssertFalse(appVersion.isEmpty)
    }
    
    // MARK: - OS Version Tests
    
    func testGetOSVersion_ReturnsNonEmptyString() async {
        // When
        let osVersion = await anonymizationService.getOSVersion()
        
        // Then
        XCTAssertFalse(osVersion.isEmpty)
    }
    
    // MARK: - Device Model Tests
    
    func testGetDeviceModel_ReturnsNonEmptyString() async {
        // When
        let deviceModel = await anonymizationService.getDeviceModel()
        
        // Then
        XCTAssertFalse(deviceModel.isEmpty)
    }
}