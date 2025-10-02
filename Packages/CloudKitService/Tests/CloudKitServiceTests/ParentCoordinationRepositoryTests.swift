import XCTest
@testable import CloudKitService
import SharedModels

@available(iOS 15.0, macOS 12.0, *)
final class ParentCoordinationRepositoryTests: XCTestCase {
    
    var repository: CloudKitParentCoordinationRepository!
    
    override func setUp() {
        super.setUp()
        repository = CloudKitParentCoordinationRepository()
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    func testCreateCoordinationEvent() async throws {
        let event = ParentCoordinationEvent(
            id: UUID(),
            familyID: UUID(),
            triggeringUserID: "testUser",
            eventType: .appCategorizationChanged,
            targetEntity: "TestEntity",
            targetEntityID: UUID(),
            changes: CodableDictionary(["test": "value"]),
            timestamp: Date(),
            deviceID: "testDevice"
        )
        
        let result = try await repository.createCoordinationEvent(event)
        XCTAssertEqual(result.triggeringUserID, "testUser")
        XCTAssertEqual(result.eventType, .appCategorizationChanged)
    }
    
    func testFetchCoordinationEvents() async throws {
        let familyID = UUID()
        let events = try await repository.fetchCoordinationEvents(for: familyID)
        XCTAssertNotNil(events)
    }
    
    func testDeleteCoordinationEvent() async throws {
        let eventID = UUID()
        // This should not throw an error
        try await repository.deleteCoordinationEvent(id: eventID)
    }
}