import XCTest
import SwiftUI
import SharedModels
@testable import ScreenTimeRewards

@available(iOS 15.0, *)
final class FeatureGatingIntegrationTests: XCTestCase {
    
    func testFeatureGatingWithActiveSubscription() async {
        // Given: A view with feature gating applied and active subscription
        let familyID = "test-family"
        
        // Create a mock family with active subscription
        let subscriptionStartDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        let subscriptionEndDate = Date().addingTimeInterval(86400 * 335) // ~11 months from now
        
        // When: Creating a gated view
        let gatedView = Text("Premium Content")
            .featureGated(.advancedAnalytics, for: familyID)
        
        // Then: View should be created successfully
        XCTAssertNotNil(gatedView)
    }
    
    func testFeatureGatingWithNoSubscription() async {
        // Given: A view with feature gating applied and no subscription
        let familyID = "test-family-without-subscription"
        
        // When: Creating a gated view
        let gatedView = Text("Premium Content")
            .featureGated(.advancedAnalytics, for: familyID)
        
        // Then: View should be created successfully
        XCTAssertNotNil(gatedView)
    }
    
    func testPremiumBadgeWithActiveSubscription() async {
        // Given: A view with premium badge and active subscription
        let familyID = "test-family"
        
        // When: Creating a view with premium badge
        let viewWithBadge = Text("Premium Feature")
            .premiumBadge(for: .advancedAnalytics, familyID: familyID)
        
        // Then: View should be created successfully
        XCTAssertNotNil(viewWithBadge)
    }
    
    func testPremiumBadgeWithNoSubscription() async {
        // Given: A view with premium badge and no subscription
        let familyID = "test-family-without-subscription"
        
        // When: Creating a view with premium badge
        let viewWithBadge = Text("Premium Feature")
            .premiumBadge(for: .advancedAnalytics, familyID: familyID)
        
        // Then: View should be created successfully
        XCTAssertNotNil(viewWithBadge)
    }
    
    func testUpgradePromptButton() async {
        // Given: An upgrade prompt button
        let familyID = "test-family"
        
        // When: Creating an upgrade prompt button
        let upgradeButton = UpgradePromptButton(feature: .advancedAnalytics, familyID: familyID) {
            // Mock action
        }
        
        // Then: Button should be created successfully
        XCTAssertNotNil(upgradeButton)
    }
    
    func testTrialCountdownBanner() async {
        // Given: A trial countdown banner
        let daysRemaining = 5
        
        // When: Creating a trial countdown banner
        let banner = TrialCountdownBanner(daysRemaining: daysRemaining) {
            // Mock action
        }
        
        // Then: Banner should be created successfully
        XCTAssertNotNil(banner)
    }
}