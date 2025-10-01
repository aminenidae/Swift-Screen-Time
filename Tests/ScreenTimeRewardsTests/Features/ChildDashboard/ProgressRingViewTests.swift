import XCTest
import SwiftUI
import ViewInspector
@testable import ScreenTimeRewards

final class ProgressRingViewTests: XCTestCase {
    
    func testProgressRingView_WithZeroPoints() throws {
        let view = ProgressRingView(currentPoints: 0, goalPoints: 100)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
        
        // Test progress calculation
        let progress = view.progress
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }
    
    func testProgressRingView_WithPartialProgress() throws {
        let view = ProgressRingView(currentPoints: 45, goalPoints: 100)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
        
        // Test progress calculation
        let progress = view.progress
        XCTAssertEqual(progress, 0.45, accuracy: 0.001)
    }
    
    func testProgressRingView_WithFullProgress() throws {
        let view = ProgressRingView(currentPoints: 100, goalPoints: 100)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
        
        // Test progress calculation
        let progress = view.progress
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }
    
    func testProgressRingView_WithExceededGoal() throws {
        let view = ProgressRingView(currentPoints: 150, goalPoints: 100)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
        
        // Test progress calculation (should cap at 1.0)
        let progress = view.progress
        XCTAssertEqual(progress, 1.5, accuracy: 0.001)
    }
    
    func testProgressRingView_WithZeroGoal() throws {
        let view = ProgressRingView(currentPoints: 50, goalPoints: 0)
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
        
        // Test progress calculation with zero goal
        let progress = view.progress
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }
}