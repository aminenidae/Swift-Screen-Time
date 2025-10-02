import XCTest
@testable import CloudKitService
import SharedModels

final class PointToTimeRedemptionRepositoryTests: XCTestCase {
    var repository: CloudKitService.PointToTimeRedemptionRepository!

    override func setUp() {
        super.setUp()
        repository = CloudKitService.PointToTimeRedemptionRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testPointToTimeRedemptionRepositoryInitialization() {
        XCTAssertNotNil(repository, "Repository should be successfully initialized")
    }

    func testRepositoryConformsToProtocol() {
        XCTAssertTrue(repository is SharedModels.PointToTimeRedemptionRepository,
                    "PointToTimeRedemptionRepository should conform to SharedModels.PointToTimeRedemptionRepository protocol")
    }

    // MARK: - Create Tests

    func testCreatePointToTimeRedemption_Success() async throws {
        // Given
        let redemption = createMockRedemption()

        // When
        let createdRedemption = try await repository.createPointToTimeRedemption(redemption)

        // Then
        XCTAssertEqual(createdRedemption.id, redemption.id)
        XCTAssertEqual(createdRedemption.childProfileID, redemption.childProfileID)
        XCTAssertEqual(createdRedemption.pointsSpent, redemption.pointsSpent)
        XCTAssertEqual(createdRedemption.timeGrantedMinutes, redemption.timeGrantedMinutes)
        XCTAssertEqual(createdRedemption.status, redemption.status)
    }

    func testCreatePointToTimeRedemption_ValidatesData() async throws {
        // Given
        let redemption = PointToTimeRedemption(
            id: "test-id",
            childProfileID: "child-1",
            appCategorizationID: "app-1",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 0,
            status: .active
        )

        // When
        let createdRedemption = try await repository.createPointToTimeRedemption(redemption)

        // Then
        XCTAssertEqual(createdRedemption.conversionRate, 10.0)
        XCTAssertTrue(createdRedemption.expiresAt > createdRedemption.redeemedAt)
    }

    // MARK: - Fetch Tests

    func testFetchPointToTimeRedemption_NotFound() async throws {
        // Given
        let nonExistentID = "non-existent-id"

        // When
        let result = try await repository.fetchPointToTimeRedemption(id: nonExistentID)

        // Then
        XCTAssertNil(result, "Should return nil for non-existent redemption")
    }

    func testFetchPointToTimeRedemptions_EmptyResult() async throws {
        // Given
        let childID = "test-child-id"

        // When
        let results = try await repository.fetchPointToTimeRedemptions(for: childID)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array for child with no redemptions")
    }

    func testFetchActivePointToTimeRedemptions_EmptyResult() async throws {
        // Given
        let childID = "test-child-id"

        // When
        let results = try await repository.fetchActivePointToTimeRedemptions(for: childID)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array for child with no active redemptions")
    }

    // MARK: - Update Tests

    func testUpdatePointToTimeRedemption_Success() async throws {
        // Given
        let redemption = createMockRedemption()
        let updatedRedemption = PointToTimeRedemption(
            id: redemption.id,
            childProfileID: redemption.childProfileID,
            appCategorizationID: redemption.appCategorizationID,
            pointsSpent: redemption.pointsSpent,
            timeGrantedMinutes: redemption.timeGrantedMinutes,
            conversionRate: redemption.conversionRate,
            redeemedAt: redemption.redeemedAt,
            expiresAt: redemption.expiresAt,
            timeUsedMinutes: 5, // Updated usage
            status: .active
        )

        // When
        let result = try await repository.updatePointToTimeRedemption(updatedRedemption)

        // Then
        XCTAssertEqual(result.timeUsedMinutes, 5)
        XCTAssertEqual(result.status, RedemptionStatus.active)
    }

    func testUpdatePointToTimeRedemption_StatusChange() async throws {
        // Given
        let redemption = createMockRedemption()
        let expiredRedemption = PointToTimeRedemption(
            id: redemption.id,
            childProfileID: redemption.childProfileID,
            appCategorizationID: redemption.appCategorizationID,
            pointsSpent: redemption.pointsSpent,
            timeGrantedMinutes: redemption.timeGrantedMinutes,
            conversionRate: redemption.conversionRate,
            redeemedAt: redemption.redeemedAt,
            expiresAt: redemption.expiresAt,
            timeUsedMinutes: redemption.timeUsedMinutes,
            status: .expired // Changed to expired
        )

        // When
        let result = try await repository.updatePointToTimeRedemption(expiredRedemption)

        // Then
        XCTAssertEqual(result.status, RedemptionStatus.expired)
    }

    // MARK: - Delete Tests

    func testDeletePointToTimeRedemption_Success() async throws {
        // Given
        let redemptionID = "test-redemption-id"

        // When & Then (should not throw)
        try await repository.deletePointToTimeRedemption(id: redemptionID)
    }

    // MARK: - Helper Methods Tests

    func testFetchRedemptionsWithDateRange() async throws {
        // Given
        let childID = "test-child-id"
        let dateRange: DateRange? = DateRange(
            start: Date().addingTimeInterval(-86400), // 1 day ago
            end: Date()
        )

        // When
        let results = try await repository.fetchRedemptions(for: childID, dateRange: dateRange)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array in demo implementation")
    }

    func testFetchRedemptionsWithStatus() async throws {
        // Given
        let childID = "test-child-id"
        let status: RedemptionStatus = .active

        // When
        let results = try await repository.fetchRedemptions(for: childID, status: status)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array in demo implementation")
    }

    func testMarkExpiredRedemptions() async throws {
        // When
        let expiredCount = try await repository.markExpiredRedemptions()

        // Then
        XCTAssertEqual(expiredCount, 0, "Should return 0 in demo implementation")
    }

    func testGetRedemptionStats() async throws {
        // Given
        let childID = "test-child-id"

        // When
        let stats = try await repository.getRedemptionStats(for: childID)

        // Then
        XCTAssertEqual(stats.totalRedemptions, 0)
        XCTAssertEqual(stats.totalPointsSpent, 0)
        XCTAssertEqual(stats.totalTimeGranted, 0)
    }

    // MARK: - Performance Tests

    func testCreatePointToTimeRedemption_Performance() async {
        let redemption = createMockRedemption()

        measure {
            Task {
                do {
                    let _ = try await repository.createPointToTimeRedemption(redemption)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testFetchPointToTimeRedemptions_Performance() async {
        measure {
            Task {
                do {
                    let _ = try await repository.fetchPointToTimeRedemptions(for: "perf-test-child")
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testUpdatePointToTimeRedemption_Performance() async {
        let redemption = createMockRedemption()

        measure {
            Task {
                do {
                    let _ = try await repository.updatePointToTimeRedemption(redemption)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockRedemption() -> PointToTimeRedemption {
        return PointToTimeRedemption(
            id: "mock-redemption-id",
            childProfileID: "mock-child-id",
            appCategorizationID: "mock-app-cat-id",
            pointsSpent: 50,
            timeGrantedMinutes: 5,
            conversionRate: 10.0,
            redeemedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            timeUsedMinutes: 0,
            status: .active
        )
    }
}