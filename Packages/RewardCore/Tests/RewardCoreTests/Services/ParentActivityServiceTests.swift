import XCTest
import Combine
import CloudKit
@testable import RewardCore
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
final class ParentActivityServiceTests: XCTestCase {

    var service: ParentActivityService!
    var mockRepository: MockParentActivityRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockParentActivityRepository()
        service = ParentActivityService(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        service = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }

    @MainActor
    func testLoadActivitiesSuccess() async {
        // Given
        let familyID = UUID()
        let mockActivities = [
            createSampleActivity(familyID: familyID),
            createSampleActivity(familyID: familyID)
        ]
        mockRepository.mockActivities = mockActivities

        // When
        await service.loadActivities(for: familyID, limit: 10)

        // Then
        XCTAssertEqual(service.activities.count, 2)
        XCTAssertEqual(service.activities, mockActivities)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.error)
    }

    @MainActor
    func testLoadActivitiesFailure() async {
        // Given
        let familyID = UUID()
        mockRepository.shouldFail = true

        // When
        await service.loadActivities(for: familyID, limit: 10)

        // Then
        XCTAssertTrue(service.activities.isEmpty)
        XCTAssertFalse(service.isLoading)
        XCTAssertNotNil(service.error)
    }

    @MainActor
    func testLoadRecentActivities() async {
        // Given
        let familyID = UUID()
        let mockActivities = [
            createSampleActivity(familyID: familyID, timestamp: Date().addingTimeInterval(-3600))
        ]
        mockRepository.mockActivities = mockActivities

        // When
        await service.loadRecentActivities(for: familyID)

        // Then
        XCTAssertEqual(service.activities.count, 1)
        XCTAssertFalse(service.isLoading)
        XCTAssertTrue(mockRepository.fetchActivitiesSinceCalled)
    }

    func testLogActivitySuccess() async throws {
        // Given
        let familyID = UUID()
        let triggeringUserID = "test-user"
        let activityType = ParentActivityType.appCategorizationAdded
        let targetEntity = "AppCategorization"
        let targetEntityID = UUID()
        let changes = ["appName": "Khan Academy", "category": "Learning"]

        let expectedActivity = ParentActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: activityType,
            targetEntity: targetEntity,
            targetEntityID: targetEntityID,
            changes: CodableDictionary(changes)
        )
        mockRepository.mockCreatedActivity = expectedActivity

        // When
        let result = try await service.logActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: activityType,
            targetEntity: targetEntity,
            targetEntityID: targetEntityID,
            changes: changes
        )

        // Then
        XCTAssertEqual(result.familyID, familyID)
        XCTAssertEqual(result.activityType, activityType)
        XCTAssertTrue(mockRepository.createActivityCalled)

        await MainActor.run {
            XCTAssertEqual(service.activities.count, 1)
            XCTAssertEqual(service.activities.first?.id, result.id)
        }
    }

    func testLogAppCategorizationChange() async throws {
        // Given
        let familyID = UUID()
        let triggeringUserID = "test-user"
        let appName = "YouTube"
        let appBundleID = "com.google.ios.youtube"
        let childName = "Emma"
        let oldCategory = "Learning"
        let newCategory = "Reward"

        mockRepository.mockCreatedActivity = createSampleActivity(familyID: familyID)

        // When
        try await service.logAppCategorizationChange(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: .appCategorizationModified,
            appName: appName,
            appBundleID: appBundleID,
            childName: childName,
            oldCategory: oldCategory,
            newCategory: newCategory
        )

        // Then
        XCTAssertTrue(mockRepository.createActivityCalled)

        let capturedActivity = mockRepository.capturedActivity!
        XCTAssertEqual(capturedActivity.activityType, .appCategorizationModified)
        XCTAssertEqual(capturedActivity.changes["appName"], appName)
        XCTAssertEqual(capturedActivity.changes["appBundleID"], appBundleID)
        XCTAssertEqual(capturedActivity.changes["childName"], childName)
        XCTAssertEqual(capturedActivity.changes["oldCategory"], oldCategory)
        XCTAssertEqual(capturedActivity.changes["newCategory"], newCategory)
    }

    func testLogPointAdjustment() async throws {
        // Given
        let familyID = UUID()
        let triggeringUserID = "test-user"
        let childName = "Alex"
        let childID = UUID()
        let pointsChange = 50
        let reason = "Good behavior"

        mockRepository.mockCreatedActivity = createSampleActivity(familyID: familyID)

        // When
        try await service.logPointAdjustment(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            childName: childName,
            childID: childID,
            pointsChange: pointsChange,
            reason: reason
        )

        // Then
        XCTAssertTrue(mockRepository.createActivityCalled)

        let capturedActivity = mockRepository.capturedActivity!
        XCTAssertEqual(capturedActivity.activityType, .pointsAdjusted)
        XCTAssertEqual(capturedActivity.changes["childName"], childName)
        XCTAssertEqual(capturedActivity.changes["pointsChange"], "+50")
        XCTAssertEqual(capturedActivity.changes["reason"], reason)
        XCTAssertEqual(capturedActivity.targetEntityID, childID)
    }

    func testLogRewardRedemption() async throws {
        // Given
        let familyID = UUID()
        let triggeringUserID = "test-user"
        let childName = "Sophie"
        let childID = UUID()
        let rewardName = "Extra Screen Time"
        let rewardID = UUID()
        let pointsSpent = 100

        mockRepository.mockCreatedActivity = createSampleActivity(familyID: familyID)

        // When
        try await service.logRewardRedemption(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            childName: childName,
            childID: childID,
            rewardName: rewardName,
            rewardID: rewardID,
            pointsSpent: pointsSpent
        )

        // Then
        XCTAssertTrue(mockRepository.createActivityCalled)

        let capturedActivity = mockRepository.capturedActivity!
        XCTAssertEqual(capturedActivity.activityType, .rewardRedeemed)
        XCTAssertEqual(capturedActivity.changes["childName"], childName)
        XCTAssertEqual(capturedActivity.changes["rewardName"], rewardName)
        XCTAssertEqual(capturedActivity.changes["pointsSpent"], "100")
        XCTAssertEqual(capturedActivity.targetEntityID, rewardID)
    }

    @MainActor
    func testCleanupOldActivities() async {
        // Given
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        // When
        await service.cleanupOldActivities()

        // Then
        XCTAssertTrue(mockRepository.deleteOldActivitiesCalled)
        XCTAssertNotNil(mockRepository.capturedCutoffDate)
        XCTAssertLessThanOrEqual(
            abs(mockRepository.capturedCutoffDate!.timeIntervalSince(cutoffDate)),
            60 // Within 1 minute
        )
    }

    @MainActor
    func testGetActivitiesByType() async {
        // Given
        let familyID = UUID()
        let pointsActivity = createSampleActivity(familyID: familyID, activityType: .pointsAdjusted)
        let appActivity = createSampleActivity(familyID: familyID, activityType: .appCategorizationAdded)

        service.setActivitiesForTesting([pointsActivity, appActivity])

        // When
        let pointsActivities = service.getActivities(ofType: .pointsAdjusted)
        let appActivities = service.getActivities(ofType: .appCategorizationAdded)

        // Then
        XCTAssertEqual(pointsActivities.count, 1)
        XCTAssertEqual(pointsActivities.first?.activityType, .pointsAdjusted)
        XCTAssertEqual(appActivities.count, 1)
        XCTAssertEqual(appActivities.first?.activityType, .appCategorizationAdded)
    }

    @MainActor
    func testGetActivitiesInDateRange() async {
        // Given
        let familyID = UUID()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        let recentActivity = createSampleActivity(familyID: familyID, timestamp: oneHourAgo)
        let oldActivity = createSampleActivity(familyID: familyID, timestamp: twoDaysAgo)

        service.setActivitiesForTesting([recentActivity, oldActivity])

        let dateRange = DateRange(
            start: now.addingTimeInterval(-7200), // 2 hours ago
            end: now
        )

        // When
        let activitiesInRange = service.getActivities(in: dateRange)

        // Then
        XCTAssertEqual(activitiesInRange.count, 1)
        XCTAssertEqual(activitiesInRange.first?.id, recentActivity.id)
    }

    func testActivitiesPublisher() {
        // Given
        let expectation = expectation(description: "Activities publisher emits")
        var receivedActivities: [ParentActivity] = []

        service.activitiesPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { activities in
                    receivedActivities = activities
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // When
        let testActivities = [createSampleActivity()]
        Task {
            await MainActor.run {
                service.setActivitiesForTesting(testActivities)
            }
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedActivities.count, 1)
    }

    func testNewActivityPublisher() {
        // Given
        let expectation = expectation(description: "New activity publisher emits")
        var receivedActivity: ParentActivity?

        service.newActivityPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { activity in
                    receivedActivity = activity
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // When
        let testActivity = createSampleActivity()
        service.sendActivityForTesting(testActivity)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedActivity?.id, testActivity.id)
    }

    // MARK: - Real-Time Updates Tests

    func testCreateActivitySubscription() async throws {
        // Given
        let familyID = UUID()
        let userID = "test-user"

        // When/Then - Should not throw
        try await service.createActivitySubscription(for: familyID, excluding: userID)

        // In a real implementation, we'd verify the CloudKit subscription was created
    }

    func testHandleBackgroundFetch() async throws {
        // Given
        let familyID = UUID()
        let newActivities = [
            createSampleActivity(familyID: familyID, timestamp: Date())
        ]
        mockRepository.mockActivities = newActivities

        // When
        let fetchedActivities = try await service.handleBackgroundFetch(for: familyID)

        // Then
        XCTAssertEqual(fetchedActivities.count, 1)
        XCTAssertTrue(mockRepository.fetchActivitiesSinceCalled)
    }

    // MARK: - Helper Methods

    private func createSampleActivity(
        familyID: UUID = UUID(),
        activityType: ParentActivityType = .appCategorizationAdded,
        timestamp: Date = Date()
    ) -> ParentActivity {
        return ParentActivity(
            familyID: familyID,
            triggeringUserID: "test-user-123",
            activityType: activityType,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "appName": "Khan Academy",
                "category": "Learning"
            ]),
            timestamp: timestamp,
            deviceID: "iPhone123"
        )
    }
}

// MARK: - Mock Repository

@available(iOS 15.0, macOS 12.0, *)
class MockParentActivityRepository: ParentActivityRepository {
    var mockActivities: [ParentActivity] = []
    var mockCreatedActivity: ParentActivity?
    var shouldFail = false

    // Tracking method calls
    var createActivityCalled = false
    var fetchActivityCalled = false
    var fetchActivitiesCalled = false
    var fetchActivitiesSinceCalled = false
    var deleteActivityCalled = false
    var deleteOldActivitiesCalled = false

    // Captured parameters
    var capturedActivity: ParentActivity?
    var capturedCutoffDate: Date?

    func createActivity(_ activity: ParentActivity) async throws -> ParentActivity {
        createActivityCalled = true
        capturedActivity = activity

        if shouldFail {
            throw ParentActivityMockError.testError
        }

        return mockCreatedActivity ?? activity
    }

    func fetchActivity(id: UUID) async throws -> ParentActivity? {
        fetchActivityCalled = true

        if shouldFail {
            throw ParentActivityMockError.testError
        }

        return mockActivities.first { $0.id == id }
    }

    func fetchActivities(for familyID: UUID, limit: Int?) async throws -> [ParentActivity] {
        fetchActivitiesCalled = true

        if shouldFail {
            throw ParentActivityMockError.testError
        }

        let filtered = mockActivities.filter { $0.familyID == familyID }
        if let limit = limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    func fetchActivities(for familyID: UUID, since date: Date) async throws -> [ParentActivity] {
        fetchActivitiesSinceCalled = true

        if shouldFail {
            throw ParentActivityMockError.testError
        }

        return mockActivities.filter { $0.familyID == familyID && $0.timestamp >= date }
    }

    func fetchActivities(for familyID: UUID, dateRange: DateRange) async throws -> [ParentActivity] {
        if shouldFail {
            throw ParentActivityMockError.testError
        }

        return mockActivities.filter {
            $0.familyID == familyID &&
            $0.timestamp >= dateRange.start &&
            $0.timestamp <= dateRange.end
        }
    }

    func deleteActivity(id: UUID) async throws {
        deleteActivityCalled = true

        if shouldFail {
            throw ParentActivityMockError.testError
        }

        mockActivities.removeAll { $0.id == id }
    }

    func deleteOldActivities(olderThan date: Date) async throws {
        deleteOldActivitiesCalled = true
        capturedCutoffDate = date

        if shouldFail {
            throw ParentActivityMockError.testError
        }

        mockActivities.removeAll { $0.timestamp < date }
    }
}

enum ParentActivityMockError: Error {
    case testError
}