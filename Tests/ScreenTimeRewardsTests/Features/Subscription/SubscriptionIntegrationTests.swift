import XCTest
import SharedModels
@testable import SubscriptionService

@available(iOS 15.0, *)
final class SubscriptionIntegrationTests: XCTestCase {
    
    func testFeatureGateServiceAndPaywallTriggerIntegration() async {
        // Given: FeatureGateService and PaywallTriggerService
        let featureGateService = FeatureGateService.shared
        let paywallTriggerService = PaywallTriggerService.shared
        
        // When: Checking feature access for a family without subscription
        let familyID = "test-family-no-subscription"
        let accessResult = await featureGateService.checkFeatureAccess(.advancedAnalytics, for: familyID)
        
        // Then: Access should be denied
        XCTAssertEqual(accessResult, .denied(.noSubscription))
        
        // When: Checking if paywall should be triggered
        let shouldShowPaywall = await paywallTriggerService.checkFeatureAccessAndTriggerPaywall(.advancedAnalytics, for: familyID)
        
        // Then: Paywall should be triggered
        XCTAssertFalse(shouldShowPaywall)
        XCTAssertTrue(paywallTriggerService.shouldShowPaywall)
        XCTAssertEqual(paywallTriggerService.paywallContext, .noSubscription)
    }
    
    func testChildProfileCreationGating() async {
        // Given: FeatureGateService with a family that has no subscription
        let featureGateService = FeatureGateService.shared
        
        // When: Checking if child profile can be created with 2 existing children (exceeds free limit)
        let familyID = "test-family-no-subscription"
        let result = await featureGateService.canAddChildProfile(for: familyID, currentChildCount: 2)
        
        // Then: Should be denied due to tier limit (free tier only allows 1 child)
        XCTAssertEqual(result, .denied(.tierLimitExceeded))
    }
    
    func testPaywallContextMessaging() {
        // Given: Different paywall contexts
        let childLimitContext = PaywallContext.childLimitExceeded(currentCount: 2)
        let analyticsContext = PaywallContext.premiumAnalytics
        let expiredContext = PaywallContext.subscriptionExpired
        
        // When: Getting titles and messages
        let childLimitTitle = childLimitContext.title
        let analyticsMessage = analyticsContext.message
        let expiredPrimaryButton = expiredContext.primaryButtonTitle
        
        // Then: Should have appropriate messaging
        XCTAssertEqual(childLimitTitle, "Add More Children")
        XCTAssertTrue(analyticsMessage.contains("detailed insights"))
        XCTAssertEqual(expiredPrimaryButton, "Renew Subscription")
    }
    
    func testSubscriptionTierMaxChildren() {
        // Given: Different subscription tiers
        let oneChildTier = SubscriptionTier.oneChild
        let twoChildrenTier = SubscriptionTier.twoChildren
        let threeOrMoreTier = SubscriptionTier.threeOrMore
        
        // When: Getting max children for each tier
        let oneChildMax = oneChildTier.maxChildren
        let twoChildrenMax = twoChildrenTier.maxChildren
        let threeOrMoreMax = threeOrMoreTier.maxChildren
        
        // Then: Should have correct max children values
        XCTAssertEqual(oneChildMax, 1)
        XCTAssertEqual(twoChildrenMax, 2)
        XCTAssertEqual(threeOrMoreMax, Int.max)
    }
    
    func testFeatureAccessResultEquatability() {
        // Given: Different feature access results
        let allowedResult = FeatureAccessResult.allowed
        let trialResult = FeatureAccessResult.trial
        let deniedNoSubscription = FeatureAccessResult.denied(.noSubscription)
        let deniedExpired = FeatureAccessResult.denied(.subscriptionExpired)
        
        // When: Comparing results
        let equalAllowed = (allowedResult == FeatureAccessResult.allowed)
        let differentFromTrial = (allowedResult == trialResult)
        let equalDenied = (deniedNoSubscription == FeatureAccessResult.denied(.noSubscription))
        let differentDeniedReasons = (deniedNoSubscription == deniedExpired)
        
        // Then: Equality should work correctly
        XCTAssertTrue(equalAllowed)
        XCTAssertFalse(differentFromTrial)
        XCTAssertTrue(equalDenied)
        XCTAssertFalse(differentDeniedReasons)
    }
}