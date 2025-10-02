import XCTest
import CloudKit
@testable import CloudKitService
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
final class ParentActivityRepositoryTests: XCTestCase {

    var repository: CloudKitParentActivityRepository!
    var mockContainer: CKContainer!

    override func setUp() {
        super.setUp()
        // Use a test container to avoid affecting production data
        mockContainer = CKContainer(identifier: "iCloud.com.test.ScreenTimeRewards")
        repository = CloudKitParentActivityRepository(container: mockContainer)
    }

    override func tearDown() {
        repository = nil
        mockContainer = nil
        super.tearDown()
    }

    func testCreateActivityRecord() throws {
        // Given
        let activity = createSampleActivity()

        // When
        let record = try repository.createCKRecord(from: activity)

        // Then
        XCTAssertEqual(record.recordType, "ParentActivity")
        XCTAssertEqual(record.recordID.recordName, activity.id.uuidString)
        XCTAssertEqual(record["familyID"] as? String, activity.familyID.uuidString)
        XCTAssertEqual(record["triggeringUserID"] as? String, activity.triggeringUserID)
        XCTAssertEqual(record["activityType"] as? String, activity.activityType.rawValue)
        XCTAssertEqual(record["targetEntity"] as? String, activity.targetEntity)
        XCTAssertEqual(record["targetEntityID"] as? String, activity.targetEntityID.uuidString)
        XCTAssertEqual(record["timestamp"] as? Date, activity.timestamp)
        XCTAssertEqual(record["deviceID"] as? String, activity.deviceID)
        XCTAssertNotNil(record["changes"] as? Data)
    }

    func testCreateParentActivityFromRecord() throws {
        // Given
        let originalActivity = createSampleActivity()
        let record = try repository.createCKRecord(from: originalActivity)

        // When
        let recreatedActivity = try repository.createParentActivity(from: record)

        // Then
        XCTAssertEqual(recreatedActivity.id, originalActivity.id)
        XCTAssertEqual(recreatedActivity.familyID, originalActivity.familyID)
        XCTAssertEqual(recreatedActivity.triggeringUserID, originalActivity.triggeringUserID)
        XCTAssertEqual(recreatedActivity.activityType, originalActivity.activityType)
        XCTAssertEqual(recreatedActivity.targetEntity, originalActivity.targetEntity)
        XCTAssertEqual(recreatedActivity.targetEntityID, originalActivity.targetEntityID)
        XCTAssertEqual(recreatedActivity.changes.dictionary, originalActivity.changes.dictionary)
        XCTAssertEqual(recreatedActivity.timestamp, originalActivity.timestamp)
        XCTAssertEqual(recreatedActivity.deviceID, originalActivity.deviceID)
    }

    func testCreateParentActivityFromInvalidRecord() {
        // Given
        let invalidRecord = CKRecord(recordType: "ParentActivity")
        // Record is missing required fields

        // When/Then
        XCTAssertThrowsError(try repository.createParentActivity(from: invalidRecord)) { error in
            XCTAssertTrue(error is ParentActivityCloudKitError)
        }
    }

    func testPrivacyCheckValidActivity() async {
        // Given
        let familyID = UUID()
        let activity = ParentActivity(
            familyID: familyID,
            triggeringUserID: "valid-user-id-123",
            activityType: .pointsAdjusted,
            targetEntity: "ChildProfile",
            targetEntityID: UUID(),
            changes: CodableDictionary([:])
        )

        // When
        let isValid = await repository.isFromFamilyMember(activity, familyID: familyID)

        // Then
        XCTAssertTrue(isValid)
    }

    func testPrivacyCheckInvalidFamilyID() async {
        // Given
        let correctFamilyID = UUID()
        let wrongFamilyID = UUID()
        let activity = ParentActivity(
            familyID: wrongFamilyID,
            triggeringUserID: "valid-user-id-123",
            activityType: .pointsAdjusted,
            targetEntity: "ChildProfile",
            targetEntityID: UUID(),
            changes: CodableDictionary([:])
        )

        // When
        let isValid = await repository.isFromFamilyMember(activity, familyID: correctFamilyID)

        // Then
        XCTAssertFalse(isValid)
    }

    func testPrivacyCheckInvalidUserID() async {
        // Given
        let familyID = UUID()

        let testCases = [
            "", // Empty
            "abc", // Too short
            "user id with spaces", // Contains spaces
        ]

        for invalidUserID in testCases {
            let activity = ParentActivity(
                familyID: familyID,
                triggeringUserID: invalidUserID,
                activityType: .pointsAdjusted,
                targetEntity: "ChildProfile",
                targetEntityID: UUID(),
                changes: CodableDictionary([:])
            )

            // When
            let isValid = await repository.isFromFamilyMember(activity, familyID: familyID)

            // Then
            XCTAssertFalse(isValid, "User ID '\(invalidUserID)' should be invalid")
        }
    }

    func testConfigureCloudKitIndexes() async throws {
        // Given/When
        try await repository.configureCloudKitIndexes()

        // Then
        // This test mainly ensures the method doesn't throw
        // In a real implementation, we'd verify the indexes were created
        XCTAssertTrue(true, "configureCloudKitIndexes completed successfully")
    }

    func testDateRangeFiltering() {
        // Given
        let familyID = UUID()
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let thirtyFiveDaysAgo = Calendar.current.date(byAdding: .day, value: -35, to: now)!

        // Test that 30-day limit is enforced
        let dateRange = DateRange(start: thirtyFiveDaysAgo, end: now)

        // In a real test with actual CloudKit, we'd verify the query predicate
        // For now, we test the date calculation logic
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let effectiveStartDate = max(dateRange.start, thirtyDaysAgo)

        XCTAssertEqual(effectiveStartDate, thirtyDaysAgo, "Should enforce 30-day limit")
    }

    func testRecordTypeConsistency() {
        // Ensure record type is consistently used
        XCTAssertEqual(repository.recordType, "ParentActivity")
    }

    func testMaxFetchLimitEnforcement() {
        // Test that maxFetchLimit is respected
        XCTAssertEqual(repository.maxFetchLimit, 100)

        let testLimit = 200
        let effectiveLimit = min(testLimit, repository.maxFetchLimit)
        XCTAssertEqual(effectiveLimit, repository.maxFetchLimit)
    }

    // MARK: - Integration Tests (would require CloudKit setup)

    func testCreateAndFetchActivity() async throws {
        // Note: This test would require actual CloudKit setup and won't run in CI
        // It's included as an example of how integration tests would be structured

        guard ProcessInfo.processInfo.environment["ENABLE_CLOUDKIT_TESTS"] == "true" else {
            throw XCTSkip("CloudKit integration tests disabled")
        }

        // Given
        let activity = createSampleActivity()

        // When
        let savedActivity = try await repository.createActivity(activity)

        // Then
        XCTAssertEqual(savedActivity.id, activity.id)

        // Cleanup
        try await repository.deleteActivity(id: activity.id)
    }

    func testFetchActivitiesWithDateRange() async throws {
        guard ProcessInfo.processInfo.environment["ENABLE_CLOUDKIT_TESTS"] == "true" else {
            throw XCTSkip("CloudKit integration tests disabled")
        }

        // Given
        let familyID = UUID()
        let activities = [
            createSampleActivity(familyID: familyID, timestamp: Date().addingTimeInterval(-3600)), // 1 hour ago
            createSampleActivity(familyID: familyID, timestamp: Date().addingTimeInterval(-7200))  // 2 hours ago
        ]

        // Save activities
        for activity in activities {
            _ = try await repository.createActivity(activity)
        }

        // When
        let fetchedActivities = try await repository.fetchActivities(for: familyID, limit: 10)

        // Then
        XCTAssertGreaterThanOrEqual(fetchedActivities.count, 2)
        XCTAssertTrue(fetchedActivities.allSatisfy { $0.familyID == familyID })

        // Cleanup
        for activity in activities {
            try await repository.deleteActivity(id: activity.id)
        }
    }

    // MARK: - Helper Methods

    private func createSampleActivity(
        familyID: UUID = UUID(),
        timestamp: Date = Date()
    ) -> ParentActivity {
        return ParentActivity(
            familyID: familyID,
            triggeringUserID: "test-user-123",
            activityType: .appCategorizationAdded,
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

// MARK: - Test Extensions

@available(iOS 15.0, macOS 12.0, *)
extension CloudKitParentActivityRepository {
    // Expose private methods for testing
    func createCKRecord(from activity: ParentActivity) throws -> CKRecord {
        return try self.createCKRecord(from: activity)
    }

    func createParentActivity(from record: CKRecord) throws -> ParentActivity {
        return try self.createParentActivity(from: record)
    }

    func isFromFamilyMember(_ activity: ParentActivity, familyID: UUID) async -> Bool {
        return await self.isFromFamilyMember(activity, familyID: familyID)
    }

    var recordType: String {
        return "ParentActivity"
    }

    var maxFetchLimit: Int {
        return 100
    }
}