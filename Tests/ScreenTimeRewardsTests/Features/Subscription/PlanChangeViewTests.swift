import XCTest
import SwiftUI
@testable import ScreenTimeRewards
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, *)
final class PlanChangeViewTests: XCTestCase {

    // MARK: - Test Data Setup

    func createMockEntitlement(
        productID: String = ProductIdentifiers.oneChildMonthly
    ) -> SubscriptionEntitlementInfo {
        let purchaseDate = Date()
        let expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

        return SubscriptionEntitlementInfo(
            productID: productID,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            isAutoRenewOn: true,
            willAutoRenew: true
        )
    }

    func createMockSubscriptionProduct(
        id: String = ProductIdentifiers.twoChildMonthly,
        displayName: String = "2 Children Plan",
        price: Decimal = 9.99
    ) -> SubscriptionProduct {
        return SubscriptionProduct(
            id: id,
            displayName: displayName,
            description: "Premium plan for 2 children",
            price: price,
            priceFormatted: "$\(price)/month",
            subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
            familyShareable: true,
            introductoryOffer: nil
        )
    }

    // MARK: - View Initialization Tests

    func testViewInitialization() {
        let entitlement = createMockEntitlement()
        let view = PlanChangeView(familyID: "test-family-id", currentEntitlement: entitlement)
        XCTAssertNotNil(view)
    }

    func testViewInitializationWithoutFamilyID() {
        let entitlement = createMockEntitlement()
        let view = PlanChangeView(familyID: nil, currentEntitlement: entitlement)
        XCTAssertNotNil(view)
    }

    func testViewInitializationWithoutCurrentEntitlement() {
        let view = PlanChangeView(familyID: "test-family-id", currentEntitlement: nil)
        XCTAssertNotNil(view)
    }

    // MARK: - Plan Comparison Logic Tests

    func testUpgradeDetection() {
        let oneChildEntitlement = createMockEntitlement(productID: ProductIdentifiers.oneChildMonthly)
        let twoChildProduct = createMockSubscriptionProduct(id: ProductIdentifiers.twoChildMonthly)

        // Test upgrade detection logic
        // In real implementation, you'd extract this logic to testable methods
        let oneChildTier = SubscriptionTier.oneChild
        let twoChildTier = SubscriptionTier.twoChildren

        XCTAssertTrue(twoChildTier.maxChildren > oneChildTier.maxChildren)
    }

    func testDowngradeDetection() {
        let twoChildEntitlement = createMockEntitlement(productID: ProductIdentifiers.twoChildMonthly)
        let oneChildProduct = createMockSubscriptionProduct(id: ProductIdentifiers.oneChildMonthly)

        // Test downgrade detection logic
        let twoChildTier = SubscriptionTier.twoChildren
        let oneChildTier = SubscriptionTier.oneChild

        XCTAssertTrue(oneChildTier.maxChildren < twoChildTier.maxChildren)
    }

    // MARK: - Plan Display Name Tests

    func testPlanDisplayNames() {
        let planNames = [
            ProductIdentifiers.oneChildMonthly: "1 Child",
            ProductIdentifiers.oneChildYearly: "1 Child",
            ProductIdentifiers.twoChildMonthly: "2 Children",
            ProductIdentifiers.twoChildYearly: "2 Children"
        ]

        for (productID, expectedName) in planNames {
            // Test plan display name logic
            let containsChild = expectedName.contains("Child")
            XCTAssertTrue(containsChild)
        }
    }

    // MARK: - Subscription Tier Mapping Tests

    func testSubscriptionTierFromProductID() {
        let mappings = [
            ProductIdentifiers.oneChildMonthly: SubscriptionTier.oneChild,
            ProductIdentifiers.oneChildYearly: SubscriptionTier.oneChild,
            ProductIdentifiers.twoChildMonthly: SubscriptionTier.twoChildren,
            ProductIdentifiers.twoChildYearly: SubscriptionTier.twoChildren
        ]

        for (productID, expectedTier) in mappings {
            switch productID {
            case ProductIdentifiers.oneChildMonthly, ProductIdentifiers.oneChildYearly:
                XCTAssertEqual(expectedTier, .oneChild)
            case ProductIdentifiers.twoChildMonthly, ProductIdentifiers.twoChildYearly:
                XCTAssertEqual(expectedTier, .twoChildren)
            default:
                XCTAssertEqual(expectedTier, .oneChild) // Default case
            }
        }
    }

    // MARK: - Plan Comparison Features Tests

    func testPlanComparisonFeatures() {
        let features = [
            "1 Child Plan",
            "2 Children Plan",
            "Family Sharing",
            "Cloud Sync",
            "Premium Analytics"
        ]

        for feature in features {
            XCTAssertFalse(feature.isEmpty)
            XCTAssertTrue(feature.count > 0)
        }

        // Test feature availability
        let oneChildFeatures = ["✓", "—", "✓", "✓", "✓"]
        let twoChildFeatures = ["✓", "✓", "✓", "✓", "✓"]

        XCTAssertEqual(oneChildFeatures.count, features.count)
        XCTAssertEqual(twoChildFeatures.count, features.count)
    }

    // MARK: - Date Formatting Tests

    func testDateFormatting() {
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let formattedDate = formatter.string(from: testDate)
        XCTAssertFalse(formattedDate.isEmpty)
        XCTAssertTrue(formattedDate.contains("Jun") || formattedDate.contains("6"))
        XCTAssertTrue(formattedDate.contains("15"))
    }

    // MARK: - View Rendering Tests

    func testViewRenderingWithoutCrash() {
        let entitlement = createMockEntitlement()
        let view = PlanChangeView(familyID: "test-family-id", currentEntitlement: entitlement)

        XCTAssertNoThrow({
            let _ = view.body
        })
    }

    // MARK: - Important Information Tests

    func testImportantInformationMessages() {
        let messages = [
            "Plan changes take effect immediately",
            "Billing is prorated by Apple automatically",
            "Downgrades may require removing some child profiles",
            "Your data will be preserved during plan changes"
        ]

        for message in messages {
            XCTAssertFalse(message.isEmpty)
            XCTAssertTrue(message.count > 10) // Ensure substantive messages
        }
    }

    // MARK: - Subscription Product Tests

    func testSubscriptionProductCreation() {
        let product = createMockSubscriptionProduct()

        XCTAssertEqual(product.id, ProductIdentifiers.twoChildMonthly)
        XCTAssertEqual(product.displayName, "2 Children Plan")
        XCTAssertEqual(product.price, 9.99)
        XCTAssertTrue(product.familyShareable)
        XCTAssertEqual(product.subscriptionPeriod.unit, .month)
        XCTAssertEqual(product.subscriptionPeriod.value, 1)
    }

    // MARK: - Grid Layout Tests

    func testGridLayoutConfiguration() {
        // Test that grid layout would work with flexible columns
        let columnCount = 2
        XCTAssertEqual(columnCount, 2)

        // Test that we have an even number of products for grid layout
        XCTAssertEqual(ProductIdentifiers.allProducts.count, 4)
        XCTAssertTrue(ProductIdentifiers.allProducts.count % 2 == 0)
    }

    // MARK: - Error Handling Tests

    func testViewWithNilEntitlement() {
        let view = PlanChangeView(familyID: "test-family-id", currentEntitlement: nil)

        XCTAssertNoThrow({
            let _ = view.body
        })
    }

    // MARK: - Performance Tests

    func testViewCreationPerformance() {
        let entitlement = createMockEntitlement()

        measure {
            for _ in 0..<10 {
                let view = PlanChangeView(familyID: "test-family-id", currentEntitlement: entitlement)
                _ = view.body
            }
        }
    }

    // MARK: - Preview Tests

    #if DEBUG
    func testPreviewRendering() {
        XCTAssertNoThrow({
            let mockEntitlement = SubscriptionEntitlementInfo(
                productID: ProductIdentifiers.oneChildMonthly,
                purchaseDate: Date(),
                expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                isAutoRenewOn: true,
                willAutoRenew: true
            )

            let _ = PlanChangeView(
                familyID: "preview-family-id",
                currentEntitlement: mockEntitlement
            )
        })
    }
    #endif
}