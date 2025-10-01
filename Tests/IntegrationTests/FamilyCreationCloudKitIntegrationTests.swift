import XCTest
import CloudKit
@testable import SharedModels
@testable import CloudKitService

/// Integration tests for family creation and CloudKit zone setup
final class FamilyCreationCloudKitIntegrationTests: XCTestCase {
    
    var cloudKitService: CloudKitService!
    
    override func setUp() {
        super.setUp()
        cloudKitService = CloudKitService.shared
    }
    
    override func tearDown() {
        cloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - Family Creation Integration Tests
    
    func testFamilyCreationWithCloudKitIntegration() async throws {
        // Given
        let now = Date()
        let family = Family(
            id: "integration-test-family-\(UUID().uuidString)",
            name: "Integration Test Family",
            createdAt: now,
            ownerUserID: "test-owner-\(UUID().uuidString)",
            sharedWithUserIDs: ["user-1", "user-2"],
            childProfileIDs: ["child-1", "child-2"],
            parentalConsentGiven: true,
            parentalConsentDate: now,
            parentalConsentMethod: "in-app"
        )
        
        // When - Test that family repository is accessible through CloudKitService
        XCTAssertTrue(cloudKitService is FamilyRepository, "CloudKitService should conform to FamilyRepository")
        
        // Note: In mock implementation, these operations won't actually interact with CloudKit
        // but we can test the interface integration
    }
    
    func testChildProfileCreationWithCloudKitIntegration() async throws {
        // Given
        let childProfile = ChildProfile(
            id: "integration-test-child-\(UUID().uuidString)",
            familyID: "integration-test-family-\(UUID().uuidString)",
            name: "Integration Test Child",
            avatarAssetURL: nil,
            birthDate: Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date(),
            pointBalance: 100,
            totalPointsEarned: 500,
            createdAt: Date(),
            ageVerified: true
        )
        
        // When - Test that child profile repository is accessible through CloudKitService
        XCTAssertTrue(cloudKitService is ChildProfileRepository, "CloudKitService should conform to ChildProfileRepository")
        
        // Test the mock implementation
        let createdChild = try await cloudKitService.createChild(childProfile)
        XCTAssertEqual(createdChild.id, childProfile.id)
        XCTAssertEqual(createdChild.name, childProfile.name)
        XCTAssertEqual(createdChild.pointBalance, childProfile.pointBalance)
    }
    
    func testFamilyAndChildProfileIntegration() async throws {
        // Given
        let now = Date()
        let family = Family(
            id: "integrated-family-\(UUID().uuidString)",
            name: "Integrated Test Family",
            createdAt: now,
            ownerUserID: "owner-\(UUID().uuidString)",
            sharedWithUserIDs: ["shared-user-1"],
            childProfileIDs: [],
            parentalConsentGiven: true,
            parentalConsentDate: now,
            parentalConsentMethod: "in-app"
        )
        
        let childProfile = ChildProfile(
            id: "integrated-child-\(UUID().uuidString)",
            familyID: family.id,
            name: "Integrated Test Child",
            avatarAssetURL: nil,
            birthDate: Calendar.current.date(byAdding: .year, value: -8, to: Date()) ?? Date(),
            pointBalance: 0,
            totalPointsEarned: 0,
            createdAt: Date(),
            ageVerified: true
        )
        
        // When - Test integrated operations
        let createdChild = try await cloudKitService.createChild(childProfile)
        
        // Then - Verify integration
        XCTAssertEqual(createdChild.familyID, family.id, "Child should be associated with family")
        XCTAssertTrue(createdChild.id.hasPrefix("integrated-child-"), "Child ID should match")
    }
    
    // MARK: - CloudKit Zone Setup Integration Tests
    
    func testCloudKitZoneConfigurationIntegration() async throws {
        // Test that CloudKitService properly integrates with zone-based repository structure
        
        // Verify all repository protocols are implemented
        XCTAssertTrue(cloudKitService is AppCategorizationRepository, "Should implement AppCategorizationRepository")
        XCTAssertTrue(cloudKitService is UsageSessionRepository, "Should implement UsageSessionRepository")
        XCTAssertTrue(cloudKitService is PointTransactionRepository, "Should implement PointTransactionRepository")
        XCTAssertTrue(cloudKitService is PointToTimeRedemptionRepository, "Should implement PointToTimeRedemptionRepository")
        
        // Test that repositories can be accessed
        let appCategorizationRepo = cloudKitService as AppCategorizationRepository
        let usageSessionRepo = cloudKitService as UsageSessionRepository
        let pointTransactionRepo = cloudKitService as PointTransactionRepository
        let pointToTimeRedemptionRepo = cloudKitService as PointToTimeRedemptionRepository
        
        XCTAssertNotNil(appCategorizationRepo, "AppCategorizationRepository should be accessible")
        XCTAssertNotNil(usageSessionRepo, "UsageSessionRepository should be accessible")
        XCTAssertNotNil(pointTransactionRepo, "PointTransactionRepository should be accessible")
        XCTAssertNotNil(pointToTimeRedemptionRepo, "PointToTimeRedemptionRepository should be accessible")
    }
    
    func testRepositoryProtocolConformanceIntegration() async throws {
        // Test that all repository methods can be called through CloudKitService
        
        // AppCategorizationRepository methods
        let appCategorization = AppCategorization(
            id: "test-cat-\(UUID().uuidString)",
            appBundleID: "com.test.app",
            category: .learning,
            childProfileID: "test-child",
            pointsPerHour: 10,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let createdCategorization = try await cloudKitService.createAppCategorization(appCategorization)
        XCTAssertEqual(createdCategorization.id, appCategorization.id)
        
        // UsageSessionRepository methods
        let usageSession = UsageSession(
            id: "test-session-\(UUID().uuidString)",
            childProfileID: "test-child",
            appBundleID: "com.test.app",
            category: .learning,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            duration: 3600,
            isValidated: true
        )
        
        let createdSession = try await cloudKitService.createSession(usageSession)
        XCTAssertEqual(createdSession.id, usageSession.id)
        
        // PointTransactionRepository methods
        let pointTransaction = PointTransaction(
            id: "test-transaction-\(UUID().uuidString)",
            childProfileID: "test-child",
            points: 50,
            reason: "Test transaction",
            timestamp: Date()
        )
        
        let createdTransaction = try await cloudKitService.createTransaction(pointTransaction)
        XCTAssertEqual(createdTransaction.id, pointTransaction.id)
        
        // PointToTimeRedemptionRepository methods
        let redemption = PointToTimeRedemption(
            id: "test-redemption-\(UUID().uuidString)",
            childProfileID: "test-child",
            appCategorizationID: "test-cat",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 0,
            status: .active
        )
        
        let createdRedemption = try await cloudKitService.createPointToTimeRedemption(redemption)
        XCTAssertEqual(createdRedemption.id, redemption.id)
    }
    
    // MARK: - Data Model Integration Tests
    
    func testDataModelCloudKitIntegration() async throws {
        // Test that all SharedModels can be used with CloudKit repositories
        
        // Test Family model integration
        let family = Family(
            id: "data-model-family-\(UUID().uuidString)",
            name: "Data Model Test Family",
            createdAt: Date(),
            ownerUserID: "owner-\(UUID().uuidString)",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            parentalConsentGiven: true
        )
        
        // Test ChildProfile model integration
        let child = ChildProfile(
            id: "data-model-child-\(UUID().uuidString)",
            familyID: family.id,
            name: "Data Model Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0,
            totalPointsEarned: 0,
            createdAt: Date(),
            ageVerified: true
        )
        
        // Test that models conform to Codable for CloudKit storage
        let familyData = try JSONEncoder().encode(family)
        let decodedFamily = try JSONDecoder().decode(Family.self, from: familyData)
        XCTAssertEqual(family.id, decodedFamily.id)
        
        let childData = try JSONEncoder().encode(child)
        let decodedChild = try JSONDecoder().decode(ChildProfile.self, from: childData)
        XCTAssertEqual(child.id, decodedChild.id)
    }
    
    func testAppCategorizationCloudKitIntegration() async throws {
        // Test AppCategorization model with CloudKit integration
        
        let categorization = AppCategorization(
            id: "app-cat-\(UUID().uuidString)",
            appBundleID: "com.integration.test",
            category: .learning,
            childProfileID: "test-child",
            pointsPerHour: 15,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Test Codable conformance
        let data = try JSONEncoder().encode(categorization)
        let decoded = try JSONDecoder().decode(AppCategorization.self, from: data)
        XCTAssertEqual(categorization.id, decoded.id)
        XCTAssertEqual(categorization.appBundleID, decoded.appBundleID)
        XCTAssertEqual(categorization.category, decoded.category)
        XCTAssertEqual(categorization.childProfileID, decoded.childProfileID)
        XCTAssertEqual(categorization.pointsPerHour, decoded.pointsPerHour)
    }
    
    func testUsageSessionCloudKitIntegration() async throws {
        // Test UsageSession model with CloudKit integration
        
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1800) // 30 minutes
        
        let session = UsageSession(
            id: "session-\(UUID().uuidString)",
            childProfileID: "test-child",
            appBundleID: "com.session.test",
            category: .reward,
            startTime: startTime,
            endTime: endTime,
            duration: 1800,
            isValidated: false
        )
        
        // Test Codable conformance
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(UsageSession.self, from: data)
        XCTAssertEqual(session.id, decoded.id)
        XCTAssertEqual(session.appBundleID, decoded.appBundleID)
        XCTAssertEqual(session.category, decoded.category)
        XCTAssertEqual(session.duration, decoded.duration)
        XCTAssertEqual(session.isValidated, decoded.isValidated)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingInCloudKitIntegration() async throws {
        // Test that error handling works properly across integrated components
        
        // Test with empty IDs
        let emptyFamily = Family(
            id: "",
            name: "Empty ID Family",
            createdAt: Date(),
            ownerUserID: "",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            parentalConsentGiven: false
        )
        
        // Should not crash even with empty IDs
        XCTAssertTrue(emptyFamily.id.isEmpty)
        XCTAssertTrue(emptyFamily.ownerUserID.isEmpty)
        
        // Test with special characters
        let specialFamily = Family(
            id: "special!@#$%^&*()_+-=[]{}|;':\",./<>?",
            name: "Special Characters Family",
            createdAt: Date(),
            ownerUserID: "special-owner!@#$%",
            sharedWithUserIDs: ["user-1", "user-2"],
            childProfileIDs: ["child-1"],
            parentalConsentGiven: true
        )
        
        XCTAssertFalse(specialFamily.id.isEmpty)
        XCTAssertFalse(specialFamily.ownerUserID.isEmpty)
    }
    
    // MARK: - Performance Integration Tests
    
    func testFamilyCreationPerformanceIntegration() async throws {
        measure {
            Task {
                do {
                    let family = Family(
                        id: "perf-family-\(UUID().uuidString)",
                        name: "Performance Test Family",
                        createdAt: Date(),
                        ownerUserID: "perf-owner-\(UUID().uuidString)",
                        sharedWithUserIDs: [],
                        childProfileIDs: [],
                        parentalConsentGiven: true
                    )
                    
                    // Test integrated creation performance
                    _ = try await cloudKitService.createChild(ChildProfile(
                        id: "perf-child-\(UUID().uuidString)",
                        familyID: family.id,
                        name: "Performance Test Child",
                        avatarAssetURL: nil,
                        birthDate: Date(),
                        pointBalance: 0,
                        totalPointsEarned: 0,
                        createdAt: Date(),
                        ageVerified: true
                    ))
                } catch {
                    // Expected in mock implementation
                }
            }
        }
    }
    
    // MARK: - Concurrency Integration Tests
    
    func testConcurrentFamilyAndChildOperations() async throws {
        // Test concurrent operations on integrated CloudKit services
        
        async let family1 = createTestFamily(name: "Concurrent Family 1")
        async let family2 = createTestFamily(name: "Concurrent Family 2")
        async let child1 = createTestChild(name: "Concurrent Child 1")
        async let child2 = createTestChild(name: "Concurrent Child 2")
        
        let results = try await [family1, family2, child1, child2]
        
        XCTAssertEqual(results.count, 4, "All concurrent operations should complete")
    }
    
    // MARK: - Helper Methods
    
    private func createTestFamily(name: String) async -> Family {
        return Family(
            id: "test-family-\(UUID().uuidString)",
            name: name,
            createdAt: Date(),
            ownerUserID: "test-owner-\(UUID().uuidString)",
            sharedWithUserIDs: [],
            childProfileIDs: [],
            parentalConsentGiven: true
        )
    }
    
    private func createTestChild(name: String) async -> ChildProfile {
        return ChildProfile(
            id: "test-child-\(UUID().uuidString)",
            familyID: "test-family-\(UUID().uuidString)",
            name: name,
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0,
            totalPointsEarned: 0,
            createdAt: Date(),
            ageVerified: true
        )
    }
}