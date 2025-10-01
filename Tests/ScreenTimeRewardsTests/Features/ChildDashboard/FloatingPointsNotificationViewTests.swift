import XCTest
import SwiftUI
import ViewInspector
@testable import ScreenTimeRewards

final class FloatingPointsNotificationViewTests: XCTestCase {
    
    func testFloatingPointsNotificationView_WhenVisible() throws {
        let isVisible = Binding.constant(true)
        let view = FloatingPointsNotificationView(points: 5, isVisible: isVisible)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
    }
    
    func testFloatingPointsNotificationView_WhenNotVisible() throws {
        let isVisible = Binding.constant(false)
        let view = FloatingPointsNotificationView(points: 5, isVisible: isVisible)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
    }
    
    func testFloatingPointsNotificationView_WithDifferentPointValues() throws {
        let isVisible = Binding.constant(true)
        
        // Test with small positive value
        let view1 = FloatingPointsNotificationView(points: 1, isVisible: isVisible)
        XCTAssertNotNil(view1)
        
        // Test with larger positive value
        let view2 = FloatingPointsNotificationView(points: 100, isVisible: isVisible)
        XCTAssertNotNil(view2)
        
        // Test with zero points
        let view3 = FloatingPointsNotificationView(points: 0, isVisible: isVisible)
        XCTAssertNotNil(view3)
    }
}