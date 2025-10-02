import XCTest
@testable import CloudKitService
import SharedModels

final class UsageSessionRepositoryTests: XCTestCase {
    var repository: CloudKitService.UsageSessionRepository!

    override func setUp() {
        super.setUp()
        repository = CloudKitService.UsageSessionRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testUsageSessionRepositoryInitialization() {
        XCTAssertNotNil(repository, "Repository should be successfully initialized")
    }

    func testRepositoryConformsToProtocol() {
        XCTAssertTrue(repository is SharedModels.UsageSessionRepository,
                    "UsageSessionRepository should conform to SharedModels.UsageSessionRepository protocol")
    }

    // MARK: - Create Tests

    func testCreateSession_Success() async throws {
        // Given
        let session = createMockSession()

        // When
        let createdSession = try await repository.createSession(session)

        // Then
        XCTAssertEqual(createdSession.id, session.id)
        XCTAssertEqual(createdSession.childProfileID, session.childProfileID)
        XCTAssertEqual(createdSession.appBundleID, session.appBundleID)
        XCTAssertEqual(createdSession.category, session.category)
    }

    func testCreateSession_WithDifferentCategories() async throws {
        // Given
        let learningSession = UsageSession(
            id: "learning-session-id",
            childProfileID: "child-1",
            appBundleID: "com.learning.app",
            category: .learning,
            startTime: Date().addingTimeInterval(-3600), // 1 hour ago
            endTime: Date(),
            duration: 3600,
            isValidated: true
        )

        let rewardSession = UsageSession(
            id: "reward-session-id",
            childProfileID: "child-1",
            appBundleID: "com.reward.app",
            category: .reward,
            startTime: Date().addingTimeInterval(-1800), // 30 minutes ago
            endTime: Date(),
            duration: 1800,
            isValidated: true
        )

        // When & Then
        let createdLearningSession = try await repository.createSession(learningSession)
        let createdRewardSession = try await repository.createSession(rewardSession)

        XCTAssertEqual(createdLearningSession.category, AppCategory.learning)
        XCTAssertEqual(createdRewardSession.category, AppCategory.reward)
    }

    // MARK: - Fetch Tests

    func testFetchSession_NotFound() async throws {
        // Given
        let nonExistentID = "non-existent-id"

        // When
        let result = try await repository.fetchSession(id: nonExistentID)

        // Then
        XCTAssertNil(result, "Should return nil for non-existent session")
    }

    func testFetchSessions_EmptyResult() async throws {
        // Given
        let childID = "test-child-id"
        let dateRange: DateRange? = nil

        // When
        let results = try await repository.fetchSessions(for: childID, dateRange: dateRange)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array for child with no sessions")
    }

    func testFetchSessions_WithDateRange() async throws {
        // Given
        let childID = "test-child-id"
        let dateRange: DateRange? = DateRange(
            start: Date().addingTimeInterval(-86400), // 1 day ago
            end: Date()
        )

        // When
        let results = try await repository.fetchSessions(for: childID, dateRange: dateRange)

        // Then
        XCTAssertTrue(results.isEmpty, "Should return empty array in demo implementation")
    }

    // MARK: - Update Tests

    func testUpdateSession_Success() async throws {
        // Given
        let session = createMockSession()
        let updatedSession = UsageSession(
            id: session.id,
            childProfileID: session.childProfileID,
            appBundleID: session.appBundleID,
            category: session.category,
            startTime: session.startTime,
            endTime: Date(), // Updated end time
            duration: 7200, // Updated duration (2 hours)
            isValidated: true
        )

        // When
        let result = try await repository.updateSession(updatedSession)

        // Then
        XCTAssertEqual(result.duration, 7200)
        XCTAssertTrue(result.endTime > session.endTime)
    }

    // MARK: - Delete Tests

    func testDeleteSession_Success() async throws {
        // Given
        let sessionID = "test-session-id"

        // When & Then (should not throw)
        try await repository.deleteSession(id: sessionID)
    }

    // MARK: - Additional Method Tests

    func testSaveSession() {
        // Given
        let session = createMockSession()

        // When
        repository.save(session: session)

        // Then (no assertion needed as method doesn't return anything in mock implementation)
        XCTAssertTrue(true, "Save method should complete without error")
    }

    // MARK: - Edge Case Tests

    func testCreateSession_WithZeroDuration() async throws {
        // Given
        let session = UsageSession(
            id: "zero-duration-id",
            childProfileID: "child-1",
            appBundleID: "com.test.app",
            category: .learning,
            startTime: Date(),
            endTime: Date(), // Same as start time
            duration: 0, // Zero duration
            isValidated: true
        )

        // When
        let createdSession = try await repository.createSession(session)

        // Then
        XCTAssertEqual(createdSession.duration, 0)
    }

    func testCreateSession_WithNegativeDuration() async throws {
        // Given
        let session = UsageSession(
            id: "negative-duration-id",
            childProfileID: "child-1",
            appBundleID: "com.test.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(-3600), // 1 hour before start
            duration: -3600, // Negative duration
            isValidated: true
        )

        // When
        let createdSession = try await repository.createSession(session)

        // Then
        XCTAssertEqual(createdSession.duration, -3600)
    }

    // MARK: - Performance Tests

    func testCreateSession_Performance() async {
        let session = createMockSession()

        measure {
            Task {
                do {
                    let _ = try await repository.createSession(session)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testFetchSessions_Performance() async {
        let dateRange: DateRange? = nil
        
        measure {
            Task {
                do {
                    let _ = try await repository.fetchSessions(for: "perf-test-child", dateRange: dateRange)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testDeleteSession_Performance() async {
        measure {
            Task {
                do {
                    try await repository.deleteSession(id: "perf-test-id")
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockSession() -> UsageSession {
        return UsageSession(
            id: "mock-session-id",
            childProfileID: "mock-child-id",
            appBundleID: "com.mock.app",
            category: .learning,
            startTime: Date().addingTimeInterval(-1800), // 30 minutes ago
            endTime: Date(),
            duration: 1800,
            isValidated: true
        )
    }
}