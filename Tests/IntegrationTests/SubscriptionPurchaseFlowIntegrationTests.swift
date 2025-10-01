import XCTest
import StoreKit
import SharedModels
import SubscriptionService
import RewardCore
@testable import ScreenTimeRewards

@available(iOS 15.0, *)
@MainActor
final class SubscriptionPurchaseFlowIntegrationTests: XCTestCase {

    var viewModel: SubscriptionViewModel!
    var mockSubscriptionService: MockSubscriptionService!
    var mockAnalyticsService: MockAnalyticsService!

    override func setUp() async throws {
        try await super.setUp()

        // Set up StoreKit test environment
        try await setupStoreKitTestEnvironment()

        mockSubscriptionService = MockSubscriptionService()
        mockAnalyticsService = MockAnalyticsService()

        viewModel = SubscriptionViewModel(
            subscriptionService: mockSubscriptionService,
            analyticsService: mockAnalyticsService
        )
    }

    override func tearDown() async throws {
        try await tearDownStoreKitTestEnvironment()

        mockSubscriptionService = nil
        mockAnalyticsService = nil
        viewModel = nil

        try await super.tearDown()
    }

    // MARK: - Full Purchase Flow Integration Tests

    func testCompleteSubscriptionPurchaseFlow() async throws {
        // Given: Products are available and user is ready to purchase
        let testProducts = createTestSubscriptionProducts()
        mockSubscriptionService.mockProducts = testProducts
        mockSubscriptionService.mockPurchaseResult = .success(.verified(createMockTransaction()))

        // When: Complete purchase flow is executed

        // Step 1: Fetch products
        await viewModel.fetchProducts()
        XCTAssertEqual(viewModel.availableProducts.count, 4)
        XCTAssertFalse(viewModel.isLoading)

        // Step 2: Start purchase
        let productId = ProductIdentifiers.oneChildMonthly
        await viewModel.startPurchase(for: productId)

        // Then: Purchase should complete successfully
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertTrue(viewModel.purchaseSuccess)
        XCTAssertTrue(viewModel.showingSuccessView)
        XCTAssertNil(viewModel.error)

        // Analytics tracking should be complete
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("paywall_impression"))
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_attempted"))
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_completed"))
    }

    func testPurchaseFlowWithNetworkFailure() async throws {
        // Given: Network failure during product fetch
        mockSubscriptionService.shouldThrowError = true

        // When: Attempting to fetch products
        await viewModel.fetchProducts()

        // Then: Error should be handled gracefully
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.availableProducts.count, 0)
    }

    func testPurchaseFlowWithUserCancellation() async throws {
        // Given: User will cancel purchase
        let testProducts = createTestSubscriptionProducts()
        mockSubscriptionService.mockProducts = testProducts
        mockSubscriptionService.mockPurchaseResult = .userCancelled

        // When: User starts and cancels purchase
        await viewModel.fetchProducts()
        await viewModel.startPurchase(for: ProductIdentifiers.oneChildMonthly)

        // Then: Cancellation should be handled gracefully
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertFalse(viewModel.purchaseSuccess)
        XCTAssertNil(viewModel.error) // User cancellation is not an error

        // Analytics should track cancellation
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_cancelled"))
    }

    func testPurchaseFlowWithRestorePurchases() async throws {
        // Given: User has previous purchases to restore
        mockSubscriptionService.shouldThrowError = false

        // When: User restores purchases
        await viewModel.restorePurchases()

        // Then: Restore should complete successfully
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)

        // Analytics should track restore
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_restored"))
    }

    // MARK: - Error Recovery Integration Tests

    func testErrorRecoveryFlow() async throws {
        // Given: Initial error state
        mockSubscriptionService.shouldThrowError = true
        await viewModel.fetchProducts()
        XCTAssertNotNil(viewModel.error)

        // When: Error is cleared and retry is attempted
        mockSubscriptionService.shouldThrowError = false
        mockSubscriptionService.mockProducts = createTestSubscriptionProducts()

        viewModel.clearError()
        await viewModel.fetchProducts()

        // Then: Should recover successfully
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.availableProducts.count, 4)
    }

    // MARK: - Analytics Integration Tests

    func testAnalyticsTrackingThroughoutPurchaseFlow() async throws {
        // Given: Mock analytics service tracking all events
        let testProducts = createTestSubscriptionProducts()
        mockSubscriptionService.mockProducts = testProducts
        mockSubscriptionService.mockPurchaseResult = .success(.verified(createMockTransaction()))

        // When: Complete flow with analytics tracking
        await viewModel.fetchProducts()
        await viewModel.startPurchase(for: ProductIdentifiers.twoChildYearly)

        // Then: All expected analytics events should be tracked
        let expectedEvents = [
            "paywall_impression",
            "purchase_attempted",
            "purchase_completed"
        ]

        for event in expectedEvents {
            XCTAssertTrue(
                mockAnalyticsService.trackedFeatures.contains(event),
                "Expected analytics event '\(event)' was not tracked"
            )
        }
    }

    func testAnalyticsErrorTracking() async throws {
        // Given: Purchase will fail
        mockSubscriptionService.shouldThrowError = true

        // When: Purchase fails
        await viewModel.startPurchase(for: ProductIdentifiers.oneChildMonthly)

        // Then: Error should be tracked in analytics
        XCTAssertTrue(mockAnalyticsService.trackedErrors.contains { $0.0 == "purchase" && $0.1 == "purchase_failed" })
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_failed"))
    }

    // MARK: - State Management Integration Tests

    func testStateManagementThroughPurchaseFlow() async throws {
        // Given: Initial state
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isPurchasing)

        // When: Starting product fetch
        mockSubscriptionService.shouldDelay = true
        let fetchTask = Task { await viewModel.fetchProducts() }

        // Then: Loading state should be active
        XCTAssertTrue(viewModel.isLoading)

        await fetchTask.value
        XCTAssertFalse(viewModel.isLoading)

        // When: Starting purchase
        mockSubscriptionService.mockPurchaseResult = .success(.verified(createMockTransaction()))
        let purchaseTask = Task { await viewModel.startPurchase(for: ProductIdentifiers.oneChildMonthly) }

        // Then: Purchasing state should be active
        try? await Task.sleep(nanoseconds: 10_000_000) // Brief delay
        XCTAssertTrue(viewModel.isPurchasing)

        await purchaseTask.value
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertTrue(viewModel.purchaseSuccess)
    }

    // MARK: - Product Configuration Integration Tests

    func testAllProductIdentifiersAreMapped() async throws {
        // Given: All product identifiers
        let allProductIds = ProductIdentifiers.allProducts

        // When: Creating subscription products for each ID
        let testProducts = allProductIds.map { id in
            SubscriptionProduct(
                id: id,
                displayName: "Test \(id)",
                description: "Test product",
                price: 9.99,
                priceFormatted: "$9.99",
                subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
                familyShareable: true
            )
        }

        mockSubscriptionService.mockProducts = testProducts
        await viewModel.fetchProducts()

        // Then: All products should be available
        XCTAssertEqual(viewModel.availableProducts.count, allProductIds.count)

        for productId in allProductIds {
            let productExists = viewModel.availableProducts.contains { $0.id == productId }
            XCTAssertTrue(productExists, "Product \(productId) should be available")
        }
    }

    // MARK: - Helper Methods

    private func setupStoreKitTestEnvironment() async throws {
        // Configure StoreKit test environment
        // This would set up the StoreKitTest framework for integration testing
    }

    private func tearDownStoreKitTestEnvironment() async throws {
        // Clean up StoreKit test environment
        // This would clean up any StoreKit test configuration
    }

    private func createTestSubscriptionProducts() -> [SubscriptionProduct] {
        return [
            SubscriptionProduct(
                id: ProductIdentifiers.oneChildMonthly,
                displayName: "1 Child Monthly",
                description: "Monthly subscription for 1 child",
                price: 9.99,
                priceFormatted: "$9.99",
                subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
                familyShareable: true
            ),
            SubscriptionProduct(
                id: ProductIdentifiers.oneChildYearly,
                displayName: "1 Child Yearly",
                description: "Annual subscription for 1 child",
                price: 89.99,
                priceFormatted: "$89.99",
                subscriptionPeriod: SubscriptionPeriod(unit: .year, value: 1),
                familyShareable: true
            ),
            SubscriptionProduct(
                id: ProductIdentifiers.twoChildMonthly,
                displayName: "2 Children Monthly",
                description: "Monthly subscription for 2 children",
                price: 13.98,
                priceFormatted: "$13.98",
                subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
                familyShareable: true
            ),
            SubscriptionProduct(
                id: ProductIdentifiers.twoChildYearly,
                displayName: "2 Children Yearly",
                description: "Annual subscription for 2 children",
                price: 125.99,
                priceFormatted: "$125.99",
                subscriptionPeriod: SubscriptionPeriod(unit: .year, value: 1),
                familyShareable: true
            )
        ]
    }

    private func createMockTransaction() -> MockTransaction {
        return MockTransaction(
            id: 67890,
            productID: ProductIdentifiers.twoChildYearly,
            purchaseDate: Date(),
            isUpgraded: false
        )
    }
}

// MARK: - Mock Transaction for Testing

class MockTransaction {
    let id: UInt64
    let productID: String
    let purchaseDate: Date
    let isUpgraded: Bool

    init(id: UInt64, productID: String, purchaseDate: Date, isUpgraded: Bool) {
        self.id = id
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.isUpgraded = isUpgraded
    }

    func finish() async {
        // Mock implementation - no-op for testing
    }
}