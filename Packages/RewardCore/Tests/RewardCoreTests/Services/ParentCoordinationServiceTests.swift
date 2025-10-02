import XCTest
@testable import RewardCore
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
final class ParentCoordinationServiceTests: XCTestCase {
    
    var coordinationService: ParentCoordinationService!
    
    override func setUp() {
        super.setUp()
        coordinationService = ParentCoordinationService.shared
    }
    
    override func tearDown() {
        coordinationService = nil
        super.tearDown()
    }
    
    func testParentCoordinationEventInitialization() {
        let eventID = UUID()
        let familyID = UUID()
        let changes = CodableDictionary(["test": "value"])
        let event = ParentCoordinationEvent(
            id: eventID,
            familyID: familyID,
            triggeringUserID: "user123",
            eventType: .appCategorizationChanged,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(),
            changes: changes,
            timestamp: Date(),
            deviceID: "device456"
        )
        
        XCTAssertEqual(event.id, eventID)
        XCTAssertEqual(event.familyID, familyID)
        XCTAssertEqual(event.triggeringUserID, "user123")
        XCTAssertEqual(event.eventType, .appCategorizationChanged)
    }
    
    func testParentCoordinationEventTypeCases() {
        let allCases: [ParentCoordinationEventType] = [
            .appCategorizationChanged,
            .settingsUpdated,
            .pointsAdjusted,
            .rewardRedeemed,
            .childProfileModified
        ]
        
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.appCategorizationChanged))
        XCTAssertTrue(allCases.contains(.settingsUpdated))
        XCTAssertTrue(allCases.contains(.pointsAdjusted))
        XCTAssertTrue(allCases.contains(.rewardRedeemed))
        XCTAssertTrue(allCases.contains(.childProfileModified))
    }
    
    func testCodableDictionary() {
        let dictionary = ["key1": "value1", "key2": "value2"]
        let codableDict = CodableDictionary(dictionary)
        
        XCTAssertEqual(codableDict["key1"], "value1")
        XCTAssertEqual(codableDict["key2"], "value2")
        XCTAssertEqual(codableDict.dictionary, dictionary)
    }
    
    func testCoordinationServiceInitialization() {
        XCTAssertNotNil(coordinationService)
        XCTAssertNotNil(coordinationService.coordinationEventsPublisher(for: UUID()))
    }
    
    func testSynchronizationManagerInitialization() {
        let syncManager = SynchronizationManager.shared
        XCTAssertNotNil(syncManager)
    }
    
    func testPerformanceOptimizationServiceInitialization() {
        let performanceService = PerformanceOptimizationService.shared
        XCTAssertNotNil(performanceService)
    }
    
    func testChangeDetectionServiceInitialization() {
        let changeDetectionService = ChangeDetectionService.shared
        XCTAssertNotNil(changeDetectionService)
    }
}