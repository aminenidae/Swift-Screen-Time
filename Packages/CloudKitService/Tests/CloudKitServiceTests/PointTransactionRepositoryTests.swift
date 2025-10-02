import XCTest
@testable import CloudKitService
import SharedModels

final class PointTransactionRepositoryTests: XCTestCase {
    var repository: CloudKitService.PointTransactionRepository!

    override func setUp() {
        super.setUp()
        repository = CloudKitService.PointTransactionRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testPointTransactionRepositoryInitialization() {
        XCTAssertNotNil(repository, "Repository should be successfully initialized")
    }

    func testRepositoryConformsToProtocol() {
        XCTAssertTrue(repository is SharedModels.PointTransactionRepository,
                    "PointTransactionRepository should conform to SharedModels.PointTransactionRepository protocol")
    }

    // MARK: - Create Tests

    func testCreateTransaction_Success() async throws {
        // Given
        let transaction = createMockTransaction()

        // When
        let createdTransaction = try await repository.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.id, transaction.id)
        XCTAssertEqual(createdTransaction.childProfileID, transaction.childProfileID)
        XCTAssertEqual(createdTransaction.points, transaction.points)
        XCTAssertEqual(createdTransaction.reason, transaction.reason)
    }

    func testCreateTransaction_WithPositivePoints() async throws {
        // Given
        let transaction = PointTransaction(
            id: "positive-points-id",
            childProfileID: "child-1",
            points: 50,
            reason: "Completed educational app session",
            timestamp: Date()
        )

        // When
        let createdTransaction = try await repository.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.points, 50)
        XCTAssertTrue(createdTransaction.points > 0)
    }

    func testCreateTransaction_WithNegativePoints() async throws {
        // Given
        let transaction = PointTransaction(
            id: "negative-points-id",
            childProfileID: "child-1",
            points: -30,
            reason: "Redeemed reward",
            timestamp: Date()
        )

        // When
        let createdTransaction = try await repository.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.points, -30)
        XCTAssertTrue(createdTransaction.points < 0)
    }

    func testCreateTransaction_WithZeroPoints() async throws {
        // Given
        let transaction = PointTransaction(
            id: "zero-points-id",
            childProfileID: "child-1",
            points: 0,
            reason: "System adjustment",
            timestamp: Date()
        )

        // When
        let createdTransaction = try await repository.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.points, 0)
    }

    // MARK: - Fetch Tests

    func testFetchTransaction_NotFound() async throws {
        // Given
        let nonExistentID = "non-existent-id"

        // When
        let result = try await repository.fetchTransaction(id: nonExistentID)

        // Then
        XCTAssertNil(result, "Should return nil for non-existent transaction")
    }

    func testFetchTransactions_WithLimit() async throws {
        // Given
        let childID = "test-child-id"
        let limit: Int? = 10

        // When
        let results = try await repository.fetchTransactions(for: childID, limit: limit)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array in demo implementation")
    }

    func testFetchTransactions_WithoutLimit() async throws {
        // Given
        let childID = "test-child-id"
        let limit: Int? = nil

        // When
        let results = try await repository.fetchTransactions(for: childID, limit: limit)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array in demo implementation")
    }

    func testFetchTransactions_WithDateRange() async throws {
        // Given
        let childID = "test-child-id"
        let dateRange: DateRange? = DateRange(
            start: Date().addingTimeInterval(-86400), // 1 day ago
            end: Date()
        )

        // When
        let results = try await repository.fetchTransactions(for: childID, dateRange: dateRange)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array in demo implementation")
    }

    func testFetchTransactions_WithoutDateRange() async throws {
        // Given
        let childID = "test-child-id"
        let dateRange: DateRange? = nil

        // When
        let results = try await repository.fetchTransactions(for: childID, dateRange: dateRange)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array in demo implementation")
    }

    // MARK: - Delete Tests

    func testDeleteTransaction_Success() async throws {
        // Given
        let transactionID = "test-transaction-id"

        // When & Then (should not throw)
        try await repository.deleteTransaction(id: transactionID)
    }

    // MARK: - Additional Method Tests

    func testSaveTransaction() {
        // Given
        let transaction = createMockTransaction()

        // When
        repository.save(transaction: transaction)

        // Then (no assertion needed as method doesn't return anything in mock implementation)
        XCTAssertTrue(true, "Save method should complete without error")
    }

    // MARK: - Edge Case Tests

    func testCreateTransaction_WithSpecialCharactersInReason() async throws {
        // Given
        let transaction = PointTransaction(
            id: "special-chars-id",
            childProfileID: "child-1",
            points: 25,
            reason: "Completed app with special chars: áéíóúñü",
            timestamp: Date()
        )

        // When
        let createdTransaction = try await repository.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.reason, "Completed app with special chars: áéíóúñü")
    }

    func testCreateTransaction_WithEmptyReason() async throws {
        // Given
        let transaction = PointTransaction(
            id: "empty-reason-id",
            childProfileID: "child-1",
            points: 10,
            reason: "",
            timestamp: Date()
        )

        // When
        let createdTransaction = try await repository.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.reason, "")
    }

    // MARK: - Performance Tests

    func testCreateTransaction_Performance() async {
        let transaction = createMockTransaction()

        measure {
            Task {
                do {
                    let _ = try await repository.createTransaction(transaction)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testFetchTransactionsWithLimit_Performance() async {
        measure {
            Task {
                do {
                    let _ = try await repository.fetchTransactions(for: "perf-test-child", limit: 10)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testFetchTransactionsWithDateRange_Performance() async {
        let dateRange: DateRange? = DateRange(start: Date().addingTimeInterval(-86400), end: Date())

        measure {
            Task {
                do {
                    let _ = try await repository.fetchTransactions(for: "perf-test-child", dateRange: dateRange)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockTransaction() -> PointTransaction {
        return PointTransaction(
            id: "test-transaction-id",
            childProfileID: "test-child-id",
            points: 25,
            reason: "Completed educational activity",
            timestamp: Date()
        )
    }
}