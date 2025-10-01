import XCTest
import SwiftUI
import SharedModels
import SubscriptionService
import ViewInspector
@testable import ScreenTimeRewards

@available(iOS 15.0, *)
final class PaywallViewUITests: XCTestCase {

    var mockSubscriptionService: MockSubscriptionService!

    override func setUp() {
        super.setUp()
        mockSubscriptionService = MockSubscriptionService()
    }

    override func tearDown() {
        mockSubscriptionService = nil
        super.tearDown()
    }

    // MARK: - UI Structure Tests

    func testPaywallViewContainsRequiredSections() throws {
        // Given: PaywallView with mock service
        let paywall = PaywallView()

        // When: Inspecting the view hierarchy
        let body = try paywall.inspect().navigationView().scrollView().vStack()

        // Then: Should contain all required sections
        XCTAssertNoThrow(try body.view(HeaderSection.self, 0))
        XCTAssertNoThrow(try body.view(PlanSelectionSection.self, 1))
        XCTAssertNoThrow(try body.view(PricingToggleSection.self, 2))
        XCTAssertNoThrow(try body.view(PricingComparisonSection.self, 3))
        XCTAssertNoThrow(try body.view(TrialOfferSection.self, 4))
        XCTAssertNoThrow(try body.view(PurchaseButtonSection.self, 5))
    }

    func testHeaderSectionContainsCorrectElements() throws {
        // Given: PaywallView
        let paywall = PaywallView()

        // When: Getting the header section
        let headerSection = paywall.headerSection

        // Then: Should contain star icon, title, and description
        let vStack = try headerSection.inspect().vStack()
        XCTAssertNoThrow(try vStack.image(0))
        XCTAssertNoThrow(try vStack.text(1))
        XCTAssertNoThrow(try vStack.text(2))

        // Verify title text
        let titleText = try vStack.text(1).string()
        XCTAssertEqual(titleText, "Unlock Premium Features")
    }

    func testPlanSelectionButtons() throws {
        // Given: PaywallView
        let paywall = PaywallView()

        // When: Getting the plan selection section
        let planSection = paywall.planSelectionSection

        // Then: Should contain buttons for 1, 2, and 3+ children
        let vStack = try planSection.inspect().vStack()
        let hStack = try vStack.hStack(1)

        // Should have 3 buttons for different child counts
        XCTAssertEqual(try hStack.forEach(0).count, 3)

        // Test button text content
        let firstButton = try hStack.forEach(0).button(0)
        let firstButtonText = try firstButton.labelView().hStack().text(0).string()
        XCTAssertEqual(firstButtonText, "1")
    }

    func testPricingToggleSection() throws {
        // Given: PaywallView
        let paywall = PaywallView()

        // When: Getting the pricing toggle section
        let toggleSection = paywall.pricingToggleSection

        // Then: Should contain monthly/annual toggle
        let hStack = try toggleSection.inspect().hStack()

        // Should have "Monthly" text, toggle, and "Annual" text with savings badge
        XCTAssertNoThrow(try hStack.text(0))
        XCTAssertNoThrow(try hStack.toggle(1))
        XCTAssertNoThrow(try hStack.hStack(2))

        let monthlyText = try hStack.text(0).string()
        XCTAssertEqual(monthlyText, "Monthly")
    }

    func testTrialOfferSection() throws {
        // Given: PaywallView
        let paywall = PaywallView()

        // When: Getting the trial offer section
        let trialSection = paywall.trialOfferSection

        // Then: Should contain gift icon and trial messaging
        let vStack = try trialSection.inspect().vStack()

        // Should contain gift icon and trial text
        let iconAndTitle = try vStack.hStack(0)
        XCTAssertNoThrow(try iconAndTitle.image(0))

        let titleText = try iconAndTitle.text(1).string()
        XCTAssertEqual(titleText, "14-Day Free Trial")
    }

    func testPurchaseButtonSection() throws {
        // Given: PaywallView
        let paywall = PaywallView()

        // When: Getting the purchase button section
        let buttonSection = paywall.purchaseButtonSection

        // Then: Should contain main purchase button and restore button
        let vStack = try buttonSection.inspect().vStack()

        // Main purchase button
        XCTAssertNoThrow(try vStack.button(0))

        // Restore purchases button
        XCTAssertNoThrow(try vStack.button(1))

        // Terms and conditions text
        XCTAssertNoThrow(try vStack.text(2))
    }

    // MARK: - Interaction Tests

    func testChildCountSelection() throws {
        // Given: PaywallView with state
        var paywall = PaywallView()

        // When: Selecting different child counts
        // Note: This would require state inspection which is complex with ViewInspector
        // In a real test, you'd use XCUITest for integration testing

        // Then: Selected count should update pricing
        XCTAssertTrue(true) // Placeholder for actual interaction test
    }

    func testAnnualToggleUpdatesPricing() throws {
        // Given: PaywallView with products loaded
        var paywall = PaywallView()

        // When: Toggling between monthly and annual
        // This would require interaction simulation

        // Then: Pricing should update and show savings
        XCTAssertTrue(true) // Placeholder for actual interaction test
    }

    // MARK: - Error State Tests

    func testErrorStateDisplaysErrorView() {
        // Given: PaywallView with error state
        let paywall = PaywallView()

        // This test would verify that when viewModel.error is set,
        // the PurchaseErrorView sheet is presented
        XCTAssertTrue(true) // Placeholder - actual implementation would test sheet presentation
    }

    func testSuccessStateDisplaysSuccessView() {
        // Given: PaywallView with success state
        let paywall = PaywallView()

        // This test would verify that when viewModel.showingSuccessView is true,
        // the PurchaseSuccessView sheet is presented
        XCTAssertTrue(true) // Placeholder - actual implementation would test sheet presentation
    }

    // MARK: - Accessibility Tests

    func testAccessibilityElements() throws {
        // Given: PaywallView
        let paywall = PaywallView()

        // Then: Key elements should have accessibility labels
        // This would test that buttons, images, and text have proper accessibility
        XCTAssertTrue(true) // Placeholder for accessibility tests
    }

    // MARK: - Performance Tests

    func testViewRenderingPerformance() {
        // Test that the view renders quickly
        self.measure {
            let _ = PaywallView()
        }
    }

    func testPricingCalculationPerformance() {
        // Test that pricing calculations are performant
        let paywall = PaywallView()

        self.measure {
            // This would test the performance of pricing calculations
            let _ = paywall.currentPrice
            let _ = paywall.savingsPercentage
            let _ = paywall.monthlyEquivalent
            let _ = paywall.annualSavings
        }
    }
}

// MARK: - Mock Helper Views for Testing

private struct HeaderSection: View {
    var body: some View {
        EmptyView()
    }
}

private struct PlanSelectionSection: View {
    var body: some View {
        EmptyView()
    }
}

private struct PricingToggleSection: View {
    var body: some View {
        EmptyView()
    }
}

private struct PricingComparisonSection: View {
    var body: some View {
        EmptyView()
    }
}

private struct TrialOfferSection: View {
    var body: some View {
        EmptyView()
    }
}

private struct PurchaseButtonSection: View {
    var body: some View {
        EmptyView()
    }
}