import XCTest
import Combine
@testable import SubscriptionService
@testable import SharedModels
@testable import CloudKitService

@available(iOS 15.0, macOS 10.15, *)
final class SubscriptionValidationIntegrationTests: XCTestCase {

    var entitlementValidationService: EntitlementValidationService!
    var fraudPreventionService: FraudPreventionService!
    var gracePeriodService: GracePeriodService!
    var offlineEntitlementService: OfflineEntitlementService!
    var adminService: SubscriptionAdminService!

    var mockEntitlementRepository: MockSubscriptionEntitlementRepository!
    var mockFraudRepository: MockFraudDetectionRepository!
    var mockAuditRepository: MockValidationAuditRepository!
    var mockAdminAuditRepository: MockAdminAuditRepository!
    var mockLocalCacheService: MockLocalEntitlementCacheService!
    var mockNetworkMonitor: MockNetworkMonitor!
    var mockNotificationService: MockBillingNotificationService!

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        // Set up mock repositories
        mockEntitlementRepository = MockSubscriptionEntitlementRepository()
        mockFraudRepository = MockFraudDetectionRepository()
        mockAuditRepository = MockValidationAuditRepository()
        mockAdminAuditRepository = MockAdminAuditRepository()
        mockLocalCacheService = MockLocalEntitlementCacheService()
        mockNetworkMonitor = MockNetworkMonitor()
        mockNotificationService = MockBillingNotificationService()

        // Set up services
        entitlementValidationService = EntitlementValidationService(
            entitlementRepository: mockEntitlementRepository,
            fraudDetectionService: DefaultFraudDetectionService(),
            userDefaults: UserDefaults(suiteName: "integration_test")!
        )

        fraudPreventionService = FraudPreventionService(
            fraudRepository: mockFraudRepository,
            validationRepository: mockAuditRepository,
            deviceProfiler: MockDeviceProfiler(),
            usageAnalyzer: MockUsagePatternAnalyzer()
        )

        gracePeriodService = GracePeriodService(
            entitlementRepository: mockEntitlementRepository,
            auditRepository: mockAuditRepository,
            notificationService: mockNotificationService
        )

        offlineEntitlementService = OfflineEntitlementService(
            entitlementRepository: mockEntitlementRepository,
            localCacheService: mockLocalCacheService,
            networkMonitor: mockNetworkMonitor
        )

        adminService = SubscriptionAdminService(
            entitlementRepository: mockEntitlementRepository,
            fraudRepository: mockFraudRepository,
            auditRepository: mockAuditRepository,
            adminAuditRepository: mockAdminAuditRepository
        )

        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        adminService = nil
        offlineEntitlementService = nil
        gracePeriodService = nil
        fraudPreventionService = nil
        entitlementValidationService = nil

        mockNotificationService = nil
        mockNetworkMonitor = nil
        mockLocalCacheService = nil
        mockAdminAuditRepository = nil
        mockAuditRepository = nil
        mockFraudRepository = nil
        mockEntitlementRepository = nil

        UserDefaults(suiteName: "integration_test")?.removePersistentDomain(forName: "integration_test")
        super.tearDown()
    }

    // MARK: - End-to-End Receipt Validation Flow

    func testEndToEndReceiptValidation_ValidReceipt_SuccessfulValidation() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)

        mockEntitlementRepository.mockEntitlement = entitlement

        // When - Validate entitlement
        let validatedEntitlement = try await entitlementValidationService.validateEntitlement(for: familyID)

        // Then
        XCTAssertNotNil(validatedEntitlement)
        XCTAssertEqual(validatedEntitlement?.familyID, familyID)
        XCTAssertTrue(entitlementValidationService.hasActiveEntitlement(for: familyID))

        // Verify fraud detection was performed
        let fraudContext = FraudDetectionContext(deviceInfo: ["test": "device"])
        let fraudResult = try await fraudPreventionService.detectFraud(for: entitlement, context: fraudContext)
        XCTAssertFalse(fraudResult.shouldBlock)
        XCTAssertLessThan(fraudResult.fraudScore, 0.5)
    }

    func testEndToEndReceiptValidation_FraudDetected_BlocksAccess() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)

        // Set up duplicate transaction to trigger fraud detection
        let duplicateEntitlement = createValidEntitlement(familyID: "different-family")
        duplicateEntitlement.transactionID = entitlement.transactionID
        mockFraudRepository.mockDuplicateEntitlements = [duplicateEntitlement]

        mockEntitlementRepository.mockEntitlement = entitlement

        // When - Validate entitlement and check for fraud
        let validatedEntitlement = try await entitlementValidationService.validateEntitlement(for: familyID)
        XCTAssertNotNil(validatedEntitlement)

        let fraudContext = FraudDetectionContext(deviceInfo: ["test": "device"])
        let fraudResult = try await fraudPreventionService.detectFraud(for: entitlement, context: fraudContext)

        // Then
        XCTAssertTrue(fraudResult.shouldBlock)
        XCTAssertGreaterThan(fraudResult.fraudScore, 0.7)
        XCTAssertTrue(fraudResult.events.contains { $0.detectionType == .duplicateTransaction })

        // Verify family is blocked
        let isBlocked = try await fraudPreventionService.isFamilyBlocked(familyID)
        XCTAssertTrue(isBlocked)
    }

    // MARK: - Grace Period Integration Flow

    func testGracePeriodFlow_BillingIssue_StartAndResolveGracePeriod() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)
        mockEntitlementRepository.mockEntitlement = entitlement

        // When - Start grace period
        var updatedEntitlement = entitlement
        updatedEntitlement.gracePeriodExpiresAt = Calendar.current.date(byAdding: .day, value: 16, to: Date())
        mockEntitlementRepository.mockUpdatedEntitlement = updatedEntitlement

        let gracePeriodEntitlement = try await gracePeriodService.startGracePeriod(for: entitlement)

        // Then - Verify grace period is active
        XCTAssertNotNil(gracePeriodEntitlement.gracePeriodExpiresAt)
        XCTAssertTrue(gracePeriodService.isInGracePeriod)
        XCTAssertEqual(gracePeriodService.gracePeriodDaysRemaining, 16)

        let gracePeriodStatus = await gracePeriodService.checkGracePeriodStatus(for: gracePeriodEntitlement)
        switch gracePeriodStatus {
        case .active(let daysRemaining):
            XCTAssertEqual(daysRemaining, 16)
        default:
            XCTFail("Expected active grace period")
        }

        // When - Resolve billing issue
        var resolvedEntitlement = gracePeriodEntitlement
        resolvedEntitlement.gracePeriodExpiresAt = nil
        resolvedEntitlement.isActive = true
        mockEntitlementRepository.mockUpdatedEntitlement = resolvedEntitlement

        let finalEntitlement = try await gracePeriodService.handleBillingResolved(for: gracePeriodEntitlement)

        // Then - Verify grace period is ended
        XCTAssertNil(finalEntitlement.gracePeriodExpiresAt)
        XCTAssertTrue(finalEntitlement.isActive)
        XCTAssertFalse(gracePeriodService.isInGracePeriod)
        XCTAssertEqual(gracePeriodService.billingRetryStatus, .resolved)
    }

    // MARK: - Offline Support Integration Flow

    func testOfflineFlow_GoOfflineAndSyncWhenOnline() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)

        mockNetworkMonitor.mockIsConnected = true
        mockEntitlementRepository.mockEntitlement = entitlement

        // When - Get entitlement while online (should cache)
        let onlineEntitlement = try await offlineEntitlementService.getEntitlement(for: familyID)
        XCTAssertNotNil(onlineEntitlement)
        XCTAssertTrue(mockLocalCacheService.cacheEntitlementCalled)

        // When - Go offline
        mockNetworkMonitor.simulateNetworkChange(isConnected: false)

        // Wait for network change to propagate
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertFalse(offlineEntitlementService.isOnline)
        XCTAssertTrue(offlineEntitlementService.isInOfflineMode)

        // When - Get entitlement while offline (should use cache)
        mockLocalCacheService.mockCachedEntitlement = entitlement
        let offlineEntitlement = try await offlineEntitlementService.getEntitlement(for: familyID)
        XCTAssertNotNil(offlineEntitlement)

        // When - Validate offline entitlement
        let offlineValidation = try await offlineEntitlementService.validateOfflineEntitlement(for: familyID)
        switch offlineValidation {
        case .valid(let cachedEntitlement, let daysRemaining):
            XCTAssertEqual(cachedEntitlement.familyID, familyID)
            XCTAssertEqual(daysRemaining, 7) // Default offline grace period
        default:
            XCTFail("Expected valid offline entitlement")
        }

        // When - Come back online
        mockNetworkMonitor.simulateNetworkChange(isConnected: true)
        mockLocalCacheService.mockAllCachedEntitlements = [entitlement]

        // Wait for connectivity restoration
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then - Should sync and update state
        XCTAssertTrue(offlineEntitlementService.isOnline)
        XCTAssertEqual(offlineEntitlementService.syncStatus, .completed)
        XCTAssertFalse(offlineEntitlementService.isInOfflineMode)
    }

    // MARK: - Admin Tools Integration Flow

    func testAdminFlow_ManualEntitlementManagement() async throws {
        // Given
        let familyID = "test-family"
        let adminUserID = "admin-123"

        let request = ManualEntitlementRequest(
            familyID: familyID,
            subscriptionTier: .oneChild,
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            reason: "Customer support case",
            supportTicketID: "TICKET-123"
        )

        // When - Grant manual entitlement
        let grantedEntitlement = try await adminService.grantManualEntitlement(
            request: request,
            adminUserID: adminUserID
        )

        // Then - Verify entitlement was created
        XCTAssertEqual(grantedEntitlement.familyID, familyID)
        XCTAssertEqual(grantedEntitlement.subscriptionTier, .oneChild)
        XCTAssertTrue(grantedEntitlement.isActive)
        XCTAssertFalse(grantedEntitlement.autoRenewStatus) // Manual grants don't auto-renew
        XCTAssertTrue(mockAdminAuditRepository.logActionCalled)

        // When - Extend the entitlement
        mockEntitlementRepository.mockEntitlement = grantedEntitlement

        let newExpirationDate = Calendar.current.date(byAdding: .month, value: 2, to: Date())!
        var extendedEntitlement = grantedEntitlement
        extendedEntitlement.expirationDate = newExpirationDate
        mockEntitlementRepository.mockUpdatedEntitlement = extendedEntitlement

        let finalEntitlement = try await adminService.extendEntitlement(
            familyID: familyID,
            additionalDays: 30,
            reason: "Additional support",
            adminUserID: adminUserID
        )

        // Then - Verify extension
        XCTAssertEqual(finalEntitlement.expirationDate, newExpirationDate)
        XCTAssertNotNil(finalEntitlement.metadata["extended_by"])
        XCTAssertEqual(finalEntitlement.metadata["extended_by"], adminUserID)

        // When - Get family subscription details
        mockEntitlementRepository.mockEntitlements = [finalEntitlement]
        let familyDetails = try await adminService.getFamilySubscriptionDetails(familyID: familyID)

        // Then - Verify details
        XCTAssertEqual(familyDetails.familyID, familyID)
        XCTAssertNotNil(familyDetails.currentEntitlement)
        XCTAssertEqual(familyDetails.allEntitlements.count, 1)
        XCTAssertEqual(familyDetails.riskScore, 0.0) // No fraud events
    }

    // MARK: - Complex Integration Scenario

    func testComplexScenario_OfflineFraudGracePeriodAndAdmin() async throws {
        // Given
        let familyID = "complex-family"
        let adminUserID = "admin-456"
        let entitlement = createValidEntitlement(familyID: familyID)

        // Phase 1: Normal validation with fraud detection
        mockEntitlementRepository.mockEntitlement = entitlement
        let validatedEntitlement = try await entitlementValidationService.validateEntitlement(for: familyID)
        XCTAssertNotNil(validatedEntitlement)

        // Phase 2: Detect fraud (jailbroken device)
        let mockDeviceProfiler = MockDeviceProfiler()
        mockDeviceProfiler.isJailbrokenResult = true

        let fraudService = FraudPreventionService(
            fraudRepository: mockFraudRepository,
            validationRepository: mockAuditRepository,
            deviceProfiler: mockDeviceProfiler,
            usageAnalyzer: MockUsagePatternAnalyzer()
        )

        let fraudContext = FraudDetectionContext(deviceInfo: ["jailbroken": "true"])
        let fraudResult = try await fraudService.detectFraud(for: entitlement, context: fraudContext)

        XCTAssertGreaterThan(fraudResult.fraudScore, 0.0)
        XCTAssertTrue(fraudResult.events.contains { $0.detectionType == .jailbrokenDevice })

        // Phase 3: Start grace period due to billing issue
        var gracePeriodEntitlement = entitlement
        gracePeriodEntitlement.gracePeriodExpiresAt = Calendar.current.date(byAdding: .day, value: 16, to: Date())
        mockEntitlementRepository.mockUpdatedEntitlement = gracePeriodEntitlement

        let entitlementWithGracePeriod = try await gracePeriodService.startGracePeriod(for: entitlement)
        XCTAssertNotNil(entitlementWithGracePeriod.gracePeriodExpiresAt)

        // Phase 4: Go offline during grace period
        mockNetworkMonitor.simulateNetworkChange(isConnected: false)
        mockLocalCacheService.mockCachedEntitlement = entitlementWithGracePeriod

        let offlineValidation = try await offlineEntitlementService.validateOfflineEntitlement(for: familyID)
        switch offlineValidation {
        case .valid(_, let daysRemaining):
            XCTAssertEqual(daysRemaining, 7) // Offline grace period
        default:
            XCTFail("Expected valid offline entitlement")
        }

        // Phase 5: Admin intervention - clear fraud flags
        try await adminService.clearFraudFlags(
            familyID: familyID,
            reason: "False positive - legitimate user",
            adminUserID: adminUserID
        )

        // Phase 6: Come back online and resolve issues
        mockNetworkMonitor.simulateNetworkChange(isConnected: true)
        mockLocalCacheService.mockAllCachedEntitlements = [entitlementWithGracePeriod]

        // Resolve grace period
        var resolvedEntitlement = entitlementWithGracePeriod
        resolvedEntitlement.gracePeriodExpiresAt = nil
        resolvedEntitlement.isActive = true
        mockEntitlementRepository.mockUpdatedEntitlement = resolvedEntitlement

        let finalEntitlement = try await gracePeriodService.handleBillingResolved(for: entitlementWithGracePeriod)

        // Final verification
        XCTAssertNil(finalEntitlement.gracePeriodExpiresAt)
        XCTAssertTrue(finalEntitlement.isActive)
        XCTAssertFalse(gracePeriodService.isInGracePeriod)
        XCTAssertEqual(gracePeriodService.billingRetryStatus, .resolved)

        // Verify admin actions were logged
        XCTAssertTrue(mockAdminAuditRepository.logActionCalled)
    }

    // MARK: - Helper Methods

    private func createValidEntitlement(familyID: String) -> SubscriptionEntitlement {
        return SubscriptionEntitlement(
            id: UUID().uuidString,
            familyID: familyID,
            subscriptionTier: .oneChild,
            receiptData: "dGVzdCByZWNlaXB0IGRhdGEgdGhhdCBpcyBsb25nIGVub3VnaCB0byBiZSBjb25zaWRlcmVkIHZhbGlkIGFuZCBpcyBwcm9wZXJseSBiYXNlNjQgZW5jb2RlZA==",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400),
            expirationDate: Date().addingTimeInterval(86400),
            isActive: true
        )
    }
}

// MARK: - Additional Mock Classes

class MockAdminAuditRepository: AdminAuditRepository {
    var logActionCalled = false

    func logAction(_ action: AdminAction) async throws {
        logActionCalled = true
    }

    func fetchRecentActions(limit: Int) async throws -> [AdminAction] {
        return []
    }

    func fetchActionsForFamily(_ familyID: String) async throws -> [AdminAction] {
        return []
    }

    func fetchActionsByAdmin(_ adminUserID: String) async throws -> [AdminAction] {
        return []
    }
}

// Extension to existing MockSubscriptionEntitlementRepository
extension MockSubscriptionEntitlementRepository {
    var mockEntitlements: [SubscriptionEntitlement] {
        get { mockEntitlement.map { [$0] } ?? [] }
        set { mockEntitlement = newValue.first }
    }
}