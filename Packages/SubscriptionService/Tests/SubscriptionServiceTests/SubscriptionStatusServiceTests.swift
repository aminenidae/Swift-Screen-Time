import XCTest
import StoreKit
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
final class SubscriptionStatusServiceTests: XCTestCase {
    var subscriptionStatusService: SubscriptionStatusService!
    var mockFamilyID: String!

    @MainActor
    override func setUpWithError() throws {
        mockFamilyID = "test-family-id"
        subscriptionStatusService = SubscriptionStatusService(familyID: mockFamilyID)
    }

    override func tearDownWithError() throws {
        subscriptionStatusService = nil
        mockFamilyID = nil
    }

    // MARK: - Initialization Tests

    @MainActor
    func testInitialization() {
        XCTAssertEqual(subscriptionStatusService.familyID, mockFamilyID)
        XCTAssertNil(subscriptionStatusService.currentStatus)
        XCTAssertNil(subscriptionStatusService.currentEntitlement)
        XCTAssertFalse(subscriptionStatusService.autoRenewStatus)
        XCTAssertFalse(subscriptionStatusService.isMonitoring)
    }

    @MainActor
    func testInitializationWithoutFamilyID() {
        let service = SubscriptionStatusService()
        XCTAssertNil(service.familyID)
    }

    // MARK: - Subscription Status Tests

    func testSubscriptionStatusEnum() {
        XCTAssertEqual(SharedModels.SubscriptionStatus.active.rawValue, "active")
        XCTAssertEqual(SharedModels.SubscriptionStatus.trial.rawValue, "trial")
        XCTAssertEqual(SharedModels.SubscriptionStatus.expired.rawValue, "expired")
        XCTAssertEqual(SharedModels.SubscriptionStatus.gracePeriod.rawValue, "gracePeriod")
        XCTAssertEqual(SharedModels.SubscriptionStatus.revoked.rawValue, "revoked")

        // Test all cases are covered
        XCTAssertEqual(SharedModels.SubscriptionStatus.allCases.count, 5)
    }

    // MARK: - Entitlement Info Tests

    func testSubscriptionEntitlementInfo() {
        let productID = ProductIdentifiers.oneChildMonthly
        let purchaseDate = Date()
        let expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

        let entitlement = SubscriptionEntitlementInfo(
            productID: productID,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        XCTAssertEqual(entitlement.productID, productID)
        XCTAssertEqual(entitlement.purchaseDate, purchaseDate)
        XCTAssertEqual(entitlement.expirationDate, expirationDate)
        XCTAssertTrue(entitlement.isAutoRenewOn)
        XCTAssertTrue(entitlement.willAutoRenew)
    }

    func testSubscriptionTierFromProductID() {
        let oneChildEntitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date(),
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        let twoChildEntitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.twoChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date(),
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        XCTAssertEqual(oneChildEntitlement.subscriptionTier, .oneChild)
        XCTAssertEqual(twoChildEntitlement.subscriptionTier, .twoChildren)
    }

    func testBillingPeriodFromProductID() {
        let monthlyEntitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date(),
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        let yearlyEntitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildYearly,
            purchaseDate: Date(),
            expirationDate: Date(),
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        XCTAssertEqual(monthlyEntitlement.billingPeriod, .monthly)
        XCTAssertEqual(yearlyEntitlement.billingPeriod, .yearly)
    }

    func testNextBillingDate() {
        let expirationDate = Date()
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: expirationDate,
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        XCTAssertEqual(entitlement.nextBillingDate, expirationDate)
    }

    // MARK: - Subscription Tier Tests

    func testSubscriptionTierDisplayNames() {
        XCTAssertEqual(SubscriptionTier.oneChild.displayName, "1 Child Plan")
        XCTAssertEqual(SubscriptionTier.twoChildren.displayName, "2 Children Plan")
        XCTAssertEqual(SubscriptionTier.threeOrMore.displayName, "3+ Children Plan")
    }

    func testSubscriptionTierMaxChildren() {
        XCTAssertEqual(SubscriptionTier.oneChild.maxChildren, 1)
        XCTAssertEqual(SubscriptionTier.twoChildren.maxChildren, 2)
        XCTAssertEqual(SubscriptionTier.threeOrMore.maxChildren, Int.max)
    }

    // MARK: - Billing Period Tests

    func testBillingPeriodDisplayNames() {
        XCTAssertEqual(BillingPeriod.monthly.displayName, "Monthly")
        XCTAssertEqual(BillingPeriod.yearly.displayName, "Yearly")
    }

    // MARK: - Service Access Tests

    @MainActor
    func testGetCurrentEntitlement() {
        // Initially should be nil
        XCTAssertNil(subscriptionStatusService.getCurrentEntitlement())
    }

    @MainActor
    func testRenewalMonitorAccess() {
        let renewalMonitor = subscriptionStatusService.renewalMonitorInstance
        XCTAssertNotNil(renewalMonitor)
        XCTAssertEqual(renewalMonitor.renewalStatus, .unknown)
    }

    @MainActor
    func testCancellationDetectorAccess() {
        let cancellationDetector = subscriptionStatusService.cancellationDetectorInstance
        XCTAssertNotNil(cancellationDetector)
        XCTAssertFalse(cancellationDetector.cancellationDetected)
    }

    // MARK: - Product Identifiers Tests

    func testProductIdentifiers() {
        XCTAssertEqual(ProductIdentifiers.oneChildMonthly, "screentime.1child.monthly")
        XCTAssertEqual(ProductIdentifiers.twoChildMonthly, "screentime.2child.monthly")
        XCTAssertEqual(ProductIdentifiers.oneChildYearly, "screentime.1child.yearly")
        XCTAssertEqual(ProductIdentifiers.twoChildYearly, "screentime.2child.yearly")

        XCTAssertEqual(ProductIdentifiers.allProducts.count, 4)
        XCTAssertTrue(ProductIdentifiers.allProducts.contains(ProductIdentifiers.oneChildMonthly))
        XCTAssertTrue(ProductIdentifiers.allProducts.contains(ProductIdentifiers.twoChildMonthly))
        XCTAssertTrue(ProductIdentifiers.allProducts.contains(ProductIdentifiers.oneChildYearly))
        XCTAssertTrue(ProductIdentifiers.allProducts.contains(ProductIdentifiers.twoChildYearly))
    }

    // MARK: - Status Change Callback Tests

    @MainActor
    func testStatusChangeCallback() {
        var receivedStatus: SharedModels.SubscriptionStatus?
        subscriptionStatusService.onStatusChanged = { status in
            receivedStatus = status
        }

        // Simulate status change - this is a basic test since we can't easily mock StoreKit
        XCTAssertNotNil(subscriptionStatusService.onStatusChanged)

        // Test that the callback can be set and called
        subscriptionStatusService.onStatusChanged?(.active)
        XCTAssertEqual(receivedStatus, .active)
    }

    // MARK: - Monitoring State Tests

    @MainActor
    func testMonitoringState() async {
        XCTAssertFalse(subscriptionStatusService.isMonitoring)

        subscriptionStatusService.stopMonitoring()
        XCTAssertFalse(subscriptionStatusService.isMonitoring)
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testServiceRobustness() async {
        // Test that service can handle being stopped when not started
        XCTAssertNoThrow(subscriptionStatusService.stopMonitoring())

        // Test that getting entitlement when none exists doesn't crash
        XCTAssertNoThrow(subscriptionStatusService.getCurrentEntitlement())
    }

    // MARK: - Performance Tests

    @MainActor
    func testPerformanceOfInitialization() {
        measure {
            for _ in 0..<100 {
                let service = SubscriptionStatusService(familyID: "test-id")
                _ = service.getCurrentEntitlement()
            }
        }
    }
}