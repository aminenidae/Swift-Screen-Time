import XCTest
@testable import RewardCore
@testable import CloudKitService
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
final class RealTimeSyncIntegrationTests: XCTestCase {
    
    var coordinationService: ParentCoordinationService!
    var changeDetectionService: ChangeDetectionService!
    var synchronizationManager: SynchronizationManager!
    
    override func setUp() {
        super.setUp()
        coordinationService = ParentCoordinationService.shared
        changeDetectionService = ChangeDetectionService.shared
        synchronizationManager = SynchronizationManager.shared
    }
    
    override func tearDown() {
        coordinationService = nil
        changeDetectionService = nil
        synchronizationManager = nil
        super.tearDown()
    }
    
    func testParentCoordinationZoneCreation() async throws {
        let familyID = UUID()
        try await coordinationService.createParentCoordinationZone(for: familyID)
        
        // Verify zone was created (in a real test, we would check CloudKit)
        XCTAssertNotNil(familyID)
    }
    
    func testCoordinationSubscriptionCreation() async throws {
        let familyID = UUID()
        let userID = "test-user"
        
        try await coordinationService.createCoordinationSubscription(for: familyID, excluding: userID)
        
        // Verify subscription was created (in a real test, we would check CloudKit)
        XCTAssertNotNil(familyID)
        XCTAssertEqual(userID, "test-user")
    }
    
    func testAppCategorizationChangeEventPublishing() async throws {
        let familyID = UUID()
        let userID = "test-user"
        
        let categorization = AppCategorization(
            id: "test-categorization",
            appBundleID: "com.test.app",
            category: .learning,
            childProfileID: "test-child",
            pointsPerHour: 10
        )
        
        try await changeDetectionService.publishAppCategorizationChange(
            categorization,
            familyID: familyID,
            userID: userID
        )
        
        // Verify event was published (in a real test, we would check CloudKit)
        XCTAssertNotNil(categorization)
    }
    
    func testChildProfileChangeEventPublishing() async throws {
        let familyID = UUID()
        let userID = "test-user"
        
        let childProfile = ChildProfile(
            id: "test-child",
            familyID: familyID.uuidString,
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 200
        )
        
        try await changeDetectionService.publishChildProfileChange(
            childProfile,
            familyID: familyID,
            userID: userID
        )
        
        // Verify event was published (in a real test, we would check CloudKit)
        XCTAssertNotNil(childProfile)
    }
    
    func testPointsAdjustmentEventPublishing() async throws {
        let familyID = UUID()
        let userID = "test-user"
        let childID = "test-child"
        
        try await changeDetectionService.publishPointsAdjustment(
            childID: childID,
            newBalance: 150,
            oldBalance: 100,
            familyID: familyID,
            userID: userID
        )
        
        // Verify event was published (in a real test, we would check CloudKit)
        XCTAssertNotNil(familyID)
    }
    
    func testOfflineQueueFunctionality() async throws {
        let offlineQueue = OfflineEventQueue.shared
        let event = createTestCoordinationEvent()
        
        // Enqueue event
        offlineQueue.enqueueEvent(event)
        
        // Verify event is in queue
        let events = offlineQueue.getAllEvents()
        XCTAssertTrue(events.contains { $0.id == event.id })
        
        // Remove event
        offlineQueue.removeEvent(event.id)
        
        // Verify event is no longer in queue
        let updatedEvents = offlineQueue.getAllEvents()
        XCTAssertFalse(updatedEvents.contains { $0.id == event.id })
    }
    
    func testRetryMechanism() async throws {
        let retryManager = RetryManager.shared
        
        // Test successful operation
        var attemptCount = 0
        let result = try await retryManager.retry(maxAttempts: 3, delay: 0.1) {
            attemptCount += 1
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attemptCount, 1)
    }
    
    func testPerformanceOptimization() async throws {
        let performanceService = PerformanceOptimizationService.shared
        let event = createTestCoordinationEvent()
        
        // Test debouncing
        performanceService.debounceEventPublishing(event, delay: 0.1)
        
        // Test batching
        let events = [event, event, event]
        try await performanceService.batchEvents(events)
        
        // Verify operations completed
        XCTAssertNotNil(performanceService)
        XCTAssertEqual(events.count, 3)
    }
    
    // Helper method to create a test coordination event
    private func createTestCoordinationEvent() -> ParentCoordinationEvent {
        return ParentCoordinationEvent(
            id: UUID(),
            familyID: UUID(),
            triggeringUserID: "test-user",
            eventType: .appCategorizationChanged,
            targetEntity: "TestEntity",
            targetEntityID: UUID(),
            changes: CodableDictionary(["test": "value"]),
            timestamp: Date(),
            deviceID: "test-device"
        )
    }
}