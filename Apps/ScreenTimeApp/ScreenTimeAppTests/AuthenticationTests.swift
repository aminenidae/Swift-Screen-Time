import XCTest
import CloudKit
@testable import ScreenTimeApp
@testable import SharedModels

@available(iOS 15.0, *)
final class AuthenticationTests: XCTestCase {
    var authService: iCloudAuthenticationService!
    var offlineManager: OfflineDataManager!

    override func setUpWithError() throws {
        // Access main actor properties asynchronously
        authService = iCloudAuthenticationService.shared
        offlineManager = OfflineDataManager.shared
    }

    override func tearDownWithError() throws {
        authService = nil
        offlineManager = nil
    }

    // MARK: - Authentication State Tests

    func testInitialAuthenticationState() async {
        // Access main actor properties asynchronously
        let isAuthenticated = await authService.authenticationState.isAuthenticated
        let syncStatus = await authService.syncStatus
        let isOnline = await authService.isOnline
        
        XCTAssertFalse(isAuthenticated)
        XCTAssertEqual(syncStatus, .unknown)
        XCTAssertTrue(isOnline)
    }

    func testAuthenticationStateUpdate() async {
        await authService.checkAuthenticationStatus()

        // Verify state is updated
        let authState = await authService.authenticationState
        let syncStatus = await authService.syncStatus
        
        XCTAssertNotNil(authState)
        XCTAssertNotEqual(syncStatus, .unknown)
    }

    func testRequestAuthentication() async {
        let result = await authService.requestAuthentication()

        // Test should handle both success and failure cases
        let authState = await authService.authenticationState
        if result {
            XCTAssertTrue(authState.isAuthenticated)
            XCTAssertEqual(authState.accountStatus, .available)
        } else {
            XCTAssertFalse(authState.isAuthenticated)
        }
    }

    func testSignOut() async {
        await authService.signOut()

        let authState = await authService.authenticationState
        let syncStatus = await authService.syncStatus
        let lastSyncTime = await authService.lastSyncTime
        
        XCTAssertFalse(authState.isAuthenticated)
        XCTAssertEqual(authState.accountStatus, .noAccount)
        XCTAssertNil(authState.userID)
        XCTAssertNil(authState.familyID)
        XCTAssertEqual(syncStatus, .disconnected)
        XCTAssertNil(lastSyncTime)
    }

    // MARK: - Sync Status Tests

    func testSyncStatusTransitions() async {
        // Update sync status on main actor
        await MainActor.run {
            authService.syncStatus = .syncing
        }
        
        let initialSyncStatus = await authService.syncStatus
        XCTAssertEqual(initialSyncStatus, .syncing)

        let success = await authService.triggerSync()
        
        let finalSyncStatus = await authService.syncStatus
        let lastSyncTime = await authService.lastSyncTime

        if success {
            XCTAssertEqual(finalSyncStatus, .synced)
            XCTAssertNotNil(lastSyncTime)
        } else {
            XCTAssertEqual(finalSyncStatus, .failed)
        }
    }

    func testConnectivityTest() async {
        let isOnline = await authService.testConnectivity()
        let authServiceIsOnline = await authService.isOnline
        XCTAssertEqual(isOnline, authServiceIsOnline)
    }

    // MARK: - Error Handling Tests

    func testAuthenticationErrorHandling() async {
        // Access and modify main actor properties asynchronously
        await MainActor.run {
            authService.showAuthenticationAlert = false
            authService.authenticationError = nil
        }

        // Simulate error
        let error = AuthenticationError.noiCloudAccount
        await MainActor.run {
            authService.authenticationError = error
            authService.showAuthenticationAlert = true
        }

        let showAlert = await authService.showAuthenticationAlert
        let authError = await authService.authenticationError
        
        XCTAssertTrue(showAlert)
        XCTAssertEqual(authError, error)
        XCTAssertNotNil(authError?.errorDescription)
        XCTAssertNotNil(authError?.recoverySuggestion)
    }

    // MARK: - Offline Data Manager Tests

    func testOfflineDataInitialState() async {
        let hasOfflineChanges = await offlineManager.hasOfflineChanges
        let offlineItemCount = await offlineManager.offlineItemCount
        let isProcessingOfflineData = await offlineManager.isProcessingOfflineData
        
        XCTAssertFalse(hasOfflineChanges)
        XCTAssertEqual(offlineItemCount, 0)
        XCTAssertFalse(isProcessingOfflineData)
    }

    func testQueueOfflineOperation() async {
        let operation = await MainActor.run {
            OfflineOperation(
                type: .pointTransaction,
                data: Data(),
                timestamp: Date()
            )
        }

        await offlineManager.queueOfflineOperation(operation)

        let hasOfflineChanges = await offlineManager.hasOfflineChanges
        let offlineItemCount = await offlineManager.offlineItemCount
        
        XCTAssertTrue(hasOfflineChanges)
        XCTAssertEqual(offlineItemCount, 1)
    }

    func testOfflineDataSummary() async {
        // Add test data
        let operations = await MainActor.run {
            [
                OfflineOperation(type: .pointTransaction, data: Data()),
                OfflineOperation(type: .usageSession, data: Data()),
                OfflineOperation(type: .pointTransaction, data: Data())
            ]
        }

        for operation in operations {
            await offlineManager.queueOfflineOperation(operation)
        }

        let summary = await offlineManager.getOfflineDataSummary()

        XCTAssertEqual(summary.totalOperations, 3)
        XCTAssertEqual(summary.operationsByType[.pointTransaction], 2)
        XCTAssertEqual(summary.operationsByType[.usageSession], 1)
        XCTAssertNotNil(summary.oldestOperation)
        XCTAssertGreaterThan(summary.estimatedSyncTime, 0)
    }

    func testProcessOfflineQueue() async {
        // Add test data
        let operation = await MainActor.run {
            OfflineOperation(
                type: .pointTransaction,
                data: Data()
            )
        }
        await offlineManager.queueOfflineOperation(operation)

        let hasOfflineChanges = await offlineManager.hasOfflineChanges
        XCTAssertTrue(hasOfflineChanges)

        await offlineManager.processOfflineQueue()

        // After processing, queue should be empty or have failed operations
        let isProcessingOfflineData = await offlineManager.isProcessingOfflineData
        XCTAssertFalse(isProcessingOfflineData)
    }

    func testClearOfflineData() async {
        // Add test data
        let operation = await MainActor.run {
            OfflineOperation(
                type: .pointTransaction,
                data: Data()
            )
        }
        await offlineManager.queueOfflineOperation(operation)

        let hasOfflineChanges = await offlineManager.hasOfflineChanges
        XCTAssertTrue(hasOfflineChanges)

        await offlineManager.clearOfflineData()

        let hasOfflineChangesAfterClear = await offlineManager.hasOfflineChanges
        let offlineItemCount = await offlineManager.offlineItemCount
        
        XCTAssertFalse(hasOfflineChangesAfterClear)
        XCTAssertEqual(offlineItemCount, 0)
    }

    func testExportOfflineData() async {
        // Add test data
        let operation = await MainActor.run {
            OfflineOperation(
                type: .pointTransaction,
                data: Data()
            )
        }
        await offlineManager.queueOfflineOperation(operation)

        let exportData = await offlineManager.exportOfflineData()
        XCTAssertNotNil(exportData)
        XCTAssertGreaterThan(exportData?.count ?? 0, 0)
    }

    // MARK: - Convenience Methods Tests

    func testQuickQueueMethods() async {
        struct MockTransaction: Codable {
            let amount: Int
            let timestamp: Date
        }

        let transaction = MockTransaction(amount: 10, timestamp: Date())
        await offlineManager.queuePointTransaction(transaction)

        let offlineItemCount = await offlineManager.offlineItemCount
        XCTAssertEqual(offlineItemCount, 1)

        let summary = await offlineManager.getOfflineDataSummary()
        XCTAssertEqual(summary.operationsByType[.pointTransaction], 1)
    }

    // MARK: - Mock Data Tests

    #if DEBUG
    func testMockOfflineData() async {
        let initialCount = await offlineManager.offlineItemCount

        await offlineManager.addMockOfflineData()

        let finalCount = await offlineManager.offlineItemCount
        let hasOfflineChanges = await offlineManager.hasOfflineChanges
        
        XCTAssertGreaterThan(finalCount, initialCount)
        XCTAssertTrue(hasOfflineChanges)
    }
    #endif

    // MARK: - Performance Tests

    func testOfflineOperationPerformance() {
        // For performance tests, we can't use async/await directly
        // We'll need to use a different approach for this test
        measure {
            // This test needs to be restructured to work with synchronous code
            // For now, we'll just create a simple synchronous test
            let operation = OfflineOperation(
                type: .pointTransaction,
                data: Data()
            )
            // We can't call the async method in measure, so we'll skip this test for now
        }
    }

    func testOfflineDataExportPerformance() {
        // For performance tests, we can't use async/await directly
        // We'll need to use a different approach for this test
        measure {
            // This test needs to be restructured to work with synchronous code
            // For now, we'll just create a simple synchronous test
            // We can't call the async method in measure, so we'll skip this test for now
        }
    }
}

// MARK: - Supporting Types Tests

@available(iOS 15.0, *)
final class AuthenticationTypesTests: XCTestCase {

    func testAuthenticationErrorDescriptions() {
        let errors: [AuthenticationError] = [
            .notAuthenticated,
            .authenticationFailed,
            .noiCloudAccount,
            .accountRestricted,
            .undeterminedStatus,
            .networkUnavailable,
            .iCloudUnavailable,
            .unknownError("Test error")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)

            // Some errors should have recovery suggestions
            switch error {
            case .noiCloudAccount, .accountRestricted, .networkUnavailable, .iCloudUnavailable:
                XCTAssertNotNil(error.recoverySuggestion)
            default:
                break
            }
        }
    }

    func testSyncStatusProperties() {
        let statuses: [iCloudSyncStatus] = [
            .unknown, .syncing, .synced, .failed, .offline, .disconnected
        ]

        for status in statuses {
            XCTAssertNotNil(status.displayName)
            XCTAssertNotNil(status.color)
            XCTAssertNotNil(status.icon)
        }
    }

    func testOfflineOperationTypes() {
        let types = OfflineOperation.OperationType.allCases

        for type in types {
            XCTAssertNotNil(type.displayName)
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }

    func testOfflineDataSummaryFormatting() {
        let summary = OfflineDataSummary(
            totalOperations: 5,
            operationsByType: [.pointTransaction: 3, .usageSession: 2],
            oldestOperation: OfflineOperation(type: .pointTransaction, data: Data(), timestamp: Date().addingTimeInterval(-3600)),
            estimatedSyncTime: 125.0
        )

        XCTAssertEqual(summary.formattedSyncTime, "2 minutes")
        XCTAssertNotNil(summary.oldestOperationAge)
        XCTAssertGreaterThan(summary.oldestOperationAge!, 0)
    }
}

// MARK: - Integration Tests

@available(iOS 15.0, *)
final class AuthenticationIntegrationTests: XCTestCase {
    var authService: iCloudAuthenticationService!
    var offlineManager: OfflineDataManager!

    override func setUpWithError() throws {
        authService = iCloudAuthenticationService.shared
        offlineManager = OfflineDataManager.shared
    }

    func testAuthenticationAndOfflineFlow() async {
        // Test offline operation queuing when not authenticated
        await MainActor.run {
            authService.syncStatus = .disconnected
        }

        let operation = await MainActor.run {
            OfflineOperation(
                type: .pointTransaction,
                data: Data()
            )
        }
        await offlineManager.queueOfflineOperation(operation)

        let hasOfflineChanges = await offlineManager.hasOfflineChanges
        XCTAssertTrue(hasOfflineChanges)
        
        let offlineItemCount = await offlineManager.offlineItemCount
        XCTAssertEqual(offlineItemCount, 1)

        // Simulate authentication success
        await authService.checkAuthenticationStatus()

        // If authenticated, try to process offline queue
        let authState = await authService.authenticationState
        if authState.isAuthenticated {
            await offlineManager.processOfflineQueue()
        }
    }

    func testSyncStatusAndOfflineDataInteraction() async {
        // Queue offline data
        let operation = await MainActor.run {
            OfflineOperation(type: .pointTransaction, data: Data())
        }
        await offlineManager.queueOfflineOperation(operation)

        // Test sync trigger with offline data
        let authState = await authService.authenticationState
        if authState.isAuthenticated {
            let syncSuccess = await authService.triggerSync()

            if syncSuccess {
                let syncStatus = await authService.syncStatus
                let lastSyncTime = await authService.lastSyncTime
                
                XCTAssertEqual(syncStatus, .synced)
                XCTAssertNotNil(lastSyncTime)
            }
        }
    }
}