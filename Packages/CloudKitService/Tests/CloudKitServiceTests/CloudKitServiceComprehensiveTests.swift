import XCTest
@testable import CloudKitService
import SharedModels

final class CloudKitServiceComprehensiveTests: XCTestCase {

    var cloudKitService: CloudKitService!

    override func setUp() {
        super.setUp()
        cloudKitService = CloudKitService.shared
    }

    override func tearDown() {
        cloudKitService = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testCloudKitService_Singleton() {
        // Test that CloudKitService is properly implemented as a singleton
        let instance1 = CloudKitService.shared
        let instance2 = CloudKitService.shared

        XCTAssertTrue(instance1 === instance2, "CloudKitService should be a singleton")
    }

    // MARK: - Repository Protocol Conformance Tests

    func testCloudKitService_ConformsToChildProfileRepository() {
        XCTAssertTrue(cloudKitService is ChildProfileRepository, 
                    "CloudKitService should conform to ChildProfileRepository protocol")
    }

    func testCloudKitService_ConformsToAppCategorizationRepository() {
        XCTAssertTrue(cloudKitService is SharedModels.AppCategorizationRepository, 
                    "CloudKitService should conform to AppCategorizationRepository protocol")
    }

    func testCloudKitService_ConformsToUsageSessionRepository() {
        XCTAssertTrue(cloudKitService is SharedModels.UsageSessionRepository, 
                    "CloudKitService should conform to UsageSessionRepository protocol")
    }

    func testCloudKitService_ConformsToPointTransactionRepository() {
        XCTAssertTrue(cloudKitService is SharedModels.PointTransactionRepository, 
                    "CloudKitService should conform to PointTransactionRepository protocol")
    }

    func testCloudKitService_ConformsToPointToTimeRedemptionRepository() {
        XCTAssertTrue(cloudKitService is SharedModels.PointToTimeRedemptionRepository, 
                    "CloudKitService should conform to PointToTimeRedemptionRepository protocol")
    }

    // MARK: - Child Profile Repository Tests

    func testChildProfileRepository_CreateChild_Success() async throws {
        // Given
        let child = ChildProfile(
            id: "test-child-id",
            familyID: "test-family-id",
            name: "Test Child",
            avatarAssetURL: nil,
            birthDate: Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date(),
            pointBalance: 100,
            totalPointsEarned: 500,
            createdAt: Date(),
            ageVerified: true
        )

        // When
        let createdChild = try await cloudKitService.createChild(child)

        // Then
        XCTAssertEqual(createdChild.id, child.id)
        XCTAssertEqual(createdChild.familyID, child.familyID)
        XCTAssertEqual(createdChild.name, child.name)
        XCTAssertEqual(createdChild.pointBalance, child.pointBalance)
        XCTAssertEqual(createdChild.totalPointsEarned, child.totalPointsEarned)
    }

    func testChildProfileRepository_FetchChild_Existing() async throws {
        // Given
        let childID = "mock-child-id"

        // When
        let fetchedChild = try await cloudKitService.fetchChild(id: childID)

        // Then
        XCTAssertNotNil(fetchedChild)
        XCTAssertEqual(fetchedChild?.id, childID)
        XCTAssertEqual(fetchedChild?.name, "Demo Child")
        XCTAssertEqual(fetchedChild?.pointBalance, 450)
        XCTAssertEqual(fetchedChild?.totalPointsEarned, 1250)
    }

    func testChildProfileRepository_FetchChild_NonExistent() async throws {
        // Given
        let childID = "non-existent-id"

        // When
        let fetchedChild = try await cloudKitService.fetchChild(id: childID)

        // Then
        XCTAssertNil(fetchedChild)
    }

    func testChildProfileRepository_FetchChildren_ForFamily() async throws {
        // Given
        let familyID = "test-family-id"

        // When
        let children = try await cloudKitService.fetchChildren(for: familyID)

        // Then
        XCTAssertTrue(children.isEmpty, "Mock implementation should return empty array")
    }

    func testChildProfileRepository_UpdateChild_Success() async throws {
        // Given
        let child = ChildProfile(
            id: "update-test-id",
            familyID: "test-family-id",
            name: "Original Name",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 200,
            createdAt: Date(),
            ageVerified: true
        )

        let updatedChild = ChildProfile(
            id: "update-test-id",
            familyID: "test-family-id",
            name: "Updated Name",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 150,
            totalPointsEarned: 250,
            createdAt: Date(),
            ageVerified: true
        )

        // When
        let result = try await cloudKitService.updateChild(updatedChild)

        // Then
        XCTAssertEqual(result.id, updatedChild.id)
        XCTAssertEqual(result.name, updatedChild.name)
        XCTAssertEqual(result.pointBalance, updatedChild.pointBalance)
        XCTAssertEqual(result.totalPointsEarned, updatedChild.totalPointsEarned)
    }

    func testChildProfileRepository_DeleteChild_Success() async throws {
        // Given
        let childID = "delete-test-id"

        // When & Then (should not throw)
        try await cloudKitService.deleteChild(id: childID)
    }

    // MARK: - App Categorization Repository Tests

    func testAppCategorizationRepository_CreateAppCategorization_Success() async throws {
        // Given
        let categorization = AppCategorization(
            id: "test-categorization-id",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "test-child-id",
            pointsPerHour: 10,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let createdCategorization = try await cloudKitService.createAppCategorization(categorization)

        // Then
        XCTAssertEqual(createdCategorization.id, categorization.id)
        XCTAssertEqual(createdCategorization.appBundleID, categorization.appBundleID)
        XCTAssertEqual(createdCategorization.category, categorization.category)
        XCTAssertEqual(createdCategorization.childProfileID, categorization.childProfileID)
        XCTAssertEqual(createdCategorization.pointsPerHour, categorization.pointsPerHour)
    }

    func testAppCategorizationRepository_FetchAppCategorization_ReturnsNil() async throws {
        // Given
        let categorizationID = "test-categorization-id"

        // When
        let result = try await cloudKitService.fetchAppCategorization(id: categorizationID)

        // Then
        XCTAssertNil(result, "Mock implementation should return nil")
    }

    func testAppCategorizationRepository_FetchAppCategorizations_ForChild() async throws {
        // Given
        let childID = "test-child-id"

        // When
        let categorizations = try await cloudKitService.fetchAppCategorizations(for: childID)

        // Then
        XCTAssertTrue(categorizations.isEmpty, "Mock implementation should return empty array")
    }

    func testAppCategorizationRepository_UpdateAppCategorization_Success() async throws {
        // Given
        let categorization = AppCategorization(
            id: "update-test-id",
            appBundleID: "com.example.app",
            category: .learning,
            childProfileID: "test-child-id",
            pointsPerHour: 10,
            createdAt: Date(),
            updatedAt: Date()
        )

        let updatedCategorization = AppCategorization(
            id: "update-test-id",
            appBundleID: "com.updated.app",
            category: .reward,
            childProfileID: "test-child-id",
            pointsPerHour: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let result = try await cloudKitService.updateAppCategorization(updatedCategorization)

        // Then
        XCTAssertEqual(result.id, updatedCategorization.id)
        XCTAssertEqual(result.appBundleID, updatedCategorization.appBundleID)
        XCTAssertEqual(result.category, updatedCategorization.category)
        XCTAssertEqual(result.pointsPerHour, updatedCategorization.pointsPerHour)
    }

    func testAppCategorizationRepository_DeleteAppCategorization_Success() async throws {
        // Given
        let categorizationID = "delete-test-id"

        // When & Then (should not throw)
        try await cloudKitService.deleteAppCategorization(id: categorizationID)
    }

    // MARK: - Usage Session Repository Tests

    func testUsageSessionRepository_CreateSession_Success() async throws {
        // Given
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600)
        let session = UsageSession(
            id: "test-session-id",
            childProfileID: "test-child-id",
            appBundleID: "com.example.app",
            category: .learning,
            startTime: startTime,
            endTime: endTime,
            duration: 3600,
            isValidated: true
        )

        // When
        let createdSession = try await cloudKitService.createSession(session)

        // Then
        XCTAssertEqual(createdSession.id, session.id)
        XCTAssertEqual(createdSession.childProfileID, session.childProfileID)
        XCTAssertEqual(createdSession.appBundleID, session.appBundleID)
        XCTAssertEqual(createdSession.category, session.category)
        XCTAssertEqual(createdSession.duration, session.duration)
        XCTAssertEqual(createdSession.isValidated, session.isValidated)
    }

    func testUsageSessionRepository_FetchSession_ReturnsNil() async throws {
        // Given
        let sessionID = "test-session-id"

        // When
        let result = try await cloudKitService.fetchSession(id: sessionID)

        // Then
        XCTAssertNil(result, "Mock implementation should return nil")
    }

    func testUsageSessionRepository_FetchSessions_ForChild() async throws {
        // Given
        let childID = "test-child-id"
        let dateRange: DateRange? = nil

        // When
        let sessions = try await cloudKitService.fetchSessions(for: childID, dateRange: dateRange)

        // Then
        XCTAssertTrue(sessions.isEmpty, "Mock implementation should return empty array")
    }

    func testUsageSessionRepository_UpdateSession_Success() async throws {
        // Given
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600)
        let originalSession = UsageSession(
            id: "update-test-id",
            childProfileID: "test-child-id",
            appBundleID: "com.original.app",
            category: .learning,
            startTime: startTime,
            endTime: endTime,
            duration: 3600,
            isValidated: false
        )

        let updatedSession = UsageSession(
            id: "update-test-id",
            childProfileID: "test-child-id",
            appBundleID: "com.updated.app",
            category: .reward,
            startTime: startTime,
            endTime: endTime,
            duration: 3600,
            isValidated: true
        )

        // When
        let result = try await cloudKitService.updateSession(updatedSession)

        // Then
        XCTAssertEqual(result.id, updatedSession.id)
        XCTAssertEqual(result.appBundleID, updatedSession.appBundleID)
        XCTAssertEqual(result.category, updatedSession.category)
        XCTAssertEqual(result.isValidated, updatedSession.isValidated)
    }

    func testUsageSessionRepository_DeleteSession_Success() async throws {
        // Given
        let sessionID = "delete-test-id"

        // When & Then (should not throw)
        try await cloudKitService.deleteSession(id: sessionID)
    }

    // MARK: - Point Transaction Repository Tests

    func testPointTransactionRepository_CreateTransaction_Success() async throws {
        // Given
        let transaction = PointTransaction(
            id: "test-transaction-id",
            childProfileID: "test-child-id",
            points: 50,
            reason: "Completed learning session",
            timestamp: Date()
        )

        // When
        let createdTransaction = try await cloudKitService.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.id, transaction.id)
        XCTAssertEqual(createdTransaction.childProfileID, transaction.childProfileID)
        XCTAssertEqual(createdTransaction.points, transaction.points)
        XCTAssertEqual(createdTransaction.reason, transaction.reason)
        XCTAssertEqual(createdTransaction.timestamp, transaction.timestamp)
    }

    func testPointTransactionRepository_FetchTransaction_ReturnsNil() async throws {
        // Given
        let transactionID = "test-transaction-id"

        // When
        let result = try await cloudKitService.fetchTransaction(id: transactionID)

        // Then
        XCTAssertNil(result, "Mock implementation should return nil")
    }

    func testPointTransactionRepository_FetchTransactionsWithLimit_ForChild() async throws {
        // Given
        let childID = "test-child-id"
        let limit: Int? = 10

        // When
        let transactions = try await cloudKitService.fetchTransactions(for: childID, limit: limit)

        // Then
        XCTAssertTrue(transactions.isEmpty, "Mock implementation should return empty array")
    }

    func testPointTransactionRepository_FetchTransactionsWithDateRange_ForChild() async throws {
        // Given
        let childID = "test-child-id"
        let dateRange = DateRange(start: Date().addingTimeInterval(-86400), end: Date())

        // When
        let transactions = try await cloudKitService.fetchTransactions(for: childID, dateRange: dateRange)

        // Then
        XCTAssertTrue(transactions.isEmpty, "Mock implementation should return empty array")
    }

    func testPointTransactionRepository_DeleteTransaction_Success() async throws {
        // Given
        let transactionID = "delete-test-id"

        // When & Then (should not throw)
        try await cloudKitService.deleteTransaction(id: transactionID)
    }

    // MARK: - Point To Time Redemption Repository Tests

    func testPointToTimeRedemptionRepository_CreatePointToTimeRedemption_Success() async throws {
        // Given
        let redemption = PointToTimeRedemption(
            id: "test-redemption-id",
            childProfileID: "test-child-id",
            appCategorizationID: "test-app-cat-id",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 0,
            status: .active
        )

        // When
        let createdRedemption = try await cloudKitService.createPointToTimeRedemption(redemption)

        // Then
        XCTAssertEqual(createdRedemption.id, redemption.id)
        XCTAssertEqual(createdRedemption.childProfileID, redemption.childProfileID)
        XCTAssertEqual(createdRedemption.pointsSpent, redemption.pointsSpent)
        XCTAssertEqual(createdRedemption.timeGrantedMinutes, redemption.timeGrantedMinutes)
        XCTAssertEqual(createdRedemption.status, redemption.status)
    }

    func testPointToTimeRedemptionRepository_FetchPointToTimeRedemption_ReturnsNil() async throws {
        // Given
        let redemptionID = "test-redemption-id"

        // When
        let result = try await cloudKitService.fetchPointToTimeRedemption(id: redemptionID)

        // Then
        XCTAssertNil(result, "Mock implementation should return nil")
    }

    func testPointToTimeRedemptionRepository_FetchPointToTimeRedemptions_ForChild() async throws {
        // Given
        let childID = "test-child-id"

        // When
        let redemptions = try await cloudKitService.fetchPointToTimeRedemptions(for: childID)

        // Then
        XCTAssertTrue(redemptions.isEmpty, "Mock implementation should return empty array")
    }

    func testPointToTimeRedemptionRepository_FetchActivePointToTimeRedemptions_ForChild() async throws {
        // Given
        let childID = "test-child-id"

        // When
        let redemptions = try await cloudKitService.fetchActivePointToTimeRedemptions(for: childID)

        // Then
        XCTAssertTrue(redemptions.isEmpty, "Mock implementation should return empty array")
    }

    func testPointToTimeRedemptionRepository_UpdatePointToTimeRedemption_Success() async throws {
        // Given
        let originalRedemption = PointToTimeRedemption(
            id: "update-test-id",
            childProfileID: "test-child-id",
            appCategorizationID: "test-app-cat-id",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 0,
            status: .active
        )

        let updatedRedemption = PointToTimeRedemption(
            id: "update-test-id",
            childProfileID: "test-child-id",
            appCategorizationID: "test-app-cat-id",
            pointsSpent: 100,
            timeGrantedMinutes: 10,
            conversionRate: 10.0,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            timeUsedMinutes: 5,
            status: .active
        )

        // When
        let result = try await cloudKitService.updatePointToTimeRedemption(updatedRedemption)

        // Then
        XCTAssertEqual(result.id, updatedRedemption.id)
        XCTAssertEqual(result.timeUsedMinutes, updatedRedemption.timeUsedMinutes)
    }

    func testPointToTimeRedemptionRepository_DeletePointToTimeRedemption_Success() async throws {
        // Given
        let redemptionID = "delete-test-id"

        // When & Then (should not throw)
        try await cloudKitService.deletePointToTimeRedemption(id: redemptionID)
    }

    // MARK: - Performance Tests

    func testCloudKitService_CreateChild_Performance() async {
        let child = ChildProfile(
            id: UUID().uuidString,
            familyID: "perf-test-family",
            name: "Performance Test Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0,
            totalPointsEarned: 0,
            createdAt: Date(),
            ageVerified: true
        )

        measure {
            Task {
                do {
                    let _ = try await cloudKitService.createChild(child)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    func testCloudKitService_FetchChild_Performance() async {
        measure {
            Task {
                do {
                    let _ = try await cloudKitService.fetchChild(id: "perf-test-id")
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }

    // MARK: - Edge Case Tests

    func testCloudKitService_CreateChild_WithSpecialCharacters() async throws {
        // Given
        let child = ChildProfile(
            id: "test-child-id-with-special-chars-123",
            familyID: "test-family-id-with-special-chars-456",
            name: "Test Child With Special Characters: !@#$%^&*()",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 100,
            totalPointsEarned: 200,
            createdAt: Date(),
            ageVerified: true
        )

        // When
        let createdChild = try await cloudKitService.createChild(child)

        // Then
        XCTAssertEqual(createdChild.id, child.id)
        XCTAssertEqual(createdChild.name, child.name)
    }

    func testCloudKitService_CreateChild_WithZeroPoints() async throws {
        // Given
        let child = ChildProfile(
            id: "zero-points-id",
            familyID: "test-family-id",
            name: "Zero Points Child",
            avatarAssetURL: nil,
            birthDate: Date(),
            pointBalance: 0,
            totalPointsEarned: 0,
            createdAt: Date(),
            ageVerified: true
        )

        // When
        let createdChild = try await cloudKitService.createChild(child)

        // Then
        XCTAssertEqual(createdChild.pointBalance, 0)
        XCTAssertEqual(createdChild.totalPointsEarned, 0)
    }

    // MARK: - Error Handling Tests

    func testCloudKitService_AllOperations_HandleErrorsGracefully() async {
        // All CloudKitService operations should handle errors gracefully in this mock implementation
        do {
            // Test ChildProfileRepository operations
            let child = ChildProfile(
                id: "error-test-child",
                familyID: "error-test-family",
                name: "Error Test Child",
                avatarAssetURL: nil,
                birthDate: Date(),
                pointBalance: 100,
                totalPointsEarned: 200,
                createdAt: Date(),
                ageVerified: true
            )
            
            let _ = try await cloudKitService.createChild(child)
            let _ = try await cloudKitService.fetchChild(id: "error-test-child")
            let _ = try await cloudKitService.fetchChildren(for: "error-test-family")
            let _ = try await cloudKitService.updateChild(child)
            try await cloudKitService.deleteChild(id: "error-test-child")
            
            // Test AppCategorizationRepository operations
            let categorization = AppCategorization(
                id: "error-test-cat",
                appBundleID: "com.error.test",
                category: .learning,
                childProfileID: "error-test-child",
                pointsPerHour: 10,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let _ = try await cloudKitService.createAppCategorization(categorization)
            let _ = try await cloudKitService.fetchAppCategorization(id: "error-test-cat")
            let _ = try await cloudKitService.fetchAppCategorizations(for: "error-test-child")
            let _ = try await cloudKitService.updateAppCategorization(categorization)
            try await cloudKitService.deleteAppCategorization(id: "error-test-cat")
            
            // Test UsageSessionRepository operations
            let startTime = Date()
            let endTime = startTime.addingTimeInterval(3600)
            let session = UsageSession(
                id: "error-test-session",
                childProfileID: "error-test-child",
                appBundleID: "com.error.test",
                category: .learning,
                startTime: startTime,
                endTime: endTime,
                duration: 3600,
                isValidated: true
            )
            
            let _ = try await cloudKitService.createSession(session)
            let _ = try await cloudKitService.fetchSession(id: "error-test-session")
            let _ = try await cloudKitService.fetchSessions(for: "error-test-child", dateRange: nil)
            let _ = try await cloudKitService.updateSession(session)
            try await cloudKitService.deleteSession(id: "error-test-session")
            
            // Test PointTransactionRepository operations
            let transaction = PointTransaction(
                id: "error-test-transaction",
                childProfileID: "error-test-child",
                points: 50,
                reason: "Error test",
                timestamp: Date()
            )
            
            let _ = try await cloudKitService.createTransaction(transaction)
            let _ = try await cloudKitService.fetchTransaction(id: "error-test-transaction")
            let _ = try await cloudKitService.fetchTransactions(for: "error-test-child", limit: 10)
            let dateRange = DateRange(start: Date().addingTimeInterval(-3600), end: Date())
            let _ = try await cloudKitService.fetchTransactions(for: "error-test-child", dateRange: dateRange)
            try await cloudKitService.deleteTransaction(id: "error-test-transaction")
            
            // Test PointToTimeRedemptionRepository operations
            let redemption = PointToTimeRedemption(
                id: "error-test-redemption",
                childProfileID: "error-test-child",
                appCategorizationID: "error-test-app-cat",
                pointsSpent: 100,
                timeGrantedMinutes: 10,
                conversionRate: 10.0,
                redeemedAt: Date(),
                expiresAt: Date().addingTimeInterval(3600),
                timeUsedMinutes: 0,
                status: .active
            )
            
            let _ = try await cloudKitService.createPointToTimeRedemption(redemption)
            let _ = try await cloudKitService.fetchPointToTimeRedemption(id: "error-test-redemption")
            let _ = try await cloudKitService.fetchPointToTimeRedemptions(for: "error-test-child")
            let _ = try await cloudKitService.fetchActivePointToTimeRedemptions(for: "error-test-child")
            let _ = try await cloudKitService.updatePointToTimeRedemption(redemption)
            try await cloudKitService.deletePointToTimeRedemption(id: "error-test-redemption")
            
            // If we get here, all operations completed without throwing
            XCTAssertTrue(true, "All operations should complete without throwing in mock implementation")
            
        } catch {
            XCTFail("CloudKitService operations should not throw in mock implementation: \(error)")
        }
    }
}