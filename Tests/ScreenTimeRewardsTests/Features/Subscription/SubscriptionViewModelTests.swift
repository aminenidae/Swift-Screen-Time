import XCTest
import StoreKit
import SharedModels
import SubscriptionService
import RewardCore
@testable import ScreenTimeRewards

@available(iOS 15.0, *)
@MainActor
final class SubscriptionViewModelTests: XCTestCase {

    var mockSubscriptionService: MockSubscriptionService!
    var mockAnalyticsService: MockAnalyticsService!
    var viewModel: SubscriptionViewModel!

    override func setUp() async throws {
        try await super.setUp()
        mockSubscriptionService = MockSubscriptionService()
        mockAnalyticsService = MockAnalyticsService()
        viewModel = SubscriptionViewModel(
            subscriptionService: mockSubscriptionService,
            analyticsService: mockAnalyticsService
        )
    }

    override func tearDown() async throws {
        mockSubscriptionService = nil
        mockAnalyticsService = nil
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.availableProducts.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.purchaseSuccess)
        XCTAssertFalse(viewModel.showingSuccessView)
    }

    func testInitializationTracksPaywallImpression() async {
        // When: ViewModel is initialized
        let newViewModel = SubscriptionViewModel(
            subscriptionService: mockSubscriptionService,
            analyticsService: mockAnalyticsService
        )

        // Give analytics time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then: Analytics should track paywall impression
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("paywall_impression"))
    }

    // MARK: - Product Fetching Tests

    func testFetchProductsSuccess() async {
        // Given: Mock service returns products
        let expectedProducts = [
            createMockSubscriptionProduct(id: ProductIdentifiers.oneChildMonthly),
            createMockSubscriptionProduct(id: ProductIdentifiers.twoChildMonthly)
        ]
        mockSubscriptionService.mockProducts = expectedProducts

        // When: Fetching products
        await viewModel.fetchProducts()

        // Then: Products should be loaded
        XCTAssertEqual(viewModel.availableProducts.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testFetchProductsFailure() async {
        // Given: Mock service throws error
        mockSubscriptionService.shouldThrowError = true

        // When: Fetching products
        await viewModel.fetchProducts()

        // Then: Error should be set
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.availableProducts.count, 0)
    }

    func testFetchProductsLoadingState() async {
        // Given: Mock service with delay
        mockSubscriptionService.shouldDelay = true

        // When: Starting to fetch products
        let fetchTask = Task { await viewModel.fetchProducts() }

        // Then: Should be loading initially
        XCTAssertTrue(viewModel.isLoading)

        // Wait for completion
        await fetchTask.value
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Purchase Flow Tests

    func testStartPurchaseSuccess() async {
        // Given: Mock successful purchase
        mockSubscriptionService.mockPurchaseResult = .success(.verified(createMockTransaction()))
        let productId = ProductIdentifiers.oneChildMonthly

        // When: Starting purchase
        await viewModel.startPurchase(for: productId)

        // Then: Purchase should complete successfully
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertTrue(viewModel.purchaseSuccess)
        XCTAssertTrue(viewModel.showingSuccessView)
        XCTAssertNil(viewModel.error)

        // Analytics should track purchase attempt and success
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_attempted"))
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_completed"))
    }

    func testStartPurchaseUserCancelled() async {
        // Given: User cancels purchase
        mockSubscriptionService.mockPurchaseResult = .userCancelled
        let productId = ProductIdentifiers.oneChildMonthly

        // When: Starting purchase
        await viewModel.startPurchase(for: productId)

        // Then: Purchase should be cancelled
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertFalse(viewModel.purchaseSuccess)
        XCTAssertFalse(viewModel.showingSuccessView)
        XCTAssertNil(viewModel.error)

        // Analytics should track cancellation
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_cancelled"))
    }

    func testStartPurchasePending() async {
        // Given: Purchase is pending
        mockSubscriptionService.mockPurchaseResult = .pending
        let productId = ProductIdentifiers.oneChildMonthly

        // When: Starting purchase
        await viewModel.startPurchase(for: productId)

        // Then: Purchase should be pending with error
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.purchaseSuccess)

        // Analytics should track pending
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_pending"))
    }

    func testStartPurchaseFailure() async {
        // Given: Purchase throws error
        mockSubscriptionService.shouldThrowError = true
        let productId = ProductIdentifiers.oneChildMonthly

        // When: Starting purchase
        await viewModel.startPurchase(for: productId)

        // Then: Error should be set
        XCTAssertFalse(viewModel.isPurchasing)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.purchaseSuccess)

        // Analytics should track failure
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_failed"))
    }

    func testPurchasePreventsDuplicates() async {
        // Given: Purchase is in progress
        viewModel = SubscriptionViewModel(
            subscriptionService: mockSubscriptionService,
            analyticsService: mockAnalyticsService
        )

        mockSubscriptionService.shouldDelay = true
        let productId = ProductIdentifiers.oneChildMonthly

        // When: Starting multiple purchases
        let task1 = Task { await viewModel.startPurchase(for: productId) }
        let task2 = Task { await viewModel.startPurchase(for: productId) }

        // Then: Only one purchase should proceed
        await task1.value
        await task2.value

        // Only one attempt should be tracked
        XCTAssertEqual(mockAnalyticsService.trackedFeatures.filter { $0 == "purchase_attempted" }.count, 1)
    }

    // MARK: - Restore Purchases Tests

    func testRestorePurchasesSuccess() async {
        // Given: Mock successful restore
        mockSubscriptionService.shouldThrowError = false

        // When: Restoring purchases
        await viewModel.restorePurchases()

        // Then: Restore should complete successfully
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)

        // Analytics should track restore
        XCTAssertTrue(mockAnalyticsService.trackedFeatures.contains("purchase_restored"))
    }

    func testRestorePurchasesFailure() async {
        // Given: Mock restore failure
        mockSubscriptionService.shouldThrowError = true

        // When: Restoring purchases
        await viewModel.restorePurchases()

        // Then: Error should be set
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - State Management Tests

    func testClearError() {
        // Given: Error is set
        viewModel.error = .networkError("Test error")

        // When: Clearing error
        viewModel.clearError()

        // Then: Error should be nil
        XCTAssertNil(viewModel.error)
    }

    func testDismissSuccessView() {
        // Given: Success view is showing
        viewModel.showingSuccessView = true
        viewModel.purchaseSuccess = true

        // When: Dismissing success view
        viewModel.dismissSuccessView()

        // Then: Success state should be reset
        XCTAssertFalse(viewModel.showingSuccessView)
        XCTAssertFalse(viewModel.purchaseSuccess)
    }

    // MARK: - Helper Methods

    private func createMockSubscriptionProduct(id: String) -> SubscriptionProduct {
        return SubscriptionProduct(
            id: id,
            displayName: "Test Product",
            description: "Test Description",
            price: 9.99,
            priceFormatted: "$9.99",
            subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
            familyShareable: true
        )
    }

    private func createMockTransaction() -> MockTransaction {
        return MockTransaction(
            id: 12345,
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            isUpgraded: false
        )
    }
}

// MARK: - Mock Classes

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

class MockSubscriptionService: SubscriptionService {
    var mockProducts: [SubscriptionProduct] = []
    var shouldThrowError = false
    var shouldDelay = false
    var mockPurchaseResult: Product.PurchaseResult = .userCancelled

    override func fetchProducts() async {
        if shouldDelay {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        if shouldThrowError {
            throw AppError.networkError("Mock error")
        }

        await MainActor.run {
            self.availableProducts = mockProducts
        }
    }

    override func purchase(_ productId: String) async throws -> Product.PurchaseResult {
        if shouldDelay {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        if shouldThrowError {
            throw AppError.purchaseFailed("Mock purchase error")
        }

        return mockPurchaseResult
    }

    override func restorePurchases() async throws {
        if shouldThrowError {
            throw AppError.networkError("Mock restore error")
        }
    }
}

class MockAnalyticsService: AnalyticsService {
    var trackedFeatures: [String] = []
    var trackedErrors: [(String, String)] = []

    init() {
        // Initialize with minimal required dependencies
        super.init(
            consentService: MockAnalyticsConsentService(),
            anonymizationService: MockDataAnonymizationService(),
            aggregationService: MockAnalyticsAggregationService()
        )
    }

    override func trackFeatureUsage(feature: String, metadata: [String : String]?) async {
        trackedFeatures.append(feature)
    }

    override func trackError(category: String, code: String) async {
        trackedErrors.append((category, code))
    }
}

// Minimal mock implementations for AnalyticsService dependencies
class MockAnalyticsConsentService: AnalyticsConsentService {
    init() {
        super.init(repository: nil)
    }

    override func isCollectionAllowed(for userID: String) async -> Bool {
        return true
    }
}

class MockDataAnonymizationService: DataAnonymizationService {
    init() {
        super.init()
    }

    override func getCurrentAnonymizedUserID() async -> String {
        return "mock-user-id"
    }

    override func getCurrentSessionID() async -> String {
        return "mock-session-id"
    }

    override func getAppVersion() async -> String {
        return "1.0.0"
    }

    override func getOSVersion() async -> String {
        return "iOS 15.0"
    }
}

class MockAnalyticsAggregationService: AnalyticsAggregationService {
    init() {
        super.init(repository: nil)
    }
}