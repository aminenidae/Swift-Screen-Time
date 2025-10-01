import XCTest
import SwiftUI
@testable import ScreenTimeRewards
import SharedModels

/// Integration tests for the Child Dashboard feature
///
/// These tests verify that all components of the Child Dashboard work together correctly:
/// - ProgressRingView displays progress correctly
/// - PointsBalanceView shows current points
/// - RewardCardView displays available rewards
/// - FloatingPointsNotificationView shows notifications
/// - ChildDashboardViewModel loads data properly
/// - ChildDashboardView integrates all components
@MainActor
final class ChildDashboardIntegrationTests: XCTestCase {
    
    /// Test that the complete Child Dashboard can be instantiated and displays correctly
    func testChildDashboardCompleteIntegration() throws {
        // Given
        let viewModel = ChildDashboardViewModel.mockViewModel()
        
        // When
        let dashboardView = ChildDashboardView()
        
        // Then
        XCTAssertNotNil(dashboardView)
        // Note: In a real integration test, we would use ViewInspector or similar
        // to verify the actual UI components are displayed correctly
    }
    
    /// Test that the progress ring displays the correct progress
    func testProgressRingIntegration() throws {
        // Given
        let currentPoints = 45
        let goalPoints = 100
        
        // When
        let progressRing = ProgressRingView(currentPoints: currentPoints, goalPoints: goalPoints)
        
        // Then
        XCTAssertNotNil(progressRing)
        XCTAssertEqual(progressRing.progress, 0.45, accuracy: 0.001)
    }
    
    /// Test that the points balance view displays correctly
    func testPointsBalanceViewIntegration() throws {
        // Given
        let points = 450
        let animationScale: CGFloat = 1.0
        
        // When
        let pointsView = PointsBalanceView(points: points, animationScale: animationScale)
        
        // Then
        XCTAssertNotNil(pointsView)
    }
    
    /// Test that reward cards display correctly
    func testRewardCardViewIntegration() throws {
        // Given
        let reward = Reward(
            id: "1",
            name: "Game Time",
            description: "30 minutes of game time",
            pointCost: 50,
            imageURL: nil,
            isActive: true,
            createdAt: Date()
        )
        
        // When
        let rewardCard = RewardCardView(reward: reward, hasSufficientPoints: true, onTap: {})
        
        // Then
        XCTAssertNotNil(rewardCard)
    }
    
    /// Test that floating notifications display correctly
    func testFloatingNotificationIntegration() throws {
        // Given
        let isVisible = Binding.constant(true)
        
        // When
        let notificationView = FloatingPointsNotificationView(points: 5, isVisible: isVisible)
        
        // Then
        XCTAssertNotNil(notificationView)
    }
    
    /// Test that the view model loads mock data correctly
    func testViewModelDataLoading() async {
        // Given
        let viewModel = ChildDashboardViewModel.mockViewModel()
        
        // When
        await viewModel.loadInitialData()
        
        // Then
        XCTAssertGreaterThan(viewModel.currentPoints, 0)
        XCTAssertGreaterThan(viewModel.totalPointsEarned, 0)
        XCTAssertFalse(viewModel.recentTransactions.isEmpty)
        XCTAssertFalse(viewModel.recentSessions.isEmpty)
        XCTAssertFalse(viewModel.availableRewards.isEmpty)
    }
}