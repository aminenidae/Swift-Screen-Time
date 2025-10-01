import XCTest
import Combine
@testable import SubscriptionService
@testable import SharedModels

@available(iOS 15.0, macOS 10.15, *)
final class FraudPreventionServiceTests: XCTestCase {

    var sut: FraudPreventionService!
    var mockFraudRepository: MockFraudDetectionRepository!
    var mockValidationRepository: MockValidationAuditRepository!
    var mockDeviceProfiler: MockDeviceProfiler!
    var mockUsageAnalyzer: MockUsagePatternAnalyzer!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockFraudRepository = MockFraudDetectionRepository()
        mockValidationRepository = MockValidationAuditRepository()
        mockDeviceProfiler = MockDeviceProfiler()
        mockUsageAnalyzer = MockUsagePatternAnalyzer()

        sut = FraudPreventionService(
            fraudRepository: mockFraudRepository,
            validationRepository: mockValidationRepository,
            deviceProfiler: mockDeviceProfiler,
            usageAnalyzer: mockUsageAnalyzer
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUsageAnalyzer = nil
        mockDeviceProfiler = nil
        mockValidationRepository = nil
        mockFraudRepository = nil
        super.tearDown()
    }

    // MARK: - Fraud Detection Tests

    func testDetectFraud_NoFraudIndicators_ReturnsLowScore() async throws {
        // Given
        let entitlement = createValidEntitlement()
        let context = createFraudDetectionContext()

        mockDeviceProfiler.isJailbrokenResult = false
        mockUsageAnalyzer.mockPatterns = UsagePatterns(
            rapidSubscriptionChanges: 0,
            validationFrequency: 1,
            deviceChanges: 0,
            geographicAnomalies: 0
        )

        // When
        let result = try await sut.detectFraud(for: entitlement, context: context)

        // Then
        XCTAssertLessThan(result.fraudScore, 0.5)
        XCTAssertFalse(result.shouldBlock)
        XCTAssertEqual(result.recommendation, .allow)
    }

    func testDetectFraud_JailbrokenDevice_IncreasesFraudScore() async throws {
        // Given
        let entitlement = createValidEntitlement()
        let context = createFraudDetectionContext()

        mockDeviceProfiler.isJailbrokenResult = true
        mockUsageAnalyzer.mockPatterns = UsagePatterns(
            rapidSubscriptionChanges: 0,
            validationFrequency: 1,
            deviceChanges: 0,
            geographicAnomalies: 0
        )

        // When
        let result = try await sut.detectFraud(for: entitlement, context: context)

        // Then
        XCTAssertGreaterThan(result.fraudScore, 0.0)
        XCTAssertTrue(result.events.contains { $0.detectionType == .jailbrokenDevice })
    }

    func testDetectFraud_DuplicateTransaction_ReturnsHighScore() async throws {
        // Given
        let entitlement = createValidEntitlement()
        let context = createFraudDetectionContext()

        // Set up duplicate transaction
        let duplicateEntitlement = createValidEntitlement()
        duplicateEntitlement.familyID = "different-family"
        mockFraudRepository.mockDuplicateEntitlements = [duplicateEntitlement]

        mockDeviceProfiler.isJailbrokenResult = false
        mockUsageAnalyzer.mockPatterns = UsagePatterns(
            rapidSubscriptionChanges: 0,
            validationFrequency: 1,
            deviceChanges: 0,
            geographicAnomalies: 0
        )

        // When
        let result = try await sut.detectFraud(for: entitlement, context: context)

        // Then
        XCTAssertGreaterThan(result.fraudScore, 0.7)
        XCTAssertTrue(result.shouldBlock)
        XCTAssertTrue(result.events.contains { $0.detectionType == .duplicateTransaction })
    }

    func testDetectFraud_AnomalousUsage_IncreasesFraudScore() async throws {
        // Given
        let entitlement = createValidEntitlement()
        let context = createFraudDetectionContext()

        mockDeviceProfiler.isJailbrokenResult = false
        mockUsageAnalyzer.mockPatterns = UsagePatterns(
            rapidSubscriptionChanges: 5, // High number indicates anomalous behavior
            validationFrequency: 100,   // Very high validation frequency
            deviceChanges: 3,
            geographicAnomalies: 2
        )

        // When
        let result = try await sut.detectFraud(for: entitlement, context: context)

        // Then
        XCTAssertGreaterThan(result.fraudScore, 0.0)
        XCTAssertTrue(result.events.contains { $0.detectionType == .anomalousUsage })
    }

    func testDetectFraud_TamperedReceipt_ReturnsHighScore() async throws {
        // Given
        var entitlement = createValidEntitlement()
        entitlement.receiptData = "invalid" // Too short to be valid
        let context = createFraudDetectionContext()

        mockDeviceProfiler.isJailbrokenResult = false
        mockUsageAnalyzer.mockPatterns = UsagePatterns(
            rapidSubscriptionChanges: 0,
            validationFrequency: 1,
            deviceChanges: 0,
            geographicAnomalies: 0
        )

        // When
        let result = try await sut.detectFraud(for: entitlement, context: context)

        // Then
        XCTAssertGreaterThan(result.fraudScore, 0.5)
        XCTAssertTrue(result.events.contains { $0.detectionType == .tamperedReceipt })
    }

    // MARK: - Family Blocking Tests

    func testIsFamilyBlocked_HighFraudScore_ReturnsTrue() async throws {
        // Given
        let familyID = "test-family"
        let highSeverityEvent = FraudDetectionEvent(
            familyID: familyID,
            detectionType: .duplicateTransaction,
            severity: .critical,
            deviceInfo: [:],
            metadata: [:]
        )
        mockFraudRepository.mockFraudEvents = [highSeverityEvent]

        // When
        let isBlocked = try await sut.isFamilyBlocked(familyID)

        // Then
        XCTAssertTrue(isBlocked)
    }

    func testIsFamilyBlocked_LowFraudScore_ReturnsFalse() async throws {
        // Given
        let familyID = "test-family"
        let lowSeverityEvent = FraudDetectionEvent(
            familyID: familyID,
            detectionType: .jailbrokenDevice,
            severity: .low,
            deviceInfo: [:],
            metadata: [:]
        )
        mockFraudRepository.mockFraudEvents = [lowSeverityEvent]

        // When
        let isBlocked = try await sut.isFamilyBlocked(familyID)

        // Then
        XCTAssertFalse(isBlocked)
    }

    func testClearFraudBlock_UpdatesState() async throws {
        // Given
        let familyID = "test-family"

        // When
        try await sut.clearFraudBlock(for: familyID)

        // Then
        XCTAssertFalse(sut.isBlocked)
        XCTAssertEqual(sut.fraudScore, 0.0)
        XCTAssertTrue(sut.detectedEvents.isEmpty)
        XCTAssertTrue(mockValidationRepository.createAuditLogCalled)
    }

    // MARK: - Receipt Validation Tests

    func testValidateReceiptFormat_ValidReceipt_ReturnsTrue() {
        // Given
        let validReceipt = "dGVzdCByZWNlaXB0IGRhdGEgdGhhdCBpcyBsb25nIGVub3VnaCB0byBiZSBjb25zaWRlcmVkIHZhbGlkIGFuZCBpcyBwcm9wZXJseSBiYXNlNjQgZW5jb2RlZA==" // Base64 encoded test data

        // When
        let isValid = sut.validateReceiptFormat(validReceipt)

        // Then
        XCTAssertTrue(isValid)
    }

    func testValidateReceiptFormat_EmptyReceipt_ReturnsFalse() {
        // Given
        let emptyReceipt = ""

        // When
        let isValid = sut.validateReceiptFormat(emptyReceipt)

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateReceiptFormat_TooShortReceipt_ReturnsFalse() {
        // Given
        let shortReceipt = "short"

        // When
        let isValid = sut.validateReceiptFormat(shortReceipt)

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateReceiptFormat_InvalidBase64_ReturnsFalse() {
        // Given
        let invalidBase64 = "this is not valid base64 data that is long enough but still invalid!!!"

        // When
        let isValid = sut.validateReceiptFormat(invalidBase64)

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateReceiptFormat_SuspiciousContent_ReturnsFalse() {
        // Given
        let suspiciousReceipt = "dGVzdCBmYWtlIHJlY2VpcHQgZGF0YSB0aGF0IGNvbnRhaW5zIHN1c3BpY2lvdXMgY29udGVudA==" // Contains "fake"

        // When
        let isValid = sut.validateReceiptFormat(suspiciousReceipt)

        // Then
        XCTAssertFalse(isValid)
    }

    // MARK: - Published Properties Tests

    func testPublishedProperties_InitialState() {
        // Then
        XCTAssertTrue(sut.detectedEvents.isEmpty)
        XCTAssertEqual(sut.fraudScore, 0.0)
        XCTAssertFalse(sut.isBlocked)
    }

    func testPublishedProperties_UpdateAfterFraudDetection() async throws {
        // Given
        let entitlement = createValidEntitlement()
        let context = createFraudDetectionContext()

        mockDeviceProfiler.isJailbrokenResult = true
        mockUsageAnalyzer.mockPatterns = UsagePatterns(
            rapidSubscriptionChanges: 0,
            validationFrequency: 1,
            deviceChanges: 0,
            geographicAnomalies: 0
        )

        let expectation = XCTestExpectation(description: "Published properties updated")

        sut.$detectedEvents
            .dropFirst() // Skip initial empty state
            .sink { events in
                if !events.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        _ = try await sut.detectFraud(for: entitlement, context: context)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.detectedEvents.isEmpty)
        XCTAssertGreaterThan(sut.fraudScore, 0.0)
    }

    // MARK: - Helper Methods

    private func createValidEntitlement() -> SubscriptionEntitlement {
        return SubscriptionEntitlement(
            id: UUID().uuidString,
            familyID: "test-family",
            subscriptionTier: .oneChild,
            receiptData: "dGVzdCByZWNlaXB0IGRhdGEgdGhhdCBpcyBsb25nIGVub3VnaCB0byBiZSBjb25zaWRlcmVkIHZhbGlkIGFuZCBpcyBwcm9wZXJseSBiYXNlNjQgZW5jb2RlZA==",
            originalTransactionID: "original-123",
            transactionID: "transaction-123",
            purchaseDate: Date().addingTimeInterval(-86400),
            expirationDate: Date().addingTimeInterval(86400),
            isActive: true
        )
    }

    private func createFraudDetectionContext() -> FraudDetectionContext {
        return FraudDetectionContext(
            deviceInfo: [
                "device_model": "iPhone14,2",
                "system_version": "15.0"
            ],
            userAgent: "ScreenTimeRewards/1.0",
            ipAddress: "192.168.1.1"
        )
    }
}

// MARK: - Mock Classes

class MockFraudDetectionRepository: FraudDetectionRepository {
    var mockFraudEvents: [FraudDetectionEvent] = []
    var mockDuplicateEntitlements: [SubscriptionEntitlement] = []
    var createFraudEventCalled = false

    func createFraudEvent(_ event: FraudDetectionEvent) async throws -> FraudDetectionEvent {
        createFraudEventCalled = true
        return event
    }

    func fetchFraudEvents(for familyID: String, since date: Date) async throws -> [FraudDetectionEvent] {
        return mockFraudEvents.filter { $0.familyID == familyID && $0.timestamp >= date }
    }

    func findEntitlementsByTransactionID(_ transactionID: String) async throws -> [SubscriptionEntitlement] {
        return mockDuplicateEntitlements.filter { $0.transactionID == transactionID }
    }
}

class MockValidationAuditRepository: ValidationAuditRepository {
    var createAuditLogCalled = false

    func createAuditLog(_ log: ValidationAuditLog) async throws -> ValidationAuditLog {
        createAuditLogCalled = true
        return log
    }

    func fetchAuditLogs(for familyID: String, eventType: ValidationEventType?) async throws -> [ValidationAuditLog] {
        return []
    }
}

class MockDeviceProfiler: DeviceProfiler {
    var isJailbrokenResult = false

    func isJailbroken() -> Bool {
        return isJailbrokenResult
    }

    func getDeviceInfo() -> [String: String] {
        return [
            "device_model": "iPhone14,2",
            "system_version": "15.0"
        ]
    }

    func detectTampering() -> Bool {
        return isJailbrokenResult
    }
}

class MockUsagePatternAnalyzer: UsagePatternAnalyzer {
    var mockPatterns = UsagePatterns(
        rapidSubscriptionChanges: 0,
        validationFrequency: 1,
        deviceChanges: 0,
        geographicAnomalies: 0
    )

    func analyzeUsagePatterns(familyID: String, timeRange: DateRange) async throws -> UsagePatterns {
        return mockPatterns
    }
}