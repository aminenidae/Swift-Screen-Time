import XCTest
import CloudKit
@testable import ScreenTimeApp

@available(iOS 15.0, *)
final class AuthenticationTests: XCTestCase {
    var authService: iCloudAuthenticationService!
    var offlineManager: OfflineDataManager!

    override func setUpWithError() throws {
        authService = iCloudAuthenticationService.shared
        offlineManager = OfflineDataManager.shared
    }

    override func tearDownWithError() throws {
        authService = nil
        offlineManager = nil
    }

    // MARK: - Authentication State Tests

    func testInitialAuthenticationState() {
        XCTAssertFalse(authService.authenticationState.isAuthenticated)
        XCTAssertEqual(authService.syncStatus, .unknown)
        XCTAssertTrue(authService.isOnline)
    }

    func testAuthenticationStateUpdate() async {
        await authService.checkAuthenticationStatus()

        // Verify state is updated
        XCTAssertNotNil(authService.authenticationState)
        XCTAssertNotEqual(authService.syncStatus, .unknown)
    }

    func testRequestAuthentication() async {
        let result = await authService.requestAuthentication()

        // Test should handle both success and failure cases
        if result {
            XCTAssertTrue(authService.authenticationState.isAuthenticated)
            XCTAssertEqual(authService.authenticationState.accountStatus, .available)
        } else {
            XCTAssertFalse(authService.authenticationState.isAuthenticated)
        }
    }

    func testSignOut() async {
        await authService.signOut()

        XCTAssertFalse(authService.authenticationState.isAuthenticated)
        XCTAssertEqual(authService.authenticationState.accountStatus, .noAccount)
        XCTAssertNil(authService.authenticationState.userID)
        XCTAssertNil(authService.authenticationState.familyID)
        XCTAssertEqual(authService.syncStatus, .disconnected)
        XCTAssertNil(authService.lastSyncTime)
    }

    // MARK: - Sync Status Tests

    func testSyncStatusTransitions() async {
        authService.syncStatus = .syncing
        XCTAssertEqual(authService.syncStatus, .syncing)

        let success = await authService.triggerSync()

        if success {
            XCTAssertEqual(authService.syncStatus, .synced)
            XCTAssertNotNil(authService.lastSyncTime)
        } else {
            XCTAssertEqual(authService.syncStatus, .failed)
        }
    }

    func testConnectivityTest() async {
        let isOnline = await authService.testConnectivity()
        XCTAssertEqual(isOnline, authService.isOnline)
    }

    // MARK: - Error Handling Tests

    func testAuthenticationErrorHandling() {
        authService.showAuthenticationError = false
        authService.authenticationError = nil

        // Simulate error
        let error = AuthenticationError.noiCloudAccount
        authService.authenticationError = error
        authService.showAuthenticationAlert = true

        XCTAssertTrue(authService.showAuthenticationAlert)
        XCTAssertEqual(authService.authenticationError, error)
        XCTAssertNotNil(authService.authenticationError?.errorDescription)
        XCTAssertNotNil(authService.authenticationError?.recoverySuggestion)
    }

    // MARK: - Offline Data Manager Tests

    func testOfflineDataInitialState() {
        XCTAssertFalse(offlineManager.hasOfflineChanges)
        XCTAssertEqual(offlineManager.offlineItemCount, 0)
        XCTAssertFalse(offlineManager.isProcessingOfflineData)
    }

    func testQueueOfflineOperation() {
        let operation = OfflineOperation(
            type: .pointTransaction,
            data: Data(),
            timestamp: Date()
        )

        offlineManager.queueOfflineOperation(operation)

        XCTAssertTrue(offlineManager.hasOfflineChanges)
        XCTAssertEqual(offlineManager.offlineItemCount, 1)
    }

    func testOfflineDataSummary() {
        // Add test data
        let operations = [
            OfflineOperation(type: .pointTransaction, data: Data()),
            OfflineOperation(type: .usageSession, data: Data()),
            OfflineOperation(type: .pointTransaction, data: Data())
        ]

        for operation in operations {
            offlineManager.queueOfflineOperation(operation)
        }

        let summary = offlineManager.getOfflineDataSummary()

        XCTAssertEqual(summary.totalOperations, 3)
        XCTAssertEqual(summary.operationsByType[.pointTransaction], 2)
        XCTAssertEqual(summary.operationsByType[.usageSession], 1)
        XCTAssertNotNil(summary.oldestOperation)
        XCTAssertGreaterThan(summary.estimatedSyncTime, 0)
    }

    func testProcessOfflineQueue() async {
        // Add test data
        let operation = OfflineOperation(
            type: .pointTransaction,
            data: Data()
        )
        offlineManager.queueOfflineOperation(operation)

        XCTAssertTrue(offlineManager.hasOfflineChanges)

        await offlineManager.processOfflineQueue()

        // After processing, queue should be empty or have failed operations
        XCTAssertFalse(offlineManager.isProcessingOfflineData)
    }

    func testClearOfflineData() {
        // Add test data
        let operation = OfflineOperation(
            type: .pointTransaction,
            data: Data()
        )
        offlineManager.queueOfflineOperation(operation)

        XCTAssertTrue(offlineManager.hasOfflineChanges)

        offlineManager.clearOfflineData()

        XCTAssertFalse(offlineManager.hasOfflineChanges)
        XCTAssertEqual(offlineManager.offlineItemCount, 0)
    }

    func testExportOfflineData() {
        // Add test data
        let operation = OfflineOperation(
            type: .pointTransaction,
            data: Data()
        )
        offlineManager.queueOfflineOperation(operation)

        let exportData = offlineManager.exportOfflineData()
        XCTAssertNotNil(exportData)
        XCTAssertGreaterThan(exportData?.count ?? 0, 0)
    }

    // MARK: - Convenience Methods Tests

    func testQuickQueueMethods() {
        struct MockTransaction: Codable {
            let amount: Int
            let timestamp: Date
        }

        let transaction = MockTransaction(amount: 10, timestamp: Date())
        offlineManager.queuePointTransaction(transaction)

        XCTAssertEqual(offlineManager.offlineItemCount, 1)

        let summary = offlineManager.getOfflineDataSummary()
        XCTAssertEqual(summary.operationsByType[.pointTransaction], 1)
    }

    // MARK: - Mock Data Tests

    #if DEBUG
    func testMockOfflineData() {
        let initialCount = offlineManager.offlineItemCount

        offlineManager.addMockOfflineData()

        XCTAssertGreaterThan(offlineManager.offlineItemCount, initialCount)
        XCTAssertTrue(offlineManager.hasOfflineChanges)
    }
    #endif

    // MARK: - Performance Tests

    func testOfflineOperationPerformance() {
        measure {
            for i in 0..<100 {
                let operation = OfflineOperation(
                    type: .pointTransaction,
                    data: Data()
                )
                offlineManager.queueOfflineOperation(operation)
            }
        }
    }

    func testOfflineDataExportPerformance() {
        // Add significant test data
        for i in 0..<1000 {
            let operation = OfflineOperation(
                type: .pointTransaction,
                data: Data()
            )
            offlineManager.queueOfflineOperation(operation)
        }

        measure {
            let _ = offlineManager.exportOfflineData()
        }

        // Clean up
        offlineManager.clearOfflineData()
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
        authService.syncStatus = .disconnected

        let operation = OfflineOperation(
            type: .pointTransaction,
            data: Data()
        )
        offlineManager.queueOfflineOperation(operation)

        XCTAssertTrue(offlineManager.hasOfflineChanges)
        XCTAssertEqual(offlineManager.offlineItemCount, 1)

        // Simulate authentication success
        await authService.checkAuthenticationStatus()

        // If authenticated, try to process offline queue
        if authService.authenticationState.isAuthenticated {
            await offlineManager.processOfflineQueue()
        }
    }

    func testSyncStatusAndOfflineDataInteraction() async {
        // Queue offline data
        let operation = OfflineOperation(type: .pointTransaction, data: Data())
        offlineManager.queueOfflineOperation(operation)

        // Test sync trigger with offline data
        if authService.authenticationState.isAuthenticated {
            let syncSuccess = await authService.triggerSync()

            if syncSuccess {
                XCTAssertEqual(authService.syncStatus, .synced)
                XCTAssertNotNil(authService.lastSyncTime)
            }
        }
    }
}