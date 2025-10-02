import XCTest
import SwiftUI
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, macOS 12.0, *)
final class FeatureGatingViewModifiersTests: XCTestCase {

    func testFeatureGatedViewModifierInitialization() {
        // Given: A test view with feature gating modifier
        let testView = Text("Test Content")
            .featureGated(Feature.advancedAnalytics, for: "test-family")

        // Then: View should be created without error
        XCTAssertNotNil(testView)
    }

    func testPremiumBadgeModifierInitialization() {
        // Given: A test view with premium badge modifier
        let testView = Text("Test Content")
            .premiumBadge(for: Feature.advancedAnalytics, familyID: "test-family")

        // Then: View should be created without error
        XCTAssertNotNil(testView)
    }

    func testPremiumFeatureLockOverlayCreation() {
        // When: Creating PremiumFeatureLockOverlay
        let overlay = PremiumFeatureLockOverlay()

        // Then: View should be created without error
        XCTAssertNotNil(overlay)
    }

    func testPremiumBadgeCreation() {
        // When: Creating PremiumBadge
        let badge = PremiumBadge()

        // Then: View should be created without error
        XCTAssertNotNil(badge)
    }

    func testUpgradePromptButtonCreation() {
        // When: Creating UpgradePromptButton
        let button = UpgradePromptButton(feature: Feature.advancedAnalytics, familyID: "test-family") {
            // Mock action
        }

        // Then: View should be created without error
        XCTAssertNotNil(button)
    }

    func testTrialCountdownBannerCreation() {
        // When: Creating TrialCountdownBanner
        let banner = TrialCountdownBanner(daysRemaining: 5) {
            // Mock action
        }

        // Then: View should be created without error
        XCTAssertNotNil(banner)
    }

    // MARK: - PaywallContext Tests

    func testPaywallContextTitle() {
        XCTAssertEqual(PaywallContext.childLimitExceeded(currentCount: 1).title, "Add More Children")
        XCTAssertEqual(PaywallContext.premiumAnalytics.title, "Unlock Advanced Analytics")
        XCTAssertEqual(PaywallContext.exportReports.title, "Export Your Reports")
        XCTAssertEqual(PaywallContext.multiParentInvitations.title, "Invite Multiple Parents")
        XCTAssertEqual(PaywallContext.trialExpiration.title, "Your Trial is Ending")
        XCTAssertEqual(PaywallContext.subscriptionExpired.title, "Subscription Expired")
        XCTAssertEqual(PaywallContext.reSubscribe.title, "Welcome Back!")
        XCTAssertEqual(PaywallContext.noSubscription.title, "Unlock Premium Features")
    }

    func testPaywallContextMessage() {
        XCTAssertTrue(PaywallContext.childLimitExceeded(currentCount: 2).message.contains("2 child profiles"))
        XCTAssertTrue(PaywallContext.premiumAnalytics.message.contains("detailed insights"))
        XCTAssertTrue(PaywallContext.exportReports.message.contains("Export your family's screen time reports"))
        XCTAssertTrue(PaywallContext.multiParentInvitations.message.contains("Invite multiple parents"))
        XCTAssertTrue(PaywallContext.trialExpiration.message.contains("free trial is ending"))
        XCTAssertTrue(PaywallContext.subscriptionExpired.message.contains("subscription has expired"))
        XCTAssertTrue(PaywallContext.reSubscribe.message.contains("Reactivate your subscription"))
        XCTAssertTrue(PaywallContext.noSubscription.message.contains("Start your free trial"))
    }

    func testPaywallContextPrimaryButtonTitle() {
        XCTAssertEqual(PaywallContext.childLimitExceeded(currentCount: 1).primaryButtonTitle, "Upgrade Plan")
        XCTAssertEqual(PaywallContext.premiumAnalytics.primaryButtonTitle, "Unlock with Premium")
        XCTAssertEqual(PaywallContext.exportReports.primaryButtonTitle, "Unlock with Premium")
        XCTAssertEqual(PaywallContext.multiParentInvitations.primaryButtonTitle, "Unlock with Premium")
        XCTAssertEqual(PaywallContext.trialExpiration.primaryButtonTitle, "Subscribe Now")
        XCTAssertEqual(PaywallContext.subscriptionExpired.primaryButtonTitle, "Renew Subscription")
        XCTAssertEqual(PaywallContext.reSubscribe.primaryButtonTitle, "Renew Subscription")
        XCTAssertEqual(PaywallContext.noSubscription.primaryButtonTitle, "Start Free Trial")
    }

    func testPaywallContextSecondaryButtonTitle() {
        XCTAssertEqual(PaywallContext.trialExpiration.secondaryButtonTitle, "Remind Me Later")
        XCTAssertEqual(PaywallContext.noSubscription.secondaryButtonTitle, "Maybe Later")
        XCTAssertEqual(PaywallContext.subscriptionExpired.secondaryButtonTitle, "Maybe Later")
    }
}