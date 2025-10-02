import XCTest
import UserNotifications
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
final class SubscriptionRenewalMonitorTests: XCTestCase {
    var renewalMonitor: SubscriptionRenewalMonitor!
    var mockNotificationCenter: MockNotificationCenter!

    @MainActor
    override func setUpWithError() throws {
        // Using default notification center for now due to testing complexity
        // mockNotificationCenter = MockNotificationCenter()
        renewalMonitor = SubscriptionRenewalMonitor()
    }

    override func tearDownWithError() throws {
        renewalMonitor = nil
        mockNotificationCenter = nil
    }

    // MARK: - Initialization Tests

    @MainActor
    func testInitialization() {
        XCTAssertEqual(renewalMonitor.renewalStatus, .unknown)
        XCTAssertNil(renewalMonitor.nextRenewalDate)
        XCTAssertEqual(renewalMonitor.billingIssueCount, 0)
        XCTAssertNil(renewalMonitor.gracePeriodEndDate)
    }

    // MARK: - Renewal Status Tests

    func testRenewalStatusEnum() {
        let statuses: [RenewalStatus] = [
            .unknown, .autoRenewEnabled, .autoRenewDisabled,
            .inTrial, .billingRetry, .expired, .cancelled
        ]

        for status in statuses {
            XCTAssertNotNil(status.rawValue)
        }
    }

    // MARK: - Billing Issue Reason Tests

    func testBillingIssueReasonEnum() {
        let reasons: [BillingIssueReason] = [
            .paymentDeclined, .cardExpired, .insufficientFunds,
            .subscriptionExpired, .refunded, .unknown
        ]

        for reason in reasons {
            XCTAssertNotNil(reason.rawValue)
        }
    }

    // MARK: - Status Change Processing Tests

    @MainActor
    func testSuccessfulRenewal() async {
        let entitlement = createMockEntitlement()
        var renewalSuccessCallbackCalled = false

        renewalMonitor.onRenewalSuccess = { _ in
            renewalSuccessCallbackCalled = true
        }

        await renewalMonitor.processStatusChange(
            from: .active,
            to: .active,
            entitlement: entitlement
        )

        XCTAssertEqual(renewalMonitor.billingIssueCount, 0)
        XCTAssertNil(renewalMonitor.gracePeriodEndDate)
        XCTAssertTrue(renewalSuccessCallbackCalled)
    }

    @MainActor
    func testPaymentDeclinedDetection() async {
        let entitlement = createMockEntitlement()
        var renewalFailureCallbackCalled = false

        renewalMonitor.onRenewalFailure = { _, reason in
            renewalFailureCallbackCalled = true
            XCTAssertEqual(reason, .paymentDeclined)
        }

        await renewalMonitor.processStatusChange(
            from: .active,
            to: .gracePeriod,
            entitlement: entitlement
        )

        XCTAssertEqual(renewalMonitor.billingIssueCount, 1)
        XCTAssertNotNil(renewalMonitor.gracePeriodEndDate)
        XCTAssertTrue(renewalFailureCallbackCalled)
    }

    @MainActor
    func testRenewalFailureDetection() async {
        let entitlement = createMockEntitlement()
        var renewalFailureCallbackCalled = false

        renewalMonitor.onRenewalFailure = { _, reason in
            renewalFailureCallbackCalled = true
            XCTAssertEqual(reason, .subscriptionExpired)
        }

        await renewalMonitor.processStatusChange(
            from: .gracePeriod,
            to: .expired,
            entitlement: entitlement
        )

        XCTAssertTrue(renewalFailureCallbackCalled)
    }

    @MainActor
    func testSubscriptionRevokedDetection() async {
        let entitlement = createMockEntitlement()
        var renewalFailureCallbackCalled = false

        renewalMonitor.onRenewalFailure = { _, reason in
            renewalFailureCallbackCalled = true
            XCTAssertEqual(reason, .refunded)
        }

        await renewalMonitor.processStatusChange(
            from: .active,
            to: .revoked,
            entitlement: entitlement
        )

        XCTAssertEqual(renewalMonitor.renewalStatus, .cancelled)
        XCTAssertTrue(renewalFailureCallbackCalled)
    }

    // MARK: - Billing Status Check Tests

    @MainActor
    func testBillingStatusCheckWithActiveSubscription() async {
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let entitlement = createMockEntitlement(nextBillingDate: futureDate)

        await renewalMonitor.checkBillingStatus(for: entitlement)

        // Should not detect any billing issues for future billing date
        XCTAssertEqual(renewalMonitor.billingIssueCount, 0)
        XCTAssertNil(renewalMonitor.gracePeriodEndDate)
    }

    @MainActor
    func testBillingStatusCheckWithExpiredSubscription() async {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let entitlement = createMockEntitlement(nextBillingDate: pastDate)

        await renewalMonitor.checkBillingStatus(for: entitlement)

        // Should detect billing issue and set grace period
        XCTAssertEqual(renewalMonitor.billingIssueCount, 1)
        XCTAssertNotNil(renewalMonitor.gracePeriodEndDate)
    }

    @MainActor
    func testBillingStatusCheckPastGracePeriod() async {
        let oldDate = Calendar.current.date(byAdding: .day, value: -20, to: Date())!
        let entitlement = createMockEntitlement(nextBillingDate: oldDate)

        var renewalFailureCallbackCalled = false
        renewalMonitor.onRenewalFailure = { _, _ in
            renewalFailureCallbackCalled = true
        }

        await renewalMonitor.checkBillingStatus(for: entitlement)

        XCTAssertTrue(renewalFailureCallbackCalled)
    }

    // MARK: - Notification Scheduling Tests

    @MainActor
    func testScheduleRenewalReminders() async {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        renewalMonitor = await createRenewalMonitorWithDate(futureDate)

        await renewalMonitor.scheduleRenewalReminders()

        XCTAssertTrue(mockNotificationCenter.removePendingRequestsCalled)
        XCTAssertTrue(mockNotificationCenter.addRequestCalled)
        XCTAssertEqual(mockNotificationCenter.lastRequestIdentifier, "renewal_reminder")
    }

    @MainActor
    func testScheduleRenewalRemindersWithoutDate() async {
        await renewalMonitor.scheduleRenewalReminders()

        XCTAssertTrue(mockNotificationCenter.removePendingRequestsCalled)
        XCTAssertFalse(mockNotificationCenter.addRequestCalled) // No date to schedule
    }

    // MARK: - Helper Methods

    func createMockEntitlement(
        productID: String = ProductIdentifiers.oneChildMonthly,
        nextBillingDate: Date? = nil
    ) -> SubscriptionEntitlementInfo {
        let purchaseDate = Date()
        let expirationDate = nextBillingDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date())!

        return SubscriptionEntitlementInfo(
            productID: productID,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            isAutoRenewOn: true,
            willAutoRenew: true
        )
    }

    @MainActor
    func createRenewalMonitorWithDate(_ date: Date) async -> SubscriptionRenewalMonitor {
        let monitor = SubscriptionRenewalMonitor(notificationCenter: mockNotificationCenter)
        // Simulate having a renewal date
        await monitor.processStatusChange(
            from: nil,
            to: .active,
            entitlement: createMockEntitlement(nextBillingDate: date)
        )
        return monitor
    }

    @MainActor
    func testGracePeriodDetection() async {
        let entitlement = createMockEntitlement()
        var gracePeriodCallbackCalled = false

        renewalMonitor.onGracePeriodStarted = { endDate in
            gracePeriodCallbackCalled = true
            XCTAssertNotNil(endDate)
        }

        await renewalMonitor.processStatusChange(
            from: .active,
            to: .gracePeriod,
            entitlement: entitlement
        )

        XCTAssertEqual(renewalMonitor.billingIssueCount, 1)
        XCTAssertNotNil(renewalMonitor.gracePeriodEndDate)
        XCTAssertTrue(gracePeriodCallbackCalled)
    }

    // MARK: - Performance Tests

    func testPerformanceOfStatusProcessing() {
        let entitlement = createMockEntitlement()

        measure {
            Task {
                for _ in 0..<10 {
                    await renewalMonitor.processStatusChange(
                        from: .active,
                        to: .active,
                        entitlement: entitlement
                    )
                }
            }
        }
    }
}

// MARK: - Mock Notification Center

@available(iOS 15.0, macOS 12.0, *)
class MockNotificationCenter: UNUserNotificationCenter {
    var removePendingRequestsCalled = false
    var addRequestCalled = false
    var lastRequestIdentifier: String?
    var authorizationGranted = true

    override func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingRequestsCalled = true
    }

    override func add(_ request: UNNotificationRequest) async throws {
        addRequestCalled = true
        lastRequestIdentifier = request.identifier
    }

    override func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return authorizationGranted
    }
}