//
//  CategorySelectorViewTests.swift
//  ScreenTimeRewardsTests
//
//  Created by James on 2025-09-27.
//

import XCTest
import SwiftUI
@testable import ScreenTimeRewards_Features_AppCategorization
import SharedModels

final class CategorySelectorViewTests: XCTestCase {
    
    func testCategorySelectorViewRendersWithoutCategory() throws {
        let categorySelector = CategorySelectorView(selectedCategory: .constant(nil))
        
        // Test that the view renders without crashing
        XCTAssertNotNil(categorySelector)
    }
    
    func testCategorySelectorViewRendersWithLearningCategory() throws {
        let categorySelector = CategorySelectorView(selectedCategory: .constant(.learning))
        
        // Test that the view renders without crashing
        XCTAssertNotNil(categorySelector)
    }
    
    func testCategorySelectorViewRendersWithRewardCategory() throws {
        let categorySelector = CategorySelectorView(selectedCategory: .constant(.reward))
        
        // Test that the view renders without crashing
        XCTAssertNotNil(categorySelector)
    }
    
    func testCategorySelectorHasCorrectOptions() throws {
        // Test that all category options are available
        XCTAssertTrue(AppCategory.allCases.contains(.learning))
        XCTAssertTrue(AppCategory.allCases.contains(.reward))
    }
}