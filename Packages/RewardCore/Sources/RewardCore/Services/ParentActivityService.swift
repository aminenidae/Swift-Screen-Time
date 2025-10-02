import Foundation
import SharedModels
import CloudKitService
import CloudKit
import Combine

@available(iOS 15.0, macOS 12.0, *)
public class ParentActivityService: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var activities: [ParentActivity] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?

    // MARK: - Private Properties

    private let repository: ParentActivityRepository
    private let container: CKContainer
    private let database: CKDatabase
    private let maxActivityHistory = 30 // Days
    private var cancellables = Set<AnyCancellable>()
    private var activitySubscriptions: [UUID: CKSubscription] = [:]
    private let newActivitySubject = PassthroughSubject<ParentActivity, Error>()

    // MARK: - Publishers

    public var activitiesPublisher: AnyPublisher<[ParentActivity], Error> {
        $activities
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    public var newActivityPublisher: AnyPublisher<ParentActivity, Error> {
        newActivitySubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    public init(repository: ParentActivityRepository? = nil, container: CKContainer = CKContainer.default()) {
        self.repository = repository ?? CloudKitParentActivityRepository()
        self.container = container
        self.database = container.privateCloudDatabase
    }

    // MARK: - Public Methods

    /// Loads activities for a specific family
    public func loadActivities(for familyID: UUID, limit: Int? = nil) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let fetchedActivities = try await repository.fetchActivities(for: familyID, limit: limit)

            await MainActor.run {
                self.activities = fetchedActivities
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }

    /// Loads recent activities (last 30 days)
    public func loadRecentActivities(for familyID: UUID) async {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -maxActivityHistory, to: Date()) ?? Date()

        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let fetchedActivities = try await repository.fetchActivities(for: familyID, since: thirtyDaysAgo)

            await MainActor.run {
                self.activities = fetchedActivities
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }

    /// Creates a new activity record
    public func logActivity(
        familyID: UUID,
        triggeringUserID: String,
        activityType: ParentActivityType,
        targetEntity: String,
        targetEntityID: UUID,
        changes: [String: String],
        deviceID: String? = nil
    ) async throws -> ParentActivity {

        let activity = ParentActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: activityType,
            targetEntity: targetEntity,
            targetEntityID: targetEntityID,
            changes: CodableDictionary(changes),
            deviceID: deviceID
        )

        let savedActivity = try await repository.createActivity(activity)

        // Add to local activities list and sort
        await MainActor.run {
            activities.insert(savedActivity, at: 0) // Insert at beginning (newest first)
            activities.sort { $0.timestamp > $1.timestamp }
        }

        return savedActivity
    }

    /// Logs app categorization changes
    public func logAppCategorizationChange(
        familyID: UUID,
        triggeringUserID: String,
        activityType: ParentActivityType,
        appName: String,
        appBundleID: String,
        childName: String?,
        oldCategory: String? = nil,
        newCategory: String? = nil
    ) async throws {

        var changes: [String: String] = [
            "appName": appName,
            "appBundleID": appBundleID
        ]

        if let childName = childName {
            changes["childName"] = childName
        }

        if let oldCategory = oldCategory {
            changes["oldCategory"] = oldCategory
        }

        if let newCategory = newCategory {
            changes["newCategory"] = newCategory
            changes["category"] = newCategory
        }

        _ = try await logActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: activityType,
            targetEntity: "AppCategorization",
            targetEntityID: UUID(), // Would be actual categorization ID
            changes: changes
        )
    }

    /// Logs point adjustments
    public func logPointAdjustment(
        familyID: UUID,
        triggeringUserID: String,
        childName: String,
        childID: UUID,
        pointsChange: Int,
        reason: String
    ) async throws {

        let changes: [String: String] = [
            "childName": childName,
            "pointsChange": pointsChange >= 0 ? "+\(pointsChange)" : "\(pointsChange)",
            "reason": reason
        ]

        _ = try await logActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: .pointsAdjusted,
            targetEntity: "ChildProfile",
            targetEntityID: childID,
            changes: changes
        )
    }

    /// Logs reward redemptions
    public func logRewardRedemption(
        familyID: UUID,
        triggeringUserID: String,
        childName: String,
        childID: UUID,
        rewardName: String,
        rewardID: UUID,
        pointsSpent: Int
    ) async throws {

        let changes: [String: String] = [
            "childName": childName,
            "rewardName": rewardName,
            "pointsSpent": "\(pointsSpent)"
        ]

        _ = try await logActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: .rewardRedeemed,
            targetEntity: "Reward",
            targetEntityID: rewardID,
            changes: changes
        )
    }

    /// Logs child profile modifications
    public func logChildProfileModification(
        familyID: UUID,
        triggeringUserID: String,
        childName: String,
        childID: UUID,
        modifications: String
    ) async throws {

        let changes: [String: String] = [
            "childName": childName,
            "modifications": modifications
        ]

        _ = try await logActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: .childProfileModified,
            targetEntity: "ChildProfile",
            targetEntityID: childID,
            changes: changes
        )
    }

    /// Logs settings updates
    public func logSettingsUpdate(
        familyID: UUID,
        triggeringUserID: String,
        settingsType: String,
        settingsID: UUID? = nil
    ) async throws {

        let changes: [String: String] = [
            "settingsType": settingsType
        ]

        _ = try await logActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: .settingsUpdated,
            targetEntity: "Settings",
            targetEntityID: settingsID ?? UUID(),
            changes: changes
        )
    }

    /// Logs new child additions
    public func logChildAdded(
        familyID: UUID,
        triggeringUserID: String,
        childName: String,
        childID: UUID
    ) async throws {

        let changes: [String: String] = [
            "childName": childName
        ]

        _ = try await logActivity(
            familyID: familyID,
            triggeringUserID: triggeringUserID,
            activityType: .childAdded,
            targetEntity: "ChildProfile",
            targetEntityID: childID,
            changes: changes
        )
    }

    /// Refreshes activities from the repository
    public func refreshActivities(for familyID: UUID) async {
        await loadRecentActivities(for: familyID)
    }

    /// Cleans up old activities (beyond retention period)
    public func cleanupOldActivities() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxActivityHistory, to: Date()) ?? Date()

        do {
            try await repository.deleteOldActivities(olderThan: cutoffDate)

            // Remove from local cache as well
            await MainActor.run {
                activities.removeAll { $0.timestamp < cutoffDate }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }

    /// Gets activities filtered by type
    public func getActivities(ofType activityType: ParentActivityType) -> [ParentActivity] {
        return activities.filter { $0.activityType == activityType }
    }

    /// Gets activities for a specific date range
    public func getActivities(in dateRange: DateRange) -> [ParentActivity] {
        return activities.filter { activity in
            activity.timestamp >= dateRange.start && activity.timestamp <= dateRange.end
        }
    }

    // MARK: - Real-Time Subscriptions

    /// Creates a CloudKit subscription for activity updates
    public func createActivitySubscription(for familyID: UUID, excluding userID: String) async throws {
        let predicate = NSPredicate(
            format: "familyID == %@ AND triggeringUserID != %@",
            familyID.uuidString,
            userID
        )

        let subscription = CKQuerySubscription(
            recordType: "ParentActivity",
            predicate: predicate,
            subscriptionID: "parent-activity-\(familyID)-\(userID)",
            options: [.firesOnRecordCreation]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push for background processing
        notificationInfo.title = "Family Activity Update"
        notificationInfo.subtitle = "New activity from co-parent"
        subscription.notificationInfo = notificationInfo

        _ = try await database.save(subscription)
        activitySubscriptions[familyID] = subscription
        print("Activity subscription created for family: \(familyID)")
    }

    /// Removes the CloudKit subscription for activity updates
    public func removeActivitySubscription(for familyID: UUID, userID: String) async throws {
        let subscriptionID = "parent-activity-\(familyID)-\(userID)"

        do {
            try await database.deleteSubscription(withID: subscriptionID)
            activitySubscriptions.removeValue(forKey: familyID)
            print("Activity subscription removed for family: \(familyID)")
        } catch {
            print("Failed to remove activity subscription: \(error)")
            throw error
        }
    }

    /// Handles incoming CloudKit push notifications for new activities
    public func handleActivityNotification(_ notification: [AnyHashable: Any]) async {
        guard let recordName = notification["ck"] as? [String: Any],
              let recordID = recordName["rid"] as? String,
              let activityID = UUID(uuidString: recordID) else {
            return
        }

        do {
            // Fetch the new activity
            if let newActivity = try await repository.fetchActivity(id: activityID) {
                await MainActor.run {
                    // Insert at the beginning (newest first)
                    activities.insert(newActivity, at: 0)
                    activities.sort { $0.timestamp > $1.timestamp }
                }

                // Emit to the new activity publisher
                newActivitySubject.send(newActivity)
            }
        } catch {
            newActivitySubject.send(completion: .failure(error))
        }
    }

    /// Handles background app refresh for activity updates
    public func handleBackgroundFetch(for familyID: UUID) async throws -> [ParentActivity] {
        let lastActivity = activities.first
        let sinceDate = lastActivity?.timestamp ?? Date().addingTimeInterval(-3600) // Last hour as fallback

        let newActivities = try await repository.fetchActivities(for: familyID, since: sinceDate)

        // Filter out activities we already have
        let filteredActivities = newActivities.filter { newActivity in
            !activities.contains { $0.id == newActivity.id }
        }

        if !filteredActivities.isEmpty {
            await MainActor.run {
                activities.insert(contentsOf: filteredActivities, at: 0)
                activities.sort { $0.timestamp > $1.timestamp }
            }

            // Emit each new activity
            for activity in filteredActivities {
                newActivitySubject.send(activity)
            }
        }

        return filteredActivities
    }

    /// Sets up real-time updates for a family
    public func startRealTimeUpdates(for familyID: UUID, userID: String) async throws {
        do {
            try await createActivitySubscription(for: familyID, excluding: userID)
        } catch {
            print("Failed to create activity subscription: \(error)")
            throw error
        }
    }

    /// Stops real-time updates for a family
    public func stopRealTimeUpdates(for familyID: UUID, userID: String) async throws {
        try await removeActivitySubscription(for: familyID, userID: userID)
    }
}

// MARK: - Convenience Extensions

@available(iOS 15.0, macOS 12.0, *)
public extension ParentActivityService {
    /// Creates mock data for testing and previews
    static func createMockService() -> ParentActivityService {
        let service = ParentActivityService()
        // Mock data would be loaded here for testing
        return service
    }

    #if DEBUG
    /// Sets activities directly for testing purposes
    func setActivitiesForTesting(_ testActivities: [ParentActivity]) {
        self.activities = testActivities
    }

    /// Sends activity through newActivitySubject for testing
    func sendActivityForTesting(_ activity: ParentActivity) {
        newActivitySubject.send(activity)
    }
    #endif
}