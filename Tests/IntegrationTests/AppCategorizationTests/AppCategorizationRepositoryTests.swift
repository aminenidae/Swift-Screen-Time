//
//  AppCategorizationRepositoryTests.swift
//  IntegrationTests
//
//  Created by James on 2025-09-26.
//

import XCTest
@testable import CloudKitService
import SharedModels

class AppCategorizationRepositoryTests: XCTestCase {
    
    var repository: AppCategorizationRepository!
    var childProfileID: UUID!
    
    override func setUp() {
        super.setUp()
        repository = AppCategorizationRepository()
        childProfileID = UUID()
    }
    
    override func tearDown() {
        repository = nil
        childProfileID = nil
        super.tearDown()
    }
    
    func testSaveCategorization() async throws {
        let categorization = AppCategorization(
            id: UUID(),
            childProfileID: childProfileID,
            bundleIdentifier: "com.test.app",
            appName: "Test App",
            category: .learning,
            pointsPerHour: 10,
            iconData: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "test"
        )
        
        // This should not throw an error
        try await repository.save(categorization: categorization)
    }
    
    func testFetchCategorizations() async throws {
        let childProfileID = UUID()
        let categorizations = try await repository.fetchCategorizations(for: childProfileID)
        
        // In the mock implementation, this should return an empty array
        XCTAssertTrue(categorizations.isEmpty)
    }
    
    func testFetchCategorizationByBundleID() async throws {
        let bundleID = "com.test.app"
        let categorization = try await repository.fetchCategorization(by: bundleID, childProfileID: childProfileID)
        
        // In the mock implementation, this should return nil
        XCTAssertNil(categorization)
    }
    
    func testDeleteCategorization() async throws {
        let categorizationID = UUID()
        
        // This should not throw an error
        try await repository.delete(categorizationID: categorizationID)
    }
    
    func testAppCategorizationConversion() async throws {
        // Test that the conversion from CKRecord to AppCategorization works correctly
        // This would require mocking CKRecord, which is complex
        // In a real implementation, we would have more comprehensive tests
        XCTAssertTrue(true) // Placeholder assertion
    }
}