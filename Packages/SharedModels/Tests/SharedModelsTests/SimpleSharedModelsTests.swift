import XCTest
@testable import SharedModels

final class SimpleSharedModelsTests: XCTestCase {
    
    func testAppCategoryCreation() {
        let learningCategory = AppCategory.learning
        XCTAssertEqual(learningCategory.rawValue, "Learning")
        
        let rewardCategory = AppCategory.reward
        XCTAssertEqual(rewardCategory.rawValue, "Reward")
    }
    
    func testAppMetadataCreation() {
        let appMetadata = AppMetadata(
            id: "test-id",
            bundleID: "com.example.app",
            displayName: "Test App",
            isSystemApp: false,
            iconData: nil
        )
        
        XCTAssertEqual(appMetadata.id, "test-id")
        XCTAssertEqual(appMetadata.bundleID, "com.example.app")
        XCTAssertEqual(appMetadata.displayName, "Test App")
        XCTAssertEqual(appMetadata.isSystemApp, false)
        XCTAssertNil(appMetadata.iconData)
    }
    
    func testAppCategorizationCreation() {
        let now = Date()
        let appCategorization = AppCategorization(
            id: "test-id",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child-123",
            pointsPerHour: 10,
            createdAt: now,
            updatedAt: now
        )
        
        XCTAssertEqual(appCategorization.id, "test-id")
        XCTAssertEqual(appCategorization.appBundleID, "com.example.app")
        XCTAssertEqual(appCategorization.category, .learning)
        XCTAssertEqual(appCategorization.childProfileID, "child-123")
        XCTAssertEqual(appCategorization.pointsPerHour, 10)
        XCTAssertEqual(appCategorization.createdAt, now)
        XCTAssertEqual(appCategorization.updatedAt, now)
    }
}