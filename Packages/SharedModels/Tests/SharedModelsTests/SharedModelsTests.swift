import XCTest
@testable import SharedModels

final class SharedModelsTests: XCTestCase {
    
    func testAppCategoryInitialization() {
        XCTAssertEqual(AppCategory.learning.rawValue, "Learning")
        XCTAssertEqual(AppCategory.reward.rawValue, "Reward")
    }
    
    func testAppMetadataInitialization() {
        let appMetadata = AppMetadata(
            id: "1",
            bundleID: "com.example.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: nil
        )
        
        XCTAssertEqual(appMetadata.id, "1")
        XCTAssertEqual(appMetadata.bundleID, "com.example.app")
        XCTAssertEqual(appMetadata.displayName, "Test App")
        XCTAssertEqual(appMetadata.isSystemApp, false)
        XCTAssertNil(appMetadata.iconData)
    }
    
    func testAppCategorizationInitialization() {
        let now = Date()
        let appCategorization = AppCategorization(
            id: "1",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child1",
            pointsPerHour: 10,
            createdAt: now,
            updatedAt: now
        )
        
        XCTAssertEqual(appCategorization.id, "1")
        XCTAssertEqual(appCategorization.appBundleID, "com.example.app")
        XCTAssertEqual(appCategorization.category, .learning)
        XCTAssertEqual(appCategorization.childProfileID, "child1")
        XCTAssertEqual(appCategorization.pointsPerHour, 10)
        XCTAssertEqual(appCategorization.createdAt, now)
        XCTAssertEqual(appCategorization.updatedAt, now)
    }
    
    func testAppCategoryCodable() throws {
        let category = AppCategory.learning
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)
        let decodedCategory = try JSONDecoder().decode(AppCategory.self, from: data)
        
        XCTAssertEqual(category, decodedCategory)
    }
    
    func testAppMetadataCodable() throws {
        let appMetadata = AppMetadata(
            id: "1",
            bundleID: "com.example.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(appMetadata)
        let decodedAppMetadata = try JSONDecoder().decode(AppMetadata.self, from: data)
        
        XCTAssertEqual(appMetadata, decodedAppMetadata)
    }
    
    func testAppCategorizationCodable() throws {
        let now = Date()
        let appCategorization = AppCategorization(
            id: "1",
            appBundleID: "com.example.app",
            category: .reward,
            childProfileID: "child1",
            pointsPerHour: 5,
            createdAt: now,
            updatedAt: now
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(appCategorization)
        let decodedAppCategorization = try JSONDecoder().decode(AppCategorization.self, from: data)
        
        XCTAssertEqual(appCategorization, decodedAppCategorization)
    }

    func testSubscriptionMetadataInitialization() {
        let metadata = SubscriptionMetadata()

        XCTAssertNil(metadata.trialStartDate)
        XCTAssertNil(metadata.trialEndDate)
        XCTAssertFalse(metadata.hasUsedTrial)
        XCTAssertNil(metadata.subscriptionStartDate)
        XCTAssertNil(metadata.subscriptionEndDate)
        XCTAssertFalse(metadata.isActive)
    }

    func testSubscriptionMetadataWithTrialData() {
        let trialStart = Date()
        let trialEnd = Calendar.current.date(byAdding: .day, value: 14, to: trialStart)!

        let metadata = SubscriptionMetadata(
            trialStartDate: trialStart,
            trialEndDate: trialEnd,
            hasUsedTrial: true
        )

        XCTAssertEqual(metadata.trialStartDate, trialStart)
        XCTAssertEqual(metadata.trialEndDate, trialEnd)
        XCTAssertTrue(metadata.hasUsedTrial)
        XCTAssertFalse(metadata.isActive)
    }

    func testFamilyWithSubscriptionMetadata() throws {
        let metadata = SubscriptionMetadata(
            trialStartDate: Date(),
            trialEndDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
            hasUsedTrial: true
        )

        let family = Family(
            id: "family1",
            name: "Test Family",
            createdAt: Date(),
            ownerUserID: "user1",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            subscriptionMetadata: metadata
        )

        XCTAssertNotNil(family.subscriptionMetadata)
        XCTAssertTrue(family.subscriptionMetadata?.hasUsedTrial ?? false)

        // Test Codable
        let encoder = JSONEncoder()
        let data = try encoder.encode(family)
        let decodedFamily = try JSONDecoder().decode(Family.self, from: data)

        XCTAssertEqual(family.id, decodedFamily.id)
        XCTAssertEqual(family.subscriptionMetadata?.hasUsedTrial, decodedFamily.subscriptionMetadata?.hasUsedTrial)
    }
}