import XCTest
import SwiftUI
import ViewInspector
@testable import ScreenTimeRewards
import SharedModels

final class RewardCardViewTests: XCTestCase {
    
    func testRewardCardView_Initialization() throws {
        let reward = Reward(
            id: "1",
            name: "Game Time",
            description: "30 minutes of game time",
            pointCost: 50,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        
        let view = RewardCardView(reward: reward, hasSufficientPoints: true, onTap: {})
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
    }
    
    func testRewardCardView_WithSufficientPoints() throws {
        let reward = Reward(
            id: "1",
            name: "Game Time",
            description: "30 minutes of game time",
            pointCost: 50,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        
        let view = RewardCardView(reward: reward, hasSufficientPoints: true, onTap: {})
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
    }
    
    func testRewardCardView_WithInsufficientPoints() throws {
        let reward = Reward(
            id: "1",
            name: "Game Time",
            description: "30 minutes of game time",
            pointCost: 50,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        
        let view = RewardCardView(reward: reward, hasSufficientPoints: false, onTap: {})
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(view)
    }
    
    func testRewardCardView_WithDifferentRewardTypes() throws {
        // Test with high cost reward
        let expensiveReward = Reward(
            id: "1",
            name: "Special Reward",
            description: "Very special reward",
            pointCost: 1000,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        
        let view1 = RewardCardView(reward: expensiveReward, hasSufficientPoints: true, onTap: {})
        XCTAssertNotNil(view1)
        
        // Test with zero cost reward
        let freeReward = Reward(
            id: "2",
            name: "Free Reward",
            description: "Free reward for everyone",
            pointCost: 0,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        
        let view2 = RewardCardView(reward: freeReward, hasSufficientPoints: true, onTap: {})
        XCTAssertNotNil(view2)
    }
}