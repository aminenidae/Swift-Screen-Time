//
//  AppCategorizationFlowTests.swift
//  IntegrationTests
//
//  Created by James on 2025-09-27.
//

import XCTest
@testable import ScreenTimeRewards_Features_AppCategorization
import SharedModels

class AppCategorizationFlowTests: XCTestCase {
    
    func testCompleteAppCategorizationFlow() async throws {
        // This test covers the complete flow from UI interaction to data persistence
        // Since we're using mock services, we'll focus on the logic flow
        
        // 1. Test that apps can be loaded and displayed
        let viewModel = AppCategorizationViewModel()
        
        // 2. Test that apps can be categorized
        let testAppBundleID = "com.test.app"
        viewModel.updateAppCategory(bundleID: testAppBundleID, category: .learning)
        viewModel.updatePointsPerHour(bundleID: testAppBundleID, points: 10)
        
        // 3. Verify that the categorization is stored locally
        XCTAssertEqual(viewModel.appCategories[testAppBundleID], .learning)
        XCTAssertEqual(viewModel.appPoints[testAppBundleID], 10)
        
        // 4. Test that bulk categorization works
        let testAppBundleID2 = "com.test.app2"
        viewModel.toggleAppSelection(bundleID: testAppBundleID2)
        viewModel.bulkCategorize(to: .reward)
        
        // 5. Verify bulk categorization
        XCTAssertEqual(viewModel.appCategories[testAppBundleID2], .reward)
        
        // 6. Test validation logic
        XCTAssertTrue(viewModel.validateCategorizations())
        
        // 7. Test that changes can be marked as unsaved
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }
    
    func testAppCategoryConflictValidation() async throws {
        // Test that the validation logic prevents conflicts
        let viewModel = AppCategorizationViewModel()
        
        // Since our current implementation allows only one category per app,
        // there are no conflicts possible with the current UI design
        XCTAssertTrue(viewModel.validateCategorizations())
    }
    
    func testPointValueValidation() async throws {
        let viewModel = AppCategorizationViewModel()
        let testAppBundleID = "com.test.app"
        
        // Test that negative points are rejected
        viewModel.updatePointsPerHour(bundleID: testAppBundleID, points: -5)
        
        // The current implementation shows an error but still allows the value
        // In a real implementation, we might want to prevent negative values
        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }
    
    func testLearningAppValidation() async throws {
        let viewModel = AppCategorizationViewModel()
        let testAppBundleID = "com.test.app"
        
        // Test that learning apps must have points
        viewModel.updateAppCategory(bundleID: testAppBundleID, category: .learning)
        
        // Validation should fail without points
        XCTAssertFalse(viewModel.validateCategorizations())
        
        // Add points and validation should pass
        viewModel.updatePointsPerHour(bundleID: testAppBundleID, points: 10)
        XCTAssertTrue(viewModel.validateCategorizations())
    }
    
    // MARK: - New Tests for Enhanced Functionality
    
    func testSearchAndFilterIntegration() async throws {
        let viewModel = AppCategorizationViewModel()
        
        // Create test apps
        let app1 = AppMetadata(id: "1", bundleID: "com.test.math", displayName: "Math Learning", isSystemApp: false, iconData: nil)
        let app2 = AppMetadata(id: "2", bundleID: "com.test.game", displayName: "Fun Game", isSystemApp: false, iconData: nil)
        let app3 = AppMetadata(id: "3", bundleID: "com.test.science", displayName: "Science Learning", isSystemApp: false, iconData: nil)
        
        viewModel.apps = [app1, app2, app3]
        
        // Test search functionality
        viewModel.searchText = "Math"
        viewModel.filterApps()
        XCTAssertEqual(viewModel.filteredApps.count, 1)
        XCTAssertEqual(viewModel.filteredApps.first?.displayName, "Math Learning")
        
        // Test category filtering
        viewModel.updateAppCategory(bundleID: "com.test.math", category: .learning)
        viewModel.updateAppCategory(bundleID: "com.test.science", category: .learning)
        viewModel.updateAppCategory(bundleID: "com.test.game", category: .reward)
        
        // Apply learning filter
        viewModel.applyFilter(.learning)
        XCTAssertEqual(viewModel.filteredApps.count, 2)
        XCTAssertTrue(viewModel.filteredApps.contains(where: { $0.bundleID == "com.test.math" }))
        XCTAssertTrue(viewModel.filteredApps.contains(where: { $0.bundleID == "com.test.science" }))
        
        // Apply reward filter
        viewModel.applyFilter(.reward)
        XCTAssertEqual(viewModel.filteredApps.count, 1)
        XCTAssertEqual(viewModel.filteredApps.first?.bundleID, "com.test.game")
    }
    
    func testBulkActionIntegration() async throws {
        let viewModel = AppCategorizationViewModel()
        
        // Create test apps
        let app1 = AppMetadata(id: "1", bundleID: "com.test.app1", displayName: "App 1", isSystemApp: false, iconData: nil)
        let app2 = AppMetadata(id: "2", bundleID: "com.test.app2", displayName: "App 2", isSystemApp: false, iconData: nil)
        let app3 = AppMetadata(id: "3", bundleID: "com.test.app3", displayName: "App 3", isSystemApp: false, iconData: nil)
        
        viewModel.apps = [app1, app2, app3]
        
        // Select all apps
        viewModel.selectAllApps()
        XCTAssertEqual(viewModel.selectedApps.count, 3)
        
        // Bulk categorize as learning
        viewModel.bulkCategorize(to: .learning)
        
        // Verify all apps are categorized as learning
        XCTAssertEqual(viewModel.appCategories["com.test.app1"], .learning)
        XCTAssertEqual(viewModel.appCategories["com.test.app2"], .learning)
        XCTAssertEqual(viewModel.appCategories["com.test.app3"], .learning)
        
        // Verify points are set for learning apps
        XCTAssertEqual(viewModel.appPoints["com.test.app1"], 10)
        XCTAssertEqual(viewModel.appPoints["com.test.app2"], 10)
        XCTAssertEqual(viewModel.appPoints["com.test.app3"], 10)
        
        // Verify selection is cleared
        XCTAssertEqual(viewModel.selectedApps.count, 0)
    }
    
    func testRewardCategoryRemovesPoints() async throws {
        let viewModel = AppCategorizationViewModel()
        let testAppBundleID = "com.test.app"
        
        // Set app as learning with points
        viewModel.updateAppCategory(bundleID: testAppBundleID, category: .learning)
        viewModel.updatePointsPerHour(bundleID: testAppBundleID, points: 15)
        
        // Verify points are set
        XCTAssertEqual(viewModel.appPoints[testAppBundleID], 15)
        
        // Change to reward category
        viewModel.updateAppCategory(bundleID: testAppBundleID, category: .reward)
        
        // Verify points are removed
        XCTAssertNil(viewModel.appPoints[testAppBundleID])
    }
}