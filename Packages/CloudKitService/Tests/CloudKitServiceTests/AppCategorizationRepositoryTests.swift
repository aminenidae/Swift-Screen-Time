import XCTest
@testable import CloudKitService
import SharedModels

final class AppCategorizationRepositoryTests: XCTestCase {
    var repository: CloudKitService.CloudKitAppCategorizationRepository!

    override func setUp() {
        super.setUp()
        repository = CloudKitService.CloudKitAppCategorizationRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testAppCategorizationRepositoryInitialization() {
        XCTAssertNotNil(repository, "Repository should be successfully initialized")
    }

    func testRepositoryConformsToProtocol() {
        XCTAssertTrue(repository is SharedModels.AppCategorizationRepository,
                    "AppCategorizationRepository should conform to SharedModels.AppCategorizationRepository protocol")
    }

    // MARK: - Save Categorization Tests

    func testSaveCategorization_Success() async throws {
        // Given
        let categorization = AppCategorization(
            id: "test-id",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child-123",
            pointsPerHour: 10,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When & Then (should not throw in mock implementation)
        try await repository.saveCategorization(categorization)
    }

    func testSaveCategorization_WithRewardCategory() async throws {
        // Given
        let categorization = AppCategorization(
            id: "test-id-2",
            appBundleID: "com.game.app",
            category: .reward,
            childProfileID: "child-456",
            pointsPerHour: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When & Then (should not throw in mock implementation)
        try await repository.saveCategorization(categorization)
    }

    // MARK: - Fetch Categorizations Tests

    func testFetchCategorizations_EmptyResult() async throws {
        // Given
        let childID = "test-child-id"

        // When
        let categorizations = try await repository.fetchCategorizations(for: childID)

        // Then
        XCTAssertTrue(categorizations.isEmpty, "Should return empty array in mock implementation")
    }

    func testFetchCategorizations_ForDifferentChildren() async throws {
        // Given
        let childID1 = "child-1"
        let childID2 = "child-2"

        // When
        let categorizations1 = try await repository.fetchCategorizations(for: childID1)
        let categorizations2 = try await repository.fetchCategorizations(for: childID2)

        // Then
        XCTAssertTrue(categorizations1.isEmpty, "Should return empty array for first child")
        XCTAssertTrue(categorizations2.isEmpty, "Should return empty array for second child")
    }

    // MARK: - Delete Categorization Tests

    func testDeleteCategorization_Success() async throws {
        // Given
        let categorizationID = "test-categorization-id"

        // When & Then (should not throw in mock implementation)
        try await repository.deleteCategorization(with: categorizationID)
    }

    func testDeleteCategorization_WithNonExistentID() async throws {
        // Given
        let nonExistentID = "non-existent-id"

        // When & Then (should not throw in mock implementation)
        try await repository.deleteCategorization(with: nonExistentID)
    }

    // MARK: - Integration Tests

    // MARK: - Performance Tests

    func testSaveCategorization_Performance() async {
        let categorization = AppCategorization(
            id: UUID().uuidString,
            appBundleID: "com.performance.test",
            category: .learning,
            childProfileID: "perf-test-child",
            pointsPerHour: 15,
            createdAt: Date(),
            updatedAt: Date()
        )

        measure {
            Task {
                do {
                    try await repository.saveCategorization(categorization)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testFetchCategorizations_Performance() async {
        measure {
            Task {
                do {
                    let _ = try await repository.fetchCategorizations(for: "perf-test-child")
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testDeleteCategorization_Performance() async {
        measure {
            Task {
                do {
                    try await repository.deleteCategorization(with: "perf-test-id")
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Edge Case Tests

    func testSaveCategorization_WithSpecialCharacters() async throws {
        // Given
        let categorization = AppCategorization(
            id: "test-id-with-special-chars-123",
            appBundleID: "com.example.app-with.dots-and-dashes",
            category: .learning,
            childProfileID: "child-with-special-chars-456",
            pointsPerHour: 20,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When & Then (should not throw in mock implementation)
        try await repository.saveCategorization(categorization)
    }

    func testSaveCategorization_WithZeroPoints() async throws {
        // Given
        let categorization = AppCategorization(
            id: "zero-points-id",
            appBundleID: "com.example.learning-app",
            category: .learning,
            childProfileID: "child-789",
            pointsPerHour: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When & Then (should not throw in mock implementation)
        try await repository.saveCategorization(categorization)
    }

    // MARK: - Error Handling Tests

    func testRepositoryOperations_DoNotThrowInMockImplementation() async {
        // All repository operations should handle errors gracefully in this mock implementation
        do {
            // Test save operation
            let categorization = AppCategorization(
                id: "error-test-id",
                appBundleID: "com.error.test",
                category: .learning,
                childProfileID: "error-test-child",
                pointsPerHour: 10,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await repository.saveCategorization(categorization)
            
            // Test fetch operation
            let fetchedCategorizations = try await repository.fetchCategorizations(for: "error-test-child")
            XCTAssertTrue(fetchedCategorizations.isEmpty)
            
            // Test delete operation
            try await repository.deleteCategorization(with: "error-test-id")
            
        } catch {
            XCTFail("Repository operations should not throw in mock implementation: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockCategorization() -> AppCategorization {
        return AppCategorization(
            id: "mock-categorization-id",
            appBundleID: "com.mock.app",
            category: .learning,
            childProfileID: "mock-child-id",
            pointsPerHour: 15,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}