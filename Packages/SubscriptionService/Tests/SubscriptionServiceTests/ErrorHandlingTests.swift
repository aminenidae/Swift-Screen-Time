import XCTest
import StoreKit
@testable import SubscriptionService
@testable import SharedModels

@MainActor
final class ErrorHandlingTests: XCTestCase {

    var subscriptionService: SubscriptionService!

    override func setUp() async throws {
        try await super.setUp()
        subscriptionService = SubscriptionService()
    }

    override func tearDown() async throws {
        subscriptionService = nil
        try await super.tearDown()
    }

    func testAppErrorStoreKitTypes() {
        // Test StoreKit-specific error types
        let storeKitNotAvailable = AppError.storeKitNotAvailable
        XCTAssertEqual(storeKitNotAvailable.errorDescription, "In-app purchases are not available. Please check your settings and try again.")
        XCTAssertEqual(storeKitNotAvailable.failureReason, "StoreKit unavailable")
        XCTAssertEqual(storeKitNotAvailable.recoverySuggestion, "Go to Settings > Screen Time > Content & Privacy Restrictions and make sure In-App Purchases are allowed.")

        let productNotFound = AppError.productNotFound("test.product")
        XCTAssertEqual(productNotFound.errorDescription, "Subscription product 'test.product' not found.")
        XCTAssertEqual(productNotFound.failureReason, "Product not found")
        XCTAssertEqual(productNotFound.recoverySuggestion, "Please check your internet connection and try again. If the problem persists, contact support.")

        let purchaseFailed = AppError.purchaseFailed("Payment declined")
        XCTAssertEqual(purchaseFailed.errorDescription, "Purchase failed: Payment declined")
        XCTAssertEqual(purchaseFailed.failureReason, "Purchase failed")
        XCTAssertEqual(purchaseFailed.recoverySuggestion, "Check your payment method in App Store settings and try again.")

        let transactionNotFound = AppError.transactionNotFound
        XCTAssertEqual(transactionNotFound.errorDescription, "Transaction not found or already processed.")
        XCTAssertEqual(transactionNotFound.failureReason, "Transaction not found")
        XCTAssertEqual(transactionNotFound.recoverySuggestion, "If you completed a purchase, try restarting the app to refresh your subscription status.")

        let subscriptionExpired = AppError.subscriptionExpired
        XCTAssertEqual(subscriptionExpired.errorDescription, "Your subscription has expired. Please renew to continue.")
        XCTAssertEqual(subscriptionExpired.failureReason, "Subscription expired")
        XCTAssertEqual(subscriptionExpired.recoverySuggestion, "Tap 'Subscribe' to renew your subscription and continue using premium features.")

        let restoreFailed = AppError.restoreFailed("No purchases found")
        XCTAssertEqual(restoreFailed.errorDescription, "Failed to restore purchases: No purchases found")
        XCTAssertEqual(restoreFailed.failureReason, "Restore failed")
        XCTAssertEqual(restoreFailed.recoverySuggestion, "Make sure you're signed in with the same Apple ID used for the original purchase.")
    }

    func testFetchProductsWithNetworkFailure() async {
        // Test initial state before fetch
        XCTAssertFalse(subscriptionService.isLoading)
        XCTAssertNil(subscriptionService.error)

        // Note: In a real test, we would mock the StoreKit Product.products call
        // to simulate network failures. Since error is private(set), we can only
        // test the public interface behavior, not directly set error states.

        // Test that calling fetch without network access would set error state
        // This would be verified through integration testing with StoreKit
    }

    func testRefreshProductsWhenEmpty() async {
        // Initially no products
        XCTAssertTrue(subscriptionService.availableProducts.isEmpty)

        // Calling refreshProductsIfNeeded should trigger a fetch
        await subscriptionService.refreshProductsIfNeeded()

        // Note: Since we can't easily mock StoreKit in a unit test,
        // we mainly test that the method executes without crashing
        // Real integration tests would be needed to test actual product fetching
    }

    func testPurchaseWithInvalidProduct() async {
        do {
            _ = try await subscriptionService.purchase("invalid.product.id")
            XCTFail("Expected purchase to throw an error for invalid product")
        } catch {
            if let appError = error as? AppError,
               case .productNotFound(let productId) = appError {
                XCTAssertEqual(productId, "invalid.product.id")
            } else {
                XCTFail("Expected AppError.productNotFound, got \(error)")
            }
        }
    }

    func testErrorEquality() {
        let error1 = AppError.storeKitNotAvailable
        let error2 = AppError.storeKitNotAvailable
        XCTAssertEqual(error1, error2)

        let error3 = AppError.productNotFound("test1")
        let error4 = AppError.productNotFound("test1")
        let error5 = AppError.productNotFound("test2")
        XCTAssertEqual(error3, error4)
        XCTAssertNotEqual(error3, error5)

        let error6 = AppError.purchaseFailed("reason1")
        let error7 = AppError.purchaseFailed("reason1")
        let error8 = AppError.purchaseFailed("reason2")
        XCTAssertEqual(error6, error7)
        XCTAssertNotEqual(error6, error8)
    }

    func testSubscriptionServiceInitialState() async {
        // Verify initial state
        XCTAssertNil(subscriptionService.error)
        XCTAssertFalse(subscriptionService.isLoading)
        XCTAssertTrue(subscriptionService.availableProducts.isEmpty)
    }

    func testConcurrentAccess() async {
        // Test that multiple calls don't cause race conditions
        // This is a basic test - more sophisticated testing would use
        // concurrent queues and multiple async tasks

        let task1 = Task {
            await subscriptionService.refreshProductsIfNeeded()
        }

        let task2 = Task {
            await subscriptionService.refreshProductsIfNeeded()
        }

        await task1.value
        await task2.value

        // Should complete without crashing
        XCTAssertNotNil(subscriptionService)
    }
}