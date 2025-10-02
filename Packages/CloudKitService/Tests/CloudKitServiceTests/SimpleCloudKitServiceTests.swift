import XCTest
@testable import CloudKitService
import SharedModels

final class SimpleCloudKitServiceTests: XCTestCase {
    
    func testAppCategorizationRepositoryCreation() {
        let repository = CloudKitService.CloudKitAppCategorizationRepository()
        XCTAssertNotNil(repository)
    }
    
    func testSaveCategorization() async throws {
        let repository = CloudKitService.CloudKitAppCategorizationRepository()
        let categorization = AppCategorization(
            id: "test-id",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "child-123",
            pointsPerHour: 10,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // This should not throw an error in the mock implementation
        try await repository.saveCategorization(categorization)
    }
    
    func testFetchCategorizations() async throws {
        let repository = CloudKitService.CloudKitAppCategorizationRepository()
        let categorizations = try await repository.fetchCategorizations(for: "child-123")
        
        // In the mock implementation, this should return an empty array
        XCTAssertTrue(categorizations.isEmpty)
    }
    
    func testDeleteCategorization() async throws {
        let repository = CloudKitService.CloudKitAppCategorizationRepository()
        
        // This should not throw an error in the mock implementation
        try await repository.deleteCategorization(with: "test-id")
    }
}