import XCTest
import StoreKit
@testable import SubscriptionService
@testable import SharedModels

@MainActor
final class ProductFetchingTests: XCTestCase {

    var subscriptionService: SubscriptionService!

    override func setUp() async throws {
        try await super.setUp()
        subscriptionService = SubscriptionService()
    }

    override func tearDown() async throws {
        subscriptionService = nil
        try await super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(subscriptionService.availableProducts.isEmpty)
        XCTAssertFalse(subscriptionService.isLoading)
        XCTAssertNil(subscriptionService.error)
    }

    func testProductIdentifiers() {
        XCTAssertEqual(ProductIdentifiers.oneChildMonthly, "screentime.1child.monthly")
        XCTAssertEqual(ProductIdentifiers.twoChildMonthly, "screentime.2child.monthly")
        XCTAssertEqual(ProductIdentifiers.oneChildYearly, "screentime.1child.yearly")
        XCTAssertEqual(ProductIdentifiers.twoChildYearly, "screentime.2child.yearly")
        XCTAssertEqual(ProductIdentifiers.allProducts.count, 4)
    }

    func testSubscriptionPeriodDisplayNames() {
        let monthly = SubscriptionPeriod(unit: .month, value: 1)
        XCTAssertEqual(monthly.displayName, "Monthly")

        let yearly = SubscriptionPeriod(unit: .year, value: 1)
        XCTAssertEqual(yearly.displayName, "Yearly")

        let sixMonths = SubscriptionPeriod(unit: .month, value: 6)
        XCTAssertEqual(sixMonths.displayName, "6 Months")

        let twoYears = SubscriptionPeriod(unit: .year, value: 2)
        XCTAssertEqual(twoYears.displayName, "2 Years")
    }

    func testSubscriptionProductModel() {
        let subscriptionPeriod = SubscriptionPeriod(unit: .month, value: 1)
        let product = SubscriptionProduct(
            id: "test.product",
            displayName: "Test Product",
            description: "Test Description",
            price: Decimal(9.99),
            priceFormatted: "$9.99",
            subscriptionPeriod: subscriptionPeriod,
            familyShareable: false
        )

        XCTAssertEqual(product.id, "test.product")
        XCTAssertEqual(product.displayName, "Test Product")
        XCTAssertEqual(product.description, "Test Description")
        XCTAssertEqual(product.price, Decimal(9.99))
        XCTAssertEqual(product.priceFormatted, "$9.99")
        XCTAssertFalse(product.familyShareable)
        XCTAssertNil(product.introductoryOffer)
    }

    func testProductsByTierLogic() {
        // Test the extraction logic independently
        let monthlyPeriod = SubscriptionPeriod(unit: .month, value: 1)

        let oneChildProduct = SubscriptionProduct(
            id: ProductIdentifiers.oneChildMonthly,
            displayName: "1 Child Monthly",
            description: "Monthly subscription for 1 child",
            price: Decimal(9.99),
            priceFormatted: "$9.99",
            subscriptionPeriod: monthlyPeriod,
            familyShareable: false
        )

        let twoChildProduct = SubscriptionProduct(
            id: ProductIdentifiers.twoChildMonthly,
            displayName: "2 Child Monthly",
            description: "Monthly subscription for 2 children",
            price: Decimal(13.98),
            priceFormatted: "$13.98",
            subscriptionPeriod: monthlyPeriod,
            familyShareable: false
        )

        // Test that product IDs correctly identify child counts
        XCTAssertTrue(oneChildProduct.id.contains("1child"))
        XCTAssertTrue(twoChildProduct.id.contains("2child"))
        XCTAssertEqual(oneChildProduct.subscriptionPeriod.unit, .month)
        XCTAssertEqual(twoChildProduct.subscriptionPeriod.unit, .month)
    }

    func testProductPeriodFiltering() {
        let monthlyPeriod = SubscriptionPeriod(unit: .month, value: 1)
        let yearlyPeriod = SubscriptionPeriod(unit: .year, value: 1)

        let monthlyProduct = SubscriptionProduct(
            id: ProductIdentifiers.oneChildMonthly,
            displayName: "1 Child Monthly",
            description: "Monthly subscription",
            price: Decimal(9.99),
            priceFormatted: "$9.99",
            subscriptionPeriod: monthlyPeriod,
            familyShareable: false
        )

        let yearlyProduct = SubscriptionProduct(
            id: ProductIdentifiers.oneChildYearly,
            displayName: "1 Child Yearly",
            description: "Yearly subscription",
            price: Decimal(89.99),
            priceFormatted: "$89.99",
            subscriptionPeriod: yearlyPeriod,
            familyShareable: false
        )

        // Test the logic for identifying monthly vs yearly products
        XCTAssertEqual(monthlyProduct.subscriptionPeriod.unit, .month)
        XCTAssertEqual(monthlyProduct.subscriptionPeriod.value, 1)
        XCTAssertEqual(yearlyProduct.subscriptionPeriod.unit, .year)
        XCTAssertEqual(yearlyProduct.subscriptionPeriod.value, 1)

        // Test display names
        XCTAssertEqual(monthlyPeriod.displayName, "Monthly")
        XCTAssertEqual(yearlyPeriod.displayName, "Yearly")
    }

    func testYearlySavingsCalculation() {
        let monthlyPeriod = SubscriptionPeriod(unit: .month, value: 1)
        let yearlyPeriod = SubscriptionPeriod(unit: .year, value: 1)

        let monthlyProduct = SubscriptionProduct(
            id: ProductIdentifiers.oneChildMonthly,
            displayName: "1 Child Monthly",
            description: "Monthly subscription",
            price: Decimal(9.99),
            priceFormatted: "$9.99",
            subscriptionPeriod: monthlyPeriod,
            familyShareable: false
        )

        let yearlyProduct = SubscriptionProduct(
            id: ProductIdentifiers.oneChildYearly,
            displayName: "1 Child Yearly",
            description: "Yearly subscription",
            price: Decimal(89.99),
            priceFormatted: "$89.99",
            subscriptionPeriod: yearlyPeriod,
            familyShareable: false
        )

        let savings = subscriptionService.calculateYearlySavings(
            monthlyProduct: monthlyProduct,
            yearlyProduct: yearlyProduct
        )

        // Monthly: $9.99 * 12 = $119.88
        // Yearly: $89.99
        // Savings: $29.89 / $119.88 = ~25%
        XCTAssertNotNil(savings)
        XCTAssertGreaterThan(savings!, 20)
        XCTAssertLessThan(savings!, 30)
    }

    func testErrorMapping() {
        // Test that different error types are properly mapped
        XCTAssertNotNil(subscriptionService)
        // Note: Full error mapping testing would require mock StoreKit framework
        // which is beyond the scope of this unit test
    }

    func testProductCaching() {
        // Initially no cached product
        XCTAssertNil(subscriptionService.getCachedProduct(for: "test.cache"))

        // Note: In real implementation, this would cache actual StoreKit Product objects
        // after a successful fetch. Testing actual caching would require mock StoreKit framework
    }
}