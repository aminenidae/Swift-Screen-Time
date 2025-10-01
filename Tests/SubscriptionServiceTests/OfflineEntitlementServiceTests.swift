import XCTest
import Combine
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, macOS 10.15, *)
final class OfflineEntitlementServiceTests: XCTestCase {

    var sut: OfflineEntitlementService!
    var mockEntitlementRepository: MockSubscriptionEntitlementRepository!
    var mockLocalCacheService: MockLocalEntitlementCacheService!
    var mockNetworkMonitor: MockNetworkMonitor!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockEntitlementRepository = MockSubscriptionEntitlementRepository()
        mockLocalCacheService = MockLocalEntitlementCacheService()
        mockNetworkMonitor = MockNetworkMonitor()

        sut = OfflineEntitlementService(
            entitlementRepository: mockEntitlementRepository,
            localCacheService: mockLocalCacheService,
            networkMonitor: mockNetworkMonitor
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockNetworkMonitor = nil
        mockLocalCacheService = nil
        mockEntitlementRepository = nil
        super.tearDown()
    }

    // MARK: - Get Entitlement Tests

    func testGetEntitlement_OnlineWithServerEntitlement_ReturnsFreshEntitlement() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)

        mockNetworkMonitor.mockIsConnected = true
        mockEntitlementRepository.mockEntitlement = entitlement

        // When
        let result = try await sut.getEntitlement(for: familyID)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.familyID, familyID)
        XCTAssertTrue(mockLocalCacheService.cacheEntitlementCalled)
        XCTAssertNotNil(sut.lastSyncDate)
    }

    func testGetEntitlement_OnlineWithNetworkError_FallsBackToCache() async throws {
        // Given
        let familyID = "test-family"
        let cachedEntitlement = createValidEntitlement(familyID: familyID)

        mockNetworkMonitor.mockIsConnected = true
        mockEntitlementRepository.shouldThrowError = true
        mockLocalCacheService.mockCachedEntitlement = cachedEntitlement

        // When
        let result = try await sut.getEntitlement(for: familyID)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.familyID, familyID)
        XCTAssertTrue(mockLocalCacheService.getCachedEntitlementCalled)
    }

    func testGetEntitlement_OfflineWithValidCache_ReturnsCachedEntitlement() async throws {
        // Given
        let familyID = "test-family"
        let cachedEntitlement = createValidEntitlement(familyID: familyID)

        mockNetworkMonitor.mockIsConnected = false
        mockLocalCacheService.mockCachedEntitlement = cachedEntitlement

        // When
        let result = try await sut.getEntitlement(for: familyID)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.familyID, familyID)
        XCTAssertTrue(mockLocalCacheService.getCachedEntitlementCalled)
        XCTAssertFalse(mockEntitlementRepository.fetchEntitlementForFamilyCalled)
    }

    func testGetEntitlement_OfflineWithNoCache_ReturnsNil() async throws {
        // Given
        let familyID = "test-family"

        mockNetworkMonitor.mockIsConnected = false
        mockLocalCacheService.mockCachedEntitlement = nil

        // When
        let result = try await sut.getEntitlement(for: familyID)

        // Then
        XCTAssertNil(result)
        XCTAssertTrue(mockLocalCacheService.getCachedEntitlementCalled)
    }

    // MARK: - Offline Validation Tests

    func testValidateOfflineEntitlement_ValidCachedEntitlement_ReturnsValid() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)
        mockLocalCacheService.mockCachedEntitlement = entitlement

        // When
        let result = try await sut.validateOfflineEntitlement(for: familyID)

        // Then
        switch result {
        case .valid(let returnedEntitlement, let daysRemaining):
            XCTAssertEqual(returnedEntitlement.familyID, familyID)
            XCTAssertEqual(daysRemaining, 7) // Default offline grace period
        default:
            XCTFail("Expected valid result, got \(result)")
        }
    }

    func testValidateOfflineEntitlement_ExpiredEntitlement_ReturnsEntitlementExpired() async throws {
        // Given
        let familyID = "test-family"
        var entitlement = createValidEntitlement(familyID: familyID)
        entitlement.expirationDate = Date().addingTimeInterval(-3600) // Expired 1 hour ago
        mockLocalCacheService.mockCachedEntitlement = entitlement

        // When
        let result = try await sut.validateOfflineEntitlement(for: familyID)

        // Then
        switch result {
        case .entitlementExpired:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected entitlementExpired, got \(result)")
        }
    }

    func testValidateOfflineEntitlement_NoCache_ReturnsNoValidEntitlement() async throws {
        // Given
        let familyID = "test-family"
        mockLocalCacheService.mockCachedEntitlement = nil

        // When
        let result = try await sut.validateOfflineEntitlement(for: familyID)

        // Then
        switch result {
        case .noValidEntitlement:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected noValidEntitlement, got \(result)")
        }
    }

    func testValidateOfflineEntitlement_ExpiredGracePeriod_ReturnsOfflineGracePeriodExpired() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)
        let expiredGracePeriodStart = Date().addingTimeInterval(-8 * 24 * 3600) // 8 days ago (beyond 7-day grace period)

        mockLocalCacheService.mockCachedEntitlement = entitlement
        mockLocalCacheService.mockOfflineGracePeriodStart = expiredGracePeriodStart

        // When
        let result = try await sut.validateOfflineEntitlement(for: familyID)

        // Then
        switch result {
        case .offlineGracePeriodExpired:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected offlineGracePeriodExpired, got \(result)")
        }
    }

    // MARK: - Connectivity Restoration Tests

    func testHandleConnectivityRestored_SyncsAllCachedEntitlements() async {
        // Given
        let entitlement1 = createValidEntitlement(familyID: "family1")
        let entitlement2 = createValidEntitlement(familyID: "family2")

        mockLocalCacheService.mockAllCachedEntitlements = [entitlement1, entitlement2]
        mockEntitlementRepository.mockEntitlement = entitlement1 // Will return this for any family

        // When
        await sut.handleConnectivityRestored()

        // Then
        XCTAssertTrue(mockLocalCacheService.getAllCachedEntitlementsCalled)
        XCTAssertTrue(mockLocalCacheService.cacheEntitlementCalled)
        XCTAssertEqual(sut.syncStatus, .completed)
        XCTAssertFalse(sut.isInOfflineMode)
    }

    func testHandleConnectivityRestored_HandlesFailures() async {
        // Given
        let entitlement = createValidEntitlement(familyID: "test-family")
        mockLocalCacheService.mockAllCachedEntitlements = [entitlement]
        mockEntitlementRepository.shouldThrowError = true

        // When
        await sut.handleConnectivityRestored()

        // Then
        switch sut.syncStatus {
        case .failed:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected failed sync status")
        }
    }

    // MARK: - Force Sync Tests

    func testForceSync_WhenOnline_PerformsSyncSuccessfully() async throws {
        // Given
        mockNetworkMonitor.mockIsConnected = true
        let entitlement = createValidEntitlement(familyID: "test-family")
        mockLocalCacheService.mockAllCachedEntitlements = [entitlement]
        mockEntitlementRepository.mockEntitlement = entitlement

        // When
        try await sut.forceSync()

        // Then
        XCTAssertEqual(sut.syncStatus, .completed)
        XCTAssertFalse(sut.isInOfflineMode)
    }

    func testForceSync_WhenOffline_ThrowsError() async {
        // Given
        mockNetworkMonitor.mockIsConnected = false

        // When/Then
        do {
            try await sut.forceSync()
            XCTFail("Expected OfflineError.noNetworkConnection")
        } catch OfflineError.noNetworkConnection {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Preload Tests

    func testPreloadEntitlement_WhenOnline_CachesEntitlement() async throws {
        // Given
        let familyID = "test-family"
        let entitlement = createValidEntitlement(familyID: familyID)

        mockNetworkMonitor.mockIsConnected = true
        mockEntitlementRepository.mockEntitlement = entitlement

        // When
        try await sut.preloadEntitlement(for: familyID)

        // Then
        XCTAssertTrue(mockEntitlementRepository.fetchEntitlementForFamilyCalled)
        XCTAssertTrue(mockLocalCacheService.cacheEntitlementCalled)
    }

    func testPreloadEntitlement_WhenOffline_ThrowsError() async {
        // Given
        let familyID = "test-family"
        mockNetworkMonitor.mockIsConnected = false

        // When/Then
        do {
            try await sut.preloadEntitlement(for: familyID)
            XCTFail("Expected OfflineError.noNetworkConnection")
        } catch OfflineError.noNetworkConnection {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Clear Offline Data Tests

    func testClearOfflineData_ClearsAllCacheAndState() async throws {
        // Given
        // Set up some offline state
        await MainActor.run {
            sut.isInOfflineMode = true
            sut.offlineGracePeriodDaysRemaining = 5
        }

        // When
        try await sut.clearOfflineData()

        // Then
        XCTAssertTrue(mockLocalCacheService.clearAllCacheCalled)
        XCTAssertTrue(mockLocalCacheService.clearAllOfflineGracePeriodsCallled)
        XCTAssertFalse(sut.isInOfflineMode)
        XCTAssertEqual(sut.offlineGracePeriodDaysRemaining, 0)
        XCTAssertNil(sut.lastSyncDate)
    }

    // MARK: - Published Properties Tests

    func testPublishedProperties_InitialState() {
        XCTAssertTrue(sut.isOnline)
        XCTAssertFalse(sut.isInOfflineMode)
        XCTAssertEqual(sut.offlineGracePeriodDaysRemaining, 0)
        XCTAssertNil(sut.lastSyncDate)
        XCTAssertEqual(sut.syncStatus, .idle)
    }

    func testPublishedProperties_UpdateOnNetworkChange() {
        // Given
        let expectation = XCTestExpectation(description: "Network status updated")

        sut.$isOnline
            .dropFirst() // Skip initial true state
            .sink { isOnline in
                if !isOnline {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        mockNetworkMonitor.simulateNetworkChange(isConnected: false)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.isOnline)
        XCTAssertTrue(sut.isInOfflineMode)
    }

    func testPublishedProperties_UpdateOnConnectivityRestored() {
        // Given
        mockNetworkMonitor.mockIsConnected = false
        let expectation = XCTestExpectation(description: "Connectivity restored")

        sut.$isOnline
            .dropFirst() // Skip initial state
            .sink { isOnline in
                if isOnline {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        mockNetworkMonitor.simulateNetworkChange(isConnected: true)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(sut.isOnline)
    }

    // MARK: - Helper Methods

    private func createValidEntitlement(familyID: String) -> SubscriptionEntitlement {
        return SubscriptionEntitlement(
            id: UUID().uuidString,
            familyID: familyID,
            subscriptionTier: .oneChild,
            receiptData: "valid-receipt-data",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400),
            expirationDate: Date().addingTimeInterval(86400),
            isActive: true
        )
    }
}

// MARK: - Mock Classes

class MockLocalEntitlementCacheService: LocalEntitlementCacheService {
    var mockCachedEntitlement: SubscriptionEntitlement?
    var mockAllCachedEntitlements: [SubscriptionEntitlement] = []
    var mockOfflineGracePeriodStart: Date?
    var mockLastSyncDate: Date?

    var cacheEntitlementCalled = false
    var getCachedEntitlementCalled = false
    var getAllCachedEntitlementsCalled = false
    var clearAllCacheCalled = false
    var clearAllOfflineGracePeriodsCallled = false

    func cacheEntitlement(_ entitlement: SubscriptionEntitlement) async throws {
        cacheEntitlementCalled = true
    }

    func getCachedEntitlement(for familyID: String) async throws -> SubscriptionEntitlement? {
        getCachedEntitlementCalled = true
        return mockCachedEntitlement?.familyID == familyID ? mockCachedEntitlement : nil
    }

    func getAllCachedEntitlements() async throws -> [SubscriptionEntitlement] {
        getAllCachedEntitlementsCalled = true
        return mockAllCachedEntitlements
    }

    func clearCache(for familyID: String) async throws {
        // Mock implementation
    }

    func clearAllCache() async throws {
        clearAllCacheCalled = true
    }

    func setOfflineGracePeriodStart(for familyID: String, date: Date) async throws {
        mockOfflineGracePeriodStart = date
    }

    func getOfflineGracePeriodStart(for familyID: String) async throws -> Date? {
        return mockOfflineGracePeriodStart
    }

    func clearOfflineGracePeriodStart(for familyID: String) async throws {
        mockOfflineGracePeriodStart = nil
    }

    func clearAllOfflineGracePeriods() async throws {
        clearAllOfflineGracePeriodsCallled = true
    }

    func hasOfflineGracePeriods() async throws -> Bool {
        return mockOfflineGracePeriodStart != nil
    }

    func setLastSyncDate(_ date: Date) async throws {
        mockLastSyncDate = date
    }

    func getLastSyncDate() -> Date? {
        return mockLastSyncDate
    }
}

class MockNetworkMonitor: NetworkMonitor {
    var mockIsConnected = true
    private let connectionSubject = CurrentValueSubject<Bool, Never>(true)

    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        connectionSubject.eraseToAnyPublisher()
    }

    var isConnected: Bool {
        mockIsConnected
    }

    func simulateNetworkChange(isConnected: Bool) {
        mockIsConnected = isConnected
        connectionSubject.send(isConnected)
    }
}

// Extension to existing MockSubscriptionEntitlementRepository
extension MockSubscriptionEntitlementRepository {
    var shouldThrowError: Bool {
        get { false }
        set {
            if newValue {
                mockEntitlement = nil
            }
        }
    }

    var fetchEntitlementForFamilyCalled: Bool {
        get { validateEntitlementCalled }
        set { validateEntitlementCalled = newValue }
    }
}