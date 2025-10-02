import XCTest
@testable import SharedModels

final class ParentActivityTests: XCTestCase {

    func testParentActivityInitialization() {
        // Given
        let id = UUID()
        let familyID = UUID()
        let triggeringUserID = "test-user-123"
        let activityType = ParentActivityType.appCategorizationAdded
        let targetEntity = "AppCategorization"
        let targetEntityID = UUID()
        let changes = CodableDictionary(["appName": "Khan Academy", "category": "Learning"])
        let timestamp = Date()
        let deviceID = "iPhone123"

        // When
        let activity = ParentActivity(
            id: id,
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: activityType,
            targetEntity: targetEntity,
            targetEntityID: targetEntityID,
            changes: changes,
            timestamp: timestamp,
            deviceID: deviceID
        )

        // Then
        XCTAssertEqual(activity.id, id)
        XCTAssertEqual(activity.familyID, familyID)
        XCTAssertEqual(activity.triggeringUserID, triggeringUserID)
        XCTAssertEqual(activity.activityType, activityType)
        XCTAssertEqual(activity.targetEntity, targetEntity)
        XCTAssertEqual(activity.targetEntityID, targetEntityID)
        XCTAssertEqual(activity.changes.dictionary, changes.dictionary)
        XCTAssertEqual(activity.timestamp, timestamp)
        XCTAssertEqual(activity.deviceID, deviceID)
    }

    func testParentActivityDefaultValues() {
        // Given/When
        let activity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user",
            activityType: .pointsAdjusted,
            targetEntity: "ChildProfile",
            targetEntityID: UUID(),
            changes: CodableDictionary([:])
        )

        // Then
        XCTAssertNotNil(activity.id)
        XCTAssertNil(activity.deviceID)
        XCTAssertLessThanOrEqual(activity.timestamp.timeIntervalSinceNow, 1) // Created within last second
    }

    func testParentActivityTypeDisplayNames() {
        // Test all activity type display names
        XCTAssertEqual(ParentActivityType.appCategorizationAdded.displayName, "App Added to Category")
        XCTAssertEqual(ParentActivityType.appCategorizationModified.displayName, "App Category Modified")
        XCTAssertEqual(ParentActivityType.appCategorizationRemoved.displayName, "App Removed from Category")
        XCTAssertEqual(ParentActivityType.pointsAdjusted.displayName, "Points Adjusted")
        XCTAssertEqual(ParentActivityType.rewardRedeemed.displayName, "Reward Redeemed")
        XCTAssertEqual(ParentActivityType.childProfileModified.displayName, "Child Profile Updated")
        XCTAssertEqual(ParentActivityType.settingsUpdated.displayName, "Settings Updated")
        XCTAssertEqual(ParentActivityType.childAdded.displayName, "Child Added")
    }

    func testParentActivityTypeIcons() {
        // Test all activity type icons
        XCTAssertEqual(ParentActivityType.appCategorizationAdded.icon, "apps.iphone")
        XCTAssertEqual(ParentActivityType.appCategorizationModified.icon, "apps.iphone")
        XCTAssertEqual(ParentActivityType.appCategorizationRemoved.icon, "apps.iphone")
        XCTAssertEqual(ParentActivityType.pointsAdjusted.icon, "star.fill")
        XCTAssertEqual(ParentActivityType.rewardRedeemed.icon, "gift.fill")
        XCTAssertEqual(ParentActivityType.childProfileModified.icon, "person.fill")
        XCTAssertEqual(ParentActivityType.settingsUpdated.icon, "gearshape.fill")
        XCTAssertEqual(ParentActivityType.childAdded.icon, "person.badge.plus.fill")
    }

    func testParentActivityRelativeTimestamp() {
        // Given
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let activity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user",
            activityType: .pointsAdjusted,
            targetEntity: "ChildProfile",
            targetEntityID: UUID(),
            changes: CodableDictionary([:]),
            timestamp: oneHourAgo
        )

        // When
        let relativeTimestamp = activity.relativeTimestamp

        // Then
        XCTAssertTrue(relativeTimestamp.contains("ago") || relativeTimestamp.contains("hour"))
    }

    func testParentActivityDetailedDescriptions() {
        // Test app categorization added
        let appAddedActivity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user",
            activityType: .appCategorizationAdded,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "appName": "Khan Academy",
                "category": "Learning"
            ])
        )

        XCTAssertEqual(
            appAddedActivity.detailedDescription,
            "Khan Academy was added to Learning category"
        )

        // Test app categorization modified
        let appModifiedActivity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user",
            activityType: .appCategorizationModified,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "appName": "YouTube",
                "oldCategory": "Learning",
                "newCategory": "Reward"
            ])
        )

        XCTAssertEqual(
            appModifiedActivity.detailedDescription,
            "YouTube moved from Learning to Reward"
        )

        // Test points adjusted
        let pointsActivity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user",
            activityType: .pointsAdjusted,
            targetEntity: "ChildProfile",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "childName": "Emma",
                "pointsChange": "+50",
                "reason": "Good behavior"
            ])
        )

        XCTAssertEqual(
            pointsActivity.detailedDescription,
            "Emma's points adjusted by +50 (Good behavior)"
        )

        // Test reward redeemed
        let rewardActivity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user",
            activityType: .rewardRedeemed,
            targetEntity: "Reward",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "childName": "Alex",
                "rewardName": "Extra Screen Time",
                "pointsSpent": "100"
            ])
        )

        XCTAssertEqual(
            rewardActivity.detailedDescription,
            "Alex redeemed Extra Screen Time for 100 points"
        )

        // Test child added
        let childAddedActivity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user",
            activityType: .childAdded,
            targetEntity: "ChildProfile",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "childName": "Sophie"
            ])
        )

        XCTAssertEqual(
            childAddedActivity.detailedDescription,
            "Sophie was added to the family"
        )
    }

    func testCodableDictionary() {
        // Given
        let originalDict = ["key1": "value1", "key2": "value2"]
        let codableDict = CodableDictionary(originalDict)

        // When/Then
        XCTAssertEqual(codableDict.dictionary, originalDict)
        XCTAssertEqual(codableDict["key1"], "value1")
        XCTAssertEqual(codableDict["key2"], "value2")
        XCTAssertNil(codableDict["nonexistent"])
    }

    func testParentActivityCodable() throws {
        // Given
        let originalActivity = ParentActivity(
            familyID: UUID(),
            triggeringUserID: "test-user-123",
            activityType: .appCategorizationAdded,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(),
            changes: CodableDictionary([
                "appName": "Khan Academy",
                "category": "Learning"
            ]),
            deviceID: "iPhone123"
        )

        // When
        let encoded = try JSONEncoder().encode(originalActivity)
        let decoded = try JSONDecoder().decode(ParentActivity.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.id, originalActivity.id)
        XCTAssertEqual(decoded.familyID, originalActivity.familyID)
        XCTAssertEqual(decoded.triggeringUserID, originalActivity.triggeringUserID)
        XCTAssertEqual(decoded.activityType, originalActivity.activityType)
        XCTAssertEqual(decoded.targetEntity, originalActivity.targetEntity)
        XCTAssertEqual(decoded.targetEntityID, originalActivity.targetEntityID)
        XCTAssertEqual(decoded.changes.dictionary, originalActivity.changes.dictionary)
        XCTAssertEqual(decoded.deviceID, originalActivity.deviceID)
        // Note: Timestamp comparison might have slight precision differences
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, originalActivity.timestamp.timeIntervalSince1970, accuracy: 1)
    }

    func testParentActivityTypeAllCases() {
        // Ensure all cases are covered
        let allCases = ParentActivityType.allCases
        XCTAssertEqual(allCases.count, 8)

        XCTAssertTrue(allCases.contains(.appCategorizationAdded))
        XCTAssertTrue(allCases.contains(.appCategorizationModified))
        XCTAssertTrue(allCases.contains(.appCategorizationRemoved))
        XCTAssertTrue(allCases.contains(.pointsAdjusted))
        XCTAssertTrue(allCases.contains(.rewardRedeemed))
        XCTAssertTrue(allCases.contains(.childProfileModified))
        XCTAssertTrue(allCases.contains(.settingsUpdated))
        XCTAssertTrue(allCases.contains(.childAdded))
    }
}