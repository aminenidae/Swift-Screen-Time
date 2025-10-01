//
//  AppCategorizationViewModelTests.swift
//  ScreenTimeRewardsTests
//
//  Created by James on 2025-09-27.
//

import XCTest
@testable import ScreenTimeRewards_Features_AppCategorization
import SharedModels

class AppCategorizationViewModelTests: XCTestCase {
    
    var viewModel: AppCategorizationViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = AppCategorizationViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertTrue(viewModel.apps.isEmpty)
        XCTAssertTrue(viewModel.filteredApps.isEmpty)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }
    
    func testUpdateAppCategory() {
        let bundleID = "com.test.app"
        viewModel.updateAppCategory(bundleID: bundleID, category: .learning)
        
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.appCategories[bundleID], .learning)
    }
    
    func testUpdatePointsPerHour() {
        let bundleID = "com.test.app"
        viewModel.updatePointsPerHour(bundleID: bundleID, points: 10)
        
        XCTAssertTrue(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.appPoints[bundleID], 10)
    }
    
    func testUpdatePointsPerHourWithNegativeValue() {
        let bundleID = "com.test.app"
        viewModel.updatePointsPerHour(bundleID: bundleID, points: -5)
        
        // Should not update with negative value
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertNil(viewModel.appPoints[bundleID])
    }
    
    func testFilterApps() {
        let app1 = AppMetadata(id: "1", bundleID: "com.test.app1", displayName: "Test App 1", isSystemApp: false, iconData: nil)
        let app2 = AppMetadata(id: "2", bundleID: "com.test.app2", displayName: "Test App 2", isSystemApp: false, iconData: nil)
        
        viewModel.apps = [app1, app2]
        viewModel.filterApps()
        
        XCTAssertEqual(viewModel.filteredApps.count, 2)
        
        viewModel.searchText = "Test App 1"
        viewModel.filterApps()
        
        XCTAssertEqual(viewModel.filteredApps.count, 1)
        XCTAssertEqual(viewModel.filteredApps.first?.displayName, "Test App 1")
    }
    
    func testValidateCategorizations() {
        // In the current implementation, validation returns true when there are no learning apps
        XCTAssertTrue(viewModel.validateCategorizations())
    }
    
    func testValidateCategorizationsWithLearningAppWithoutPoints() {
        let bundleID = "com.test.app"
        viewModel.updateAppCategory(bundleID: bundleID, category: .learning)
        
        // Learning app without points should fail validation
        XCTAssertFalse(viewModel.validateCategorizations())
    }
    
    func testValidateCategorizationsWithLearningAppWithPoints() {
        let bundleID = "com.test.app"
        viewModel.updateAppCategory(bundleID: bundleID, category: .learning)
        viewModel.updatePointsPerHour(bundleID: bundleID, points: 10)
        
        // Learning app with points should pass validation
        XCTAssertTrue(viewModel.validateCategorizations())
    }
    
    // MARK: - New Tests for Enhanced Functionality
    
    func testToggleAppSelection() {
        let bundleID = "com.test.app"
        XCTAssertFalse(viewModel.selectedApps.contains(bundleID))
        
        viewModel.toggleAppSelection(bundleID: bundleID)
        XCTAssertTrue(viewModel.selectedApps.contains(bundleID))
        
        viewModel.toggleAppSelection(bundleID: bundleID)
        XCTAssertFalse(viewModel.selectedApps.contains(bundleID))
    }
    
    func testSelectAllApps() {
        let app1 = AppMetadata(id: "1", bundleID: "com.test.app1", displayName: "Test App 1", isSystemApp: false, iconData: nil)
        let app2 = AppMetadata(id: "2", bundleID: "com.test.app2", displayName: "Test App 2", isSystemApp: false, iconData: nil)
        
        viewModel.apps = [app1, app2]
        viewModel.selectAllApps()
        
        XCTAssertEqual(viewModel.selectedApps.count, 2)
        XCTAssertTrue(viewModel.selectedApps.contains("com.test.app1"))
        XCTAssertTrue(viewModel.selectedApps.contains("com.test.app2"))
    }
    
    func testClearSelection() {
        let bundleID = "com.test.app"
        viewModel.selectedApps.insert(bundleID)
        XCTAssertTrue(viewModel.selectedApps.contains(bundleID))
        
        viewModel.clearSelection()
        XCTAssertFalse(viewModel.selectedApps.contains(bundleID))
        XCTAssertEqual(viewModel.selectedApps.count, 0)
    }
    
    func testBulkCategorize() {
        let app1 = AppMetadata(id: "1", bundleID: "com.test.app1", displayName: "Test App 1", isSystemApp: false, iconData: nil)
        let app2 = AppMetadata(id: "2", bundleID: "com.test.app2", displayName: "Test App 2", isSystemApp: false, iconData: nil)
        
        viewModel.apps = [app1, app2]
        viewModel.selectedApps = ["com.test.app1", "com.test.app2"]
        
        viewModel.bulkCategorize(to: .learning)
        
        XCTAssertEqual(viewModel.appCategories["com.test.app1"], .learning)
        XCTAssertEqual(viewModel.appCategories["com.test.app2"], .learning)
        XCTAssertEqual(viewModel.appPoints["com.test.app1"], 10)
        XCTAssertEqual(viewModel.appPoints["com.test.app2"], 10)
        XCTAssertEqual(viewModel.selectedApps.count, 0) // Selection should be cleared
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }
    
    func testUpdateAppCategoryToRewardRemovesPoints() {
        let bundleID = "com.test.app"
        viewModel.updateAppCategory(bundleID: bundleID, category: .learning)
        viewModel.updatePointsPerHour(bundleID: bundleID, points: 10)
        
        // Verify points are set
        XCTAssertEqual(viewModel.appPoints[bundleID], 10)
        
        // Change category to reward
        viewModel.updateAppCategory(bundleID: bundleID, category: .reward)
        
        // Verify points are removed
        XCTAssertNil(viewModel.appPoints[bundleID])
    }
}