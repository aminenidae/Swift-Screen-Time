//
//  FilterBarViewTests.swift
//  ScreenTimeRewardsTests
//
//  Created by James on 2025-09-27.
//

import XCTest
import SwiftUI
import SharedModels

final class FilterBarViewTests: XCTestCase {
    
    func testFilterBarViewRendersAllFilters() throws {
        let filterBar = FilterBarView(selectedFilter: .constant(.all))
        
        // Test that the view renders without crashing
        XCTAssertNotNil(filterBar)
    }
    
    func testFilterBarViewHasCorrectFilters() throws {
        XCTAssertEqual(AppFilter.allCases.count, 3)
        XCTAssertTrue(AppFilter.allCases.contains(.all))
        XCTAssertTrue(AppFilter.allCases.contains(.learning))
        XCTAssertTrue(AppFilter.allCases.contains(.reward))
    }
    
    func testFilterTitlesAreCorrect() throws {
        XCTAssertEqual(AppFilter.all.title, "All")
        XCTAssertEqual(AppFilter.learning.title, "Learning")
        XCTAssertEqual(AppFilter.reward.title, "Reward")
    }
}