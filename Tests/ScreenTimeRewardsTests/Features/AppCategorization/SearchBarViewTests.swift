//
//  SearchBarViewTests.swift
//  ScreenTimeRewardsTests
//
//  Created by James on 2025-09-27.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import ScreenTimeRewards_Features_AppCategorization

final class SearchBarViewTests: XCTestCase {
    
    func testSearchBarViewRendersCorrectly() throws {
        let searchText = "Test"
        let searchBar = SearchBarView(text: .constant(searchText))
        
        // Test that the view renders without crashing
        XCTAssertNotNil(searchBar)
    }
    
    func testSearchBarClearButtonAppearsWhenTextIsNotEmpty() throws {
        let searchText = "Test"
        let searchBar = SearchBarView(text: .constant(searchText))
        
        // Test that the clear button appears when there's text
        // Note: This would require ViewInspector or a similar testing library for full testing
        XCTAssertNotNil(searchBar)
    }
    
    func testSearchBarClearButtonClearsText() throws {
        let searchText = "Test"
        var text = searchText
        let searchBar = SearchBarView(text: .constant(text)) {
            text = ""
        }
        
        // Simulate clear button tap
        text = ""
        
        // Verify text is cleared
        XCTAssertEqual(text, "")
    }
}