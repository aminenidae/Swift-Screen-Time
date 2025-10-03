import Foundation
import CoreData
import SwiftUI
import Combine
import OSLog
import SharedModels

/// Manages offline data storage and synchronization when iCloud is unavailable
@available(iOS 15.0, *)
public class OfflineDataManager: ObservableObject {
    public static let shared = OfflineDataManager()

    @Published public var hasOfflineChanges: Bool = false
    @Published public var offlineItemCount: Int = 0
    @Published public var isProcessingOfflineData: Bool = false

    private let logger = Logger(subsystem: "com.screentime.rewards", category: "offline-data")
    private let userDefaults = UserDefaults.standard

    // Queue for offline operations
    private var offlineQueue: [OfflineOperation] = []
    private let queueKey = "offlineOperationQueue"

    // Core Data context for offline storage
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "OfflineDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                self.logger.error("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {
        loadOfflineQueue()
        updateOfflineStatus()
    }

    // MARK: - Public Methods

    /// Add data to offline queue when CloudKit is unavailable
    public func queueOfflineOperation(_ operation: OfflineOperation) {
        logger.info("Queuing offline operation: \(operation.type.rawValue)")

        offlineQueue.append(operation)
        saveOfflineQueue()
        updateOfflineStatus()

        // Try to save to local Core Data
        saveOperationLocally(operation)
    }

    /// Process all queued offline operations when connectivity returns
    public func processOfflineQueue() async {
        guard !offlineQueue.isEmpty else {
            logger.info("No offline operations to process")
            return
        }

        logger.info("Processing \(self.offlineQueue.count) offline operations")
        isProcessingOfflineData = true

        var processedOperations: [OfflineOperation] = []
        var failedOperations: [OfflineOperation] = []

        for operation in offlineQueue {
            do {
                let success = try await processOperation(operation)
                if success {
                    processedOperations.append(operation)
                    logger.info("Successfully processed offline operation: \(operation.id)")
                } else {
                    failedOperations.append(operation)
                    logger.warning("Failed to process offline operation: \(operation.id)")
                }
            } catch {
                logger.error("Error processing offline operation \(operation.id): \(error.localizedDescription)")
                failedOperations.append(operation)
            }
        }

        // Remove successfully processed operations
        offlineQueue = failedOperations
        saveOfflineQueue()
        updateOfflineStatus()

        isProcessingOfflineData = false

        logger.info("Offline processing complete. \(processedOperations.count) successful, \(failedOperations.count) failed")
    }

    /// Clear all offline data (use with caution)
    public func clearOfflineData() {
        logger.warning("Clearing all offline data")

        offlineQueue.removeAll()
        saveOfflineQueue()
        clearLocalStorage()
        updateOfflineStatus()
    }

    /// Get offline data summary
    public func getOfflineDataSummary() -> OfflineDataSummary {
        let operationCounts = Dictionary(grouping: offlineQueue, by: { $0.type })
            .mapValues { $0.count }

        return OfflineDataSummary(
            totalOperations: offlineQueue.count,
            operationsByType: operationCounts,
            oldestOperation: offlineQueue.min(by: { $0.timestamp < $1.timestamp }),
            estimatedSyncTime: estimateSyncTime()
        )
    }

    /// Export offline data for debugging
    public func exportOfflineData() -> Data? {
        do {
            let exportData = OfflineDataExport(
                operations: offlineQueue,
                exportDate: Date(),
                deviceInfo: getDeviceInfo()
            )
            return try JSONEncoder().encode(exportData)
        } catch {
            logger.error("Failed to export offline data: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private Methods

    private func loadOfflineQueue() {
        if let data = userDefaults.data(forKey: queueKey),
           let queue = try? JSONDecoder().decode([OfflineOperation].self, from: data) {
            offlineQueue = queue
            logger.info("Loaded \(queue.count) offline operations from storage")
        }
    }

    private func saveOfflineQueue() {
        do {
            let data = try JSONEncoder().encode(offlineQueue)
            userDefaults.set(data, forKey: queueKey)
            logger.debug("Saved offline queue with \(self.offlineQueue.count) operations")
        } catch {
            logger.error("Failed to save offline queue: \(error.localizedDescription)")
        }
    }

    private func updateOfflineStatus() {
        DispatchQueue.main.async {
            self.hasOfflineChanges = !self.offlineQueue.isEmpty
            self.offlineItemCount = self.offlineQueue.count
        }
    }

    private func saveOperationLocally(_ operation: OfflineOperation) {
        // Save to Core Data for offline access
        // This would be implemented based on your Core Data model
        logger.debug("Saving operation locally: \(operation.id)")

        do {
            try context.save()
        } catch {
            logger.error("Failed to save operation locally: \(error.localizedDescription)")
        }
    }

    private func processOperation(_ operation: OfflineOperation) async throws -> Bool {
        // Process the operation based on its type
        switch operation.type {
        case .pointTransaction:
            return try await processPointTransaction(operation)
        case .usageSession:
            return try await processUsageSession(operation)
        case .rewardRedemption:
            return try await processRewardRedemption(operation)
        case .profileUpdate:
            return try await processProfileUpdate(operation)
        case .settingsChange:
            return try await processSettingsChange(operation)
        }
    }

    private func processPointTransaction(_ operation: OfflineOperation) async throws -> Bool {
        // Implement CloudKit sync for point transactions
        logger.info("Processing point transaction: \(operation.id)")

        // Mock implementation - replace with actual CloudKit sync
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        return true
    }

    private func processUsageSession(_ operation: OfflineOperation) async throws -> Bool {
        // Implement CloudKit sync for usage sessions
        logger.info("Processing usage session: \(operation.id)")

        // Mock implementation - replace with actual CloudKit sync
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        return true
    }

    private func processRewardRedemption(_ operation: OfflineOperation) async throws -> Bool {
        // Implement CloudKit sync for reward redemptions
        logger.info("Processing reward redemption: \(operation.id)")

        // Mock implementation - replace with actual CloudKit sync
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        return true
    }

    private func processProfileUpdate(_ operation: OfflineOperation) async throws -> Bool {
        // Implement CloudKit sync for profile updates
        logger.info("Processing profile update: \(operation.id)")

        // Mock implementation - replace with actual CloudKit sync
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        return true
    }

    private func processSettingsChange(_ operation: OfflineOperation) async throws -> Bool {
        // Implement CloudKit sync for settings changes
        logger.info("Processing settings change: \(operation.id)")

        // Mock implementation - replace with actual CloudKit sync
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        return true
    }

    private func clearLocalStorage() {
        // Clear Core Data storage
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "OfflineOperation")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
            logger.info("Cleared local offline storage")
        } catch {
            logger.error("Failed to clear local storage: \(error.localizedDescription)")
        }
    }

    private func estimateSyncTime() -> TimeInterval {
        // Estimate sync time based on operation count and types
        let baseTimePerOperation: TimeInterval = 0.5
        return Double(offlineQueue.count) * baseTimePerOperation
    }

    private func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
    }
}

// MARK: - Supporting Types

public struct OfflineOperation: Codable, Identifiable {
    public let id: UUID
    public let type: OperationType
    public let data: Data
    public let timestamp: Date
    public let retryCount: Int

    public init(id: UUID = UUID(), type: OperationType, data: Data, timestamp: Date = Date(), retryCount: Int = 0) {
        self.id = id
        self.type = type
        self.data = data
        self.timestamp = timestamp
        self.retryCount = retryCount
    }

    public enum OperationType: String, Codable, CaseIterable {
        case pointTransaction = "point_transaction"
        case usageSession = "usage_session"
        case rewardRedemption = "reward_redemption"
        case profileUpdate = "profile_update"
        case settingsChange = "settings_change"

        public var displayName: String {
            switch self {
            case .pointTransaction: return "Point Transaction"
            case .usageSession: return "Usage Session"
            case .rewardRedemption: return "Reward Redemption"
            case .profileUpdate: return "Profile Update"
            case .settingsChange: return "Settings Change"
            }
        }
    }
}

public struct OfflineDataSummary {
    public let totalOperations: Int
    public let operationsByType: [OfflineOperation.OperationType: Int]
    public let oldestOperation: OfflineOperation?
    public let estimatedSyncTime: TimeInterval

    public var oldestOperationAge: TimeInterval? {
        guard let oldest = oldestOperation else { return nil }
        return Date().timeIntervalSince(oldest.timestamp)
    }

    public var formattedSyncTime: String {
        if estimatedSyncTime < 60 {
            return "\(Int(estimatedSyncTime)) seconds"
        } else {
            let minutes = Int(estimatedSyncTime / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

private struct OfflineDataExport: Codable {
    let operations: [OfflineOperation]
    let exportDate: Date
    let deviceInfo: DeviceInfo
}

private struct DeviceInfo: Codable {
    let model: String
    let systemVersion: String
    let appVersion: String
}

// MARK: - Convenience Extensions

extension OfflineDataManager {
    /// Quick method to queue a point transaction
    public func queuePointTransaction<T: Codable>(_ transaction: T) {
        if let data = try? JSONEncoder().encode(transaction) {
            let operation = OfflineOperation(type: .pointTransaction, data: data)
            queueOfflineOperation(operation)
        }
    }

    /// Quick method to queue a usage session
    public func queueUsageSession<T: Codable>(_ session: T) {
        if let data = try? JSONEncoder().encode(session) {
            let operation = OfflineOperation(type: .usageSession, data: data)
            queueOfflineOperation(operation)
        }
    }

    /// Quick method to queue a reward redemption
    public func queueRewardRedemption<T: Codable>(_ redemption: T) {
        if let data = try? JSONEncoder().encode(redemption) {
            let operation = OfflineOperation(type: .rewardRedemption, data: data)
            queueOfflineOperation(operation)
        }
    }
}

#if DEBUG
// MARK: - Mock Data for Testing
extension OfflineDataManager {
    public func addMockOfflineData() {
        let mockOperations = [
            OfflineOperation(type: .pointTransaction, data: Data(), timestamp: Date().addingTimeInterval(-3600)),
            OfflineOperation(type: .usageSession, data: Data(), timestamp: Date().addingTimeInterval(-1800)),
            OfflineOperation(type: .rewardRedemption, data: Data(), timestamp: Date().addingTimeInterval(-900))
        ]

        for operation in mockOperations {
            queueOfflineOperation(operation)
        }
    }
}
#endif