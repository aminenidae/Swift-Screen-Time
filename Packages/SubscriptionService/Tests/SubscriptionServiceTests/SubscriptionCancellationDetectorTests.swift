import XCTest
import StoreKit
import UserNotifications
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class SubscriptionCancellationDetectorTests: XCTestCase {
    var subscriptionCancellationDetector: SubscriptionCancellationDetector!
    var mockNotificationCenter: MockUserNotificationCenter!

    override func setUpWithError() throws {
        // Using default notification center for now due to testing complexity
        // mockNotificationCenter = MockUserNotificationCenter()
        subscriptionCancellationDetector = SubscriptionCancellationDetector()
    }

    override func tearDownWithError() throws {
        subscriptionCancellationDetector = nil
        mockNotificationCenter = nil
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertFalse(subscriptionCancellationDetector.cancellationDetected)
        XCTAssertNil(subscriptionCancellationDetector.cancellationDate)
        XCTAssertNil(subscriptionCancellationDetector.accessEndDate)
        XCTAssertFalse(subscriptionCancellationDetector.hasShownResubscriptionOffer)
    }

    // MARK: - Cancellation Detection Tests

    func testProcessStatusChangeWhenAutoRenewTurnedOff() async {
        // Create an entitlement with auto-renew initially on
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        // Process initial state (auto-renew on)
        await subscriptionCancellationDetector.processStatusChange(
            from: nil,
            to: .active,
            entitlement: entitlement
        )

        // Create updated entitlement with auto-renew turned off
        let updatedEntitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
            isAutoRenewOn: true,
            willAutoRenew: false // Auto-renew turned off
        )

        var cancellationDetectedCallbackCalled = false
        subscriptionCancellationDetector.onCancellationDetected = { _ in
            cancellationDetectedCallbackCalled = true
        }

        // Process status change with auto-renew turned off
        await subscriptionCancellationDetector.processStatusChange(
            from: .active,
            to: .active,
            entitlement: updatedEntitlement
        )

        XCTAssertTrue(subscriptionCancellationDetector.cancellationDetected)
        XCTAssertNotNil(subscriptionCancellationDetector.cancellationDate)
        XCTAssertEqual(subscriptionCancellationDetector.accessEndDate, updatedEntitlement.expirationDate)
        XCTAssertTrue(cancellationDetectedCallbackCalled)
        XCTAssertEqual(mockNotificationCenter.addedNotifications.count, 1)
        XCTAssertEqual(mockNotificationCenter.addedNotifications[0].content.title, "Subscription Cancelled")
    }

    func testProcessStatusChangeWhenSubscriptionRevoked() async {
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        var cancellationDetectedCallbackCalled = false
        subscriptionCancellationDetector.onCancellationDetected = { _ in
            cancellationDetectedCallbackCalled = true
        }

        await subscriptionCancellationDetector.processStatusChange(
            from: .active,
            to: .revoked,
            entitlement: entitlement
        )

        XCTAssertTrue(subscriptionCancellationDetector.cancellationDetected)
        XCTAssertNotNil(subscriptionCancellationDetector.cancellationDate)
        XCTAssertNotNil(subscriptionCancellationDetector.accessEndDate)
        XCTAssertTrue(cancellationDetectedCallbackCalled)
        XCTAssertEqual(mockNotificationCenter.addedNotifications.count, 1)
        XCTAssertEqual(mockNotificationCenter.addedNotifications[0].content.title, "Subscription Refunded")
    }

    func testProcessStatusChangeWhenSubscriptionExpiredAfterActive() async {
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(-1 * 24 * 60 * 60), // 1 day ago
            isAutoRenewOn: true,
            willAutoRenew: true
        )

        var accessEndingCallbackCalled = false
        subscriptionCancellationDetector.onAccessEnding = { _ in
            accessEndingCallbackCalled = true
        }

        // First, simulate cancellation detection
        await subscriptionCancellationDetector.processStatusChange(
            from: .active,
            to: .active,
            entitlement: entitlement
        )

        // Then simulate expiration
        await subscriptionCancellationDetector.processStatusChange(
            from: .active,
            to: .expired,
            entitlement: entitlement
        )

        XCTAssertEqual(mockNotificationCenter.addedNotifications.count, 2)
        XCTAssertEqual(mockNotificationCenter.addedNotifications[1].content.title, "Subscription Ended")
        XCTAssertTrue(accessEndingCallbackCalled)
    }

    // MARK: - Cancellation With Access Tests

    func testCheckCancellationWithAccessWhenAutoRenewOffAndNotExpired() {
        let futureDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days in future
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: futureDate,
            isAutoRenewOn: true,
            willAutoRenew: false // Auto-renew off
        )

        let result = subscriptionCancellationDetector.checkCancellationWithAccess(entitlement: entitlement)
        XCTAssertTrue(result)
    }

    func testCheckCancellationWithAccessWhenAutoRenewOn() {
        let futureDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days in future
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: futureDate,
            isAutoRenewOn: true,
            willAutoRenew: true // Auto-renew on
        )

        let result = subscriptionCancellationDetector.checkCancellationWithAccess(entitlement: entitlement)
        XCTAssertFalse(result)
    }

    func testCheckCancellationWithAccessWhenExpired() {
        let pastDate = Date().addingTimeInterval(-1 * 24 * 60 * 60) // 1 day ago
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: pastDate,
            isAutoRenewOn: true,
            willAutoRenew: false // Auto-renew off
        )

        let result = subscriptionCancellationDetector.checkCancellationWithAccess(entitlement: entitlement)
        XCTAssertFalse(result) // Already expired, so not considered as having access
    }

    // MARK: - Resubscription Offer Tests

    func testPresentResubscriptionOfferIfNeededWhenConditionsMet() async {
        // Set up cancellation state
        subscriptionCancellationDetector = SubscriptionCancellationDetector(notificationCenter: mockNotificationCenter)
        #if DEBUG
        await MainActor.run {
            subscriptionCancellationDetector.setCancellationDetected(true)
        }
        #endif

        let expirationDate = Date().addingTimeInterval(5 * 24 * 60 * 60) // 5 days from now
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: expirationDate,
            isAutoRenewOn: true,
            willAutoRenew: false
        )

        var resubscriptionOfferCallbackCalled = false
        subscriptionCancellationDetector.onResubscriptionOfferShown = {
            resubscriptionOfferCallbackCalled = true
        }

        await subscriptionCancellationDetector.presentResubscriptionOfferIfNeeded(entitlement: entitlement)

        XCTAssertTrue(subscriptionCancellationDetector.hasShownResubscriptionOffer)
        XCTAssertTrue(resubscriptionOfferCallbackCalled)
        XCTAssertEqual(mockNotificationCenter.addedNotifications.count, 1)
        XCTAssertEqual(mockNotificationCenter.addedNotifications[0].content.title, "Special Offer - Come Back!")
    }

    func testPresentResubscriptionOfferIfNeededWhenAlreadyShown() async {
        #if DEBUG
        await MainActor.run {
            subscriptionCancellationDetector.setCancellationDetected(true)
            subscriptionCancellationDetector.setHasShownResubscriptionOffer(true) // Already shown
        }
        #endif

        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(5 * 24 * 60 * 60),
            isAutoRenewOn: true,
            willAutoRenew: false
        )

        await subscriptionCancellationDetector.presentResubscriptionOfferIfNeeded(entitlement: entitlement)

        XCTAssertTrue(subscriptionCancellationDetector.hasShownResubscriptionOffer)
        XCTAssertEqual(mockNotificationCenter.addedNotifications.count, 0) // No new notifications
    }

    func testPresentResubscriptionOfferIfNeededWhenNoCancellation() async {
        #if DEBUG
        await MainActor.run {
            subscriptionCancellationDetector.setCancellationDetected(false) // No cancellation
        }
        #endif

        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(5 * 24 * 60 * 60),
            isAutoRenewOn: true,
            willAutoRenew: false
        )

        await subscriptionCancellationDetector.presentResubscriptionOfferIfNeeded(entitlement: entitlement)

        XCTAssertFalse(subscriptionCancellationDetector.hasShownResubscriptionOffer)
        XCTAssertEqual(mockNotificationCenter.addedNotifications.count, 0) // No notifications
    }

    // MARK: - State Management Tests

    func testMarkResubscriptionOfferDismissed() async {
        #if DEBUG
        await MainActor.run {
            subscriptionCancellationDetector.setHasShownResubscriptionOffer(false)
        }
        #endif
        subscriptionCancellationDetector.markResubscriptionOfferDismissed()
        XCTAssertTrue(subscriptionCancellationDetector.hasShownResubscriptionOffer)
    }

    func testResetCancellationState() async {
        // Set up some state
        #if DEBUG
        await MainActor.run {
            subscriptionCancellationDetector.setCancellationDetected(
                true,
                date: Date(),
                accessEndDate: Date().addingTimeInterval(30 * 24 * 60 * 60)
            )
            subscriptionCancellationDetector.setHasShownResubscriptionOffer(true)
        }
        #endif

        // Reset state
        subscriptionCancellationDetector.resetCancellationState()

        XCTAssertFalse(subscriptionCancellationDetector.cancellationDetected)
        XCTAssertNil(subscriptionCancellationDetector.cancellationDate)
        XCTAssertNil(subscriptionCancellationDetector.accessEndDate)
        XCTAssertFalse(subscriptionCancellationDetector.hasShownResubscriptionOffer)
    }

    // MARK: - Access Ending Reminders Tests

    func testScheduleAccessEndingReminders() async {
        let expirationDate = Date().addingTimeInterval(10 * 24 * 60 * 60) // 10 days from now
        let entitlement = SubscriptionEntitlementInfo(
            productID: ProductIdentifiers.oneChildMonthly,
            purchaseDate: Date(),
            expirationDate: expirationDate,
            isAutoRenewOn: true,
            willAutoRenew: false
        )

        // Simulate cancellation detection which should schedule reminders
        await subscriptionCancellationDetector.processStatusChange(
            from: .active,
            to: .active,
            entitlement: entitlement
        )

        // Should have scheduled 3 reminders + 1 cancellation confirmation
        XCTAssertEqual(mockNotificationCenter.addedNotifications.count, 4)
        
        // Check that reminders have correct identifiers
        let identifiers = mockNotificationCenter.addedNotifications.map { $0.identifier }
        XCTAssertTrue(identifiers.contains("access_ending_7_days"))
        XCTAssertTrue(identifiers.contains("access_ending_1_day"))
        XCTAssertTrue(identifiers.contains("access_ending_1_hour"))
    }
}

// MARK: - Mock Classes

class MockUserNotificationCenter: UNUserNotificationCenter {
    var addedNotifications: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []

    override func add(_ request: UNNotificationRequest) async throws {
        addedNotifications.append(request)
    }

    override func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }
}