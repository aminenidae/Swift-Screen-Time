import XCTest
import SwiftUI
import ViewInspector
@testable import ScreenTimeRewards

final class PointsBalanceViewTests: XCTestCase {
    
    func testPointsBalanceView_Initialization() throws {
        let view = PointsBalanceView(points: 450, animationScale: 1.0)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
    }
    
    func testPointsBalanceView_WithDifferentPointValues() throws {
        // Test with zero points
        let view1 = PointsBalanceView(points: 0, animationScale: 1.0)
        XCTAssertNotNil(view1)
        
        // Test with large point value
        let view2 = PointsBalanceView(points: 10000, animationScale: 1.0)
        XCTAssertNotNil(view2)
        
        // Test with negative points
        let view3 = PointsBalanceView(points: -50, animationScale: 1.0)
        XCTAssertNotNil(view3)
    }
    
    func testPointsBalanceView_WithDifferentAnimationScales() throws {
        // Test with normal scale
        let view1 = PointsBalanceView(points: 450, animationScale: 1.0)
        XCTAssertNotNil(view1)
        
        // Test with scaled up
        let view2 = PointsBalanceView(points: 450, animationScale: 1.2)
        XCTAssertNotNil(view2)
        
        // Test with scaled down
        let view3 = PointsBalanceView(points: 450, animationScale: 0.8)
        XCTAssertNotNil(view3)
        
        // Test with zero scale
        let view4 = PointsBalanceView(points: 450, animationScale: 0.0)
        XCTAssertNotNil(view4)
    }
}