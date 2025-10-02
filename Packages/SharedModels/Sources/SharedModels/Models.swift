import Foundation

// MARK: - Core Data Models

public struct DateRange: Codable, Equatable {
    public let start: Date
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

// MARK: - DateRange Extensions

public extension DateRange {
    static func last30Days() -> DateRange {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -30, to: end)!
        return DateRange(start: start, end: end)
    }
    
    static func singleDay(_ date: Date) -> DateRange {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return DateRange(start: start, end: end)
    }
    
    static func today() -> DateRange {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return DateRange(start: start, end: end)
    }
}

public struct Family: Codable, Identifiable {
    public let id: String
    public var name: String
    public let createdAt: Date
    public let ownerUserID: String
    public var sharedWithUserIDs: [String]
    public var childProfileIDs: [String]
    // COPPA compliance properties
    public var parentalConsentGiven: Bool
    public var parentalConsentDate: Date?
    public var parentalConsentMethod: String?
    // Trial and subscription metadata
    public var subscriptionMetadata: SubscriptionMetadata?
    // Real-time subscription status synchronized from StoreKit
    public var subscriptionStatus: SubscriptionStatus?
    // Permission roles for family members
    public var userRoles: [String: PermissionRole]

    public init(id: String, name: String, createdAt: Date, ownerUserID: String, sharedWithUserIDs: [String], childProfileIDs: [String], parentalConsentGiven: Bool = false, parentalConsentDate: Date? = nil, parentalConsentMethod: String? = nil, subscriptionMetadata: SubscriptionMetadata? = nil, subscriptionStatus: SubscriptionStatus? = nil, userRoles: [String: PermissionRole] = [:]) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.ownerUserID = ownerUserID
        self.sharedWithUserIDs = sharedWithUserIDs
        self.childProfileIDs = childProfileIDs
        self.parentalConsentGiven = parentalConsentGiven
        self.parentalConsentDate = parentalConsentDate
        self.parentalConsentMethod = parentalConsentMethod
        self.subscriptionMetadata = subscriptionMetadata
        self.subscriptionStatus = subscriptionStatus
        self.userRoles = userRoles
    }
}

// MARK: - Subscription Status Enum

public enum SubscriptionStatus: String, Codable, CaseIterable {
    case active = "active"           // Paid and current
    case trial = "trial"             // In free trial period
    case expired = "expired"         // Lapsed subscription
    case gracePeriod = "gracePeriod" // Payment issue, retrying
    case revoked = "revoked"         // Refunded or cancelled
}

public struct ChildProfile: Codable, Identifiable {
    public let id: String
    public let familyID: String
    public var name: String
    public var avatarAssetURL: String?
    public let birthDate: Date
    public var pointBalance: Int
    // Additional properties for COPPA compliance and data management
    public var totalPointsEarned: Int
    public var deviceID: String?
    public var cloudKitZoneID: String?
    public var createdAt: Date
    public var ageVerified: Bool
    public var verificationMethod: String?
    public var dataRetentionPeriod: Int? // In days
    // Notification preferences
    public var notificationPreferences: NotificationPreferences?
    
    public init(id: String, familyID: String, name: String, avatarAssetURL: String?, birthDate: Date, pointBalance: Int, totalPointsEarned: Int = 0, deviceID: String? = nil, cloudKitZoneID: String? = nil, createdAt: Date = Date(), ageVerified: Bool = false, verificationMethod: String? = nil, dataRetentionPeriod: Int? = nil, notificationPreferences: NotificationPreferences? = nil) {
        self.id = id
        self.familyID = familyID
        self.name = name
        self.avatarAssetURL = avatarAssetURL
        self.birthDate = birthDate
        self.pointBalance = pointBalance
        self.totalPointsEarned = totalPointsEarned
        self.deviceID = deviceID
        self.cloudKitZoneID = cloudKitZoneID
        self.createdAt = createdAt
        self.ageVerified = ageVerified
        self.verificationMethod = verificationMethod
        self.dataRetentionPeriod = dataRetentionPeriod
        self.notificationPreferences = notificationPreferences
    }
}

// MARK: - Authentication Models

public enum AccountStatus: String, Codable {
    case available = "available"
    case restricted = "restricted"
    case noAccount = "noAccount"
    case couldNotDetermine = "couldNotDetermine"
}

public struct AuthState: Codable {
    public let isAuthenticated: Bool
    public let accountStatus: AccountStatus
    public let userID: String?
    public let familyID: String?
    
    public init(isAuthenticated: Bool, accountStatus: AccountStatus, userID: String?, familyID: String?) {
        self.isAuthenticated = isAuthenticated
        self.accountStatus = accountStatus
        self.userID = userID
        self.familyID = familyID
    }
}

// MARK: - App Category
public enum AppCategory: String, CaseIterable, Codable {
    case learning = "Learning"
    case reward = "Reward"
}

// MARK: - App Filter for UI
public enum AppFilter: CaseIterable {
    case all
    case learning
    case reward

    public var title: String {
        switch self {
        case .all:
            return "All"
        case .learning:
            return "Learning"
        case .reward:
            return "Reward"
        }
    }
}

// MARK: - App Metadata
public struct AppMetadata: Identifiable, Codable, Equatable {
    public let id: String
    public let bundleID: String
    public let displayName: String
    public let isSystemApp: Bool
    public let iconData: Data?
    
    public init(id: String, bundleID: String, displayName: String, isSystemApp: Bool, iconData: Data?) {
        self.id = id
        self.bundleID = bundleID
        self.displayName = displayName
        self.isSystemApp = isSystemApp
        self.iconData = iconData
    }
}

// MARK: - App Categorization
public struct AppCategorization: Identifiable, Codable, Equatable {
    public let id: String
    public let appBundleID: String
    public let category: AppCategory
    public let childProfileID: String
    public let pointsPerHour: Int
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        appBundleID: String,
        category: AppCategory,
        childProfileID: String,
        pointsPerHour: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.appBundleID = appBundleID
        self.category = category
        self.childProfileID = childProfileID
        self.pointsPerHour = pointsPerHour
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - UsageSession Model
public struct UsageSession: Codable, Identifiable {
    public let id: String
    public let childProfileID: String
    public let appBundleID: String
    public let category: AppCategory
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    // Validation fields (removed to avoid circular dependency)
    public let isValidated: Bool
    
    public init(id: String, childProfileID: String, appBundleID: String, category: AppCategory, startTime: Date, endTime: Date, duration: TimeInterval, isValidated: Bool = false) {
        self.id = id
        self.childProfileID = childProfileID
        self.appBundleID = appBundleID
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.isValidated = isValidated
    }
}

// Add ScreenTimeSession model
public struct ScreenTimeSession: Codable, Identifiable {
    public let id: String
    public let childProfileID: String
    public let appBundleID: String
    public let category: AppCategory
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public var pointsEarned: Int
    
    public init(id: String, childProfileID: String, appBundleID: String, category: AppCategory, startTime: Date, endTime: Date, duration: TimeInterval, pointsEarned: Int = 0) {
        self.id = id
        self.childProfileID = childProfileID
        self.appBundleID = appBundleID
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.pointsEarned = pointsEarned
    }
    
    public init(childID: String, appName: String, duration: TimeInterval, timestamp: Date) {
        self.id = UUID().uuidString
        self.childProfileID = childID
        self.appBundleID = appName
        self.category = .learning
        self.startTime = timestamp.addingTimeInterval(-duration)
        self.endTime = timestamp
        self.duration = duration
        self.pointsEarned = 0
    }
}

// MARK: - Reward Models

public struct Reward: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let pointCost: Int
    public let imageURL: String?
    public let isActive: Bool
    public let createdAt: Date
    
    public init(id: String, name: String, description: String, pointCost: Int, imageURL: String?, isActive: Bool, createdAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.pointCost = pointCost
        self.imageURL = imageURL
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

public enum RedemptionValidationResult: Codable {
    case valid
    case insufficientPoints(required: Int, available: Int)
    case rewardInactive
    case otherError(String)
}

public enum RedemptionResult: Codable {
    case success(transactionID: String)
    case failure(reason: String)
}

// MARK: - Achievement Models

public struct Achievement: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let criteria: String
    public let pointReward: Int
    public let imageURL: String?
    public let isUnlocked: Bool
    public let unlockedAt: Date?
    
    public init(id: String, name: String, description: String, criteria: String, pointReward: Int, imageURL: String?, isUnlocked: Bool, unlockedAt: Date?) {
        self.id = id
        self.name = name
        self.description = description
        self.criteria = criteria
        self.pointReward = pointReward
        self.imageURL = imageURL
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
}

// MARK: - Additional Models for CloudKitService

public struct PointTransaction: Codable, Identifiable {
    public let id: String
    public let childProfileID: String
    public let points: Int
    public let reason: String
    public let timestamp: Date
    
    public init(id: String, childProfileID: String, points: Int, reason: String, timestamp: Date) {
        self.id = id
        self.childProfileID = childProfileID
        self.points = points
        self.reason = reason
        self.timestamp = timestamp
    }
}

// MARK: - Point-to-Time Redemption Model (for app screen time rewards)
public struct PointToTimeRedemption: Codable, Identifiable {
    public let id: String
    public let childProfileID: String
    public let appCategorizationID: String
    public let pointsSpent: Int
    public let timeGrantedMinutes: Int
    public let conversionRate: Double // points per minute
    public let redeemedAt: Date
    public let expiresAt: Date
    public var timeUsedMinutes: Int
    public let status: RedemptionStatus

    public init(id: String, childProfileID: String, appCategorizationID: String, pointsSpent: Int, timeGrantedMinutes: Int, conversionRate: Double, redeemedAt: Date, expiresAt: Date, timeUsedMinutes: Int = 0, status: RedemptionStatus = .active) {
        self.id = id
        self.childProfileID = childProfileID
        self.appCategorizationID = appCategorizationID
        self.pointsSpent = pointsSpent
        self.timeGrantedMinutes = timeGrantedMinutes
        self.conversionRate = conversionRate
        self.redeemedAt = redeemedAt
        self.expiresAt = expiresAt
        self.timeUsedMinutes = timeUsedMinutes
        self.status = status
    }
}

public enum RedemptionStatus: String, Codable, CaseIterable {
    case active = "active"
    case expired = "expired"
    case used = "used"
}

public struct RewardRedemption: Codable, Identifiable {
    public let id: String
    public let childProfileID: String
    public let rewardID: String
    public let pointsSpent: Int
    public let timestamp: Date
    public let transactionID: String

    public init(id: String, childProfileID: String, rewardID: String, pointsSpent: Int, timestamp: Date, transactionID: String) {
        self.id = id
        self.childProfileID = childProfileID
        self.rewardID = rewardID
        self.pointsSpent = pointsSpent
        self.timestamp = timestamp
        self.transactionID = transactionID
    }
}

public struct FamilySettings: Codable, Identifiable {
    public let id: String
    public let familyID: String
    public var dailyTimeLimit: Int? // In minutes
    public var bedtimeStart: Date?
    public var bedtimeEnd: Date?
    public var contentRestrictions: [String: Bool] // App bundle ID to restriction status
    
    public init(id: String, familyID: String, dailyTimeLimit: Int? = nil, bedtimeStart: Date? = nil, bedtimeEnd: Date? = nil, contentRestrictions: [String: Bool] = [:]) {
        self.id = id
        self.familyID = familyID
        self.dailyTimeLimit = dailyTimeLimit
        self.bedtimeStart = bedtimeStart
        self.bedtimeEnd = bedtimeEnd
        self.contentRestrictions = contentRestrictions
    }
}

public struct SubscriptionMetadata: Codable {
    public var trialStartDate: Date?
    public var trialEndDate: Date?
    public var hasUsedTrial: Bool
    public var subscriptionStartDate: Date?
    public var subscriptionEndDate: Date?
    public var isActive: Bool

    public init(
        trialStartDate: Date? = nil,
        trialEndDate: Date? = nil,
        hasUsedTrial: Bool = false,
        subscriptionStartDate: Date? = nil,
        subscriptionEndDate: Date? = nil,
        isActive: Bool = false
    ) {
        self.trialStartDate = trialStartDate
        self.trialEndDate = trialEndDate
        self.hasUsedTrial = hasUsedTrial
        self.subscriptionStartDate = subscriptionStartDate
        self.subscriptionEndDate = subscriptionEndDate
        self.isActive = isActive
    }
}

// MARK: - Subscription Models

public enum SubscriptionTier: String, Codable, CaseIterable {
    case oneChild = "oneChild"
    case twoChildren = "twoChildren"
    case threeOrMore = "threeOrMore"

    public var displayName: String {
        switch self {
        case .oneChild:
            return "1 Child Plan"
        case .twoChildren:
            return "2 Children Plan"
        case .threeOrMore:
            return "3+ Children Plan"
        }
    }

    public var maxChildren: Int {
        switch self {
        case .oneChild:
            return 1
        case .twoChildren:
            return 2
        case .threeOrMore:
            return Int.max
        }
    }
}

public struct SubscriptionEntitlement: Codable, Identifiable {
    public let id: String
    public let familyID: String
    public let subscriptionTier: SubscriptionTier
    public let receiptData: String
    public let originalTransactionID: String
    public let transactionID: String
    public let purchaseDate: Date
    public let expirationDate: Date
    public var isActive: Bool
    public var isInTrial: Bool
    public var autoRenewStatus: Bool
    public var lastValidatedAt: Date
    public var gracePeriodExpiresAt: Date?
    public let metadata: [String: String]

    public init(
        id: String,
        familyID: String,
        subscriptionTier: SubscriptionTier,
        receiptData: String,
        originalTransactionID: String,
        transactionID: String,
        purchaseDate: Date,
        expirationDate: Date,
        isActive: Bool,
        isInTrial: Bool = false,
        autoRenewStatus: Bool = true,
        lastValidatedAt: Date = Date(),
        gracePeriodExpiresAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.familyID = familyID
        self.subscriptionTier = subscriptionTier
        self.receiptData = receiptData
        self.originalTransactionID = originalTransactionID
        self.transactionID = transactionID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.isActive = isActive
        self.isInTrial = isInTrial
        self.autoRenewStatus = autoRenewStatus
        self.lastValidatedAt = lastValidatedAt
        self.gracePeriodExpiresAt = gracePeriodExpiresAt
        self.metadata = metadata
    }
}

// MARK: - Fraud Prevention Models

public enum FraudDetectionType: String, Codable, CaseIterable {
    case duplicateTransaction = "duplicateTransaction"
    case tamperedReceipt = "tamperedReceipt"
    case jailbrokenDevice = "jailbrokenDevice"
    case anomalousUsage = "anomalousUsage"
}

public struct FraudDetectionEvent: Codable, Identifiable {
    public let id: String
    public let familyID: String
    public let detectionType: FraudDetectionType
    public let severity: FraudSeverity
    public let timestamp: Date
    public let deviceInfo: [String: String]
    public let transactionInfo: [String: String]?
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        familyID: String,
        detectionType: FraudDetectionType,
        severity: FraudSeverity,
        timestamp: Date = Date(),
        deviceInfo: [String: String],
        transactionInfo: [String: String]? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.familyID = familyID
        self.detectionType = detectionType
        self.severity = severity
        self.timestamp = timestamp
        self.deviceInfo = deviceInfo
        self.transactionInfo = transactionInfo
        self.metadata = metadata
    }
}

public enum FraudSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Audit Logging Models

public enum ValidationEventType: String, Codable, CaseIterable {
    case receiptValidated = "receiptValidated"
    case entitlementCreated = "entitlementCreated"
    case entitlementUpdated = "entitlementUpdated"
    case entitlementExpired = "entitlementExpired"
    case gracePeriodStarted = "gracePeriodStarted"
    case gracePeriodEnded = "gracePeriodEnded"
    case fraudDetected = "fraudDetected"
    case validationFailed = "validationFailed"
}

public struct ValidationAuditLog: Codable, Identifiable {
    public let id: String
    public let familyID: String
    public let transactionID: String?
    public let productID: String
    public let eventType: ValidationEventType
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        familyID: String,
        transactionID: String? = nil,
        productID: String,
        eventType: ValidationEventType,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.familyID = familyID
        self.transactionID = transactionID
        self.productID = productID
        self.eventType = eventType
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Educational Goals Models

public enum GoalType: Codable, Equatable {
    case timeBased(hours: Int)
    case pointBased(points: Int)
    case appSpecific(bundleID: String, hours: Int)
    case streak(days: Int)
}

public enum GoalFrequency: String, Codable, Equatable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"
}

public enum GoalStatus: String, Codable, Equatable {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case completed = "completed"
    case failed = "failed"
}

public struct GoalMetadata: Codable, Equatable {
    public var createdBy: String  // Parent user ID
    public var lastModifiedAt: Date
    public var lastModifiedBy: String
    public var completedAt: Date?
    public var failedAt: Date?

    public init(
        createdBy: String,
        lastModifiedAt: Date = Date(),
        lastModifiedBy: String,
        completedAt: Date? = nil,
        failedAt: Date? = nil
    ) {
        self.createdBy = createdBy
        self.lastModifiedAt = lastModifiedAt
        self.lastModifiedBy = lastModifiedBy
        self.completedAt = completedAt
        self.failedAt = failedAt
    }
}

public struct EducationalGoal: Codable, Equatable, Identifiable {
    public let id: UUID
    public let childProfileID: String
    public var title: String
    public var description: String
    public var type: GoalType
    public var frequency: GoalFrequency
    public var targetValue: Double
    public var currentValue: Double
    public var startDate: Date
    public var endDate: Date
    public var createdAt: Date
    public var status: GoalStatus
    public var isRecurring: Bool
    public var metadata: GoalMetadata

    public init(
        id: UUID = UUID(),
        childProfileID: String,
        title: String,
        description: String,
        type: GoalType,
        frequency: GoalFrequency,
        targetValue: Double,
        currentValue: Double,
        startDate: Date,
        endDate: Date,
        createdAt: Date = Date(),
        status: GoalStatus,
        isRecurring: Bool,
        metadata: GoalMetadata
    ) {
        self.id = id
        self.childProfileID = childProfileID
        self.title = title
        self.description = description
        self.type = type
        self.frequency = frequency
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.status = status
        self.isRecurring = isRecurring
        self.metadata = metadata
    }
}

// MARK: - Achievement Badge Models

public enum BadgeType: String, Codable, Equatable {
    case streak = "streak"
    case points = "points"
    case time = "time"
    case appSpecific = "appSpecific"
    case milestone = "milestone"
    case custom = "custom"
}

public enum MilestoneType: String, Codable, Equatable {
    case firstGoalCompleted = "firstGoalCompleted"
    case hundredPoints = "hundredPoints"
    case tenHoursLearning = "tenHoursLearning"
    case oneWeekStreak = "oneWeekStreak"
    case fiveGoalsCompleted = "fiveGoalsCompleted"
    case custom = "custom"
}

public struct BadgeMetadata: Codable, Equatable {
    public var relatedGoalID: UUID?
    public var relatedSessionIDs: [UUID]?
    public var pointsAwarded: Int?  // Optional bonus points for earning badge

    public init(
        relatedGoalID: UUID? = nil,
        relatedSessionIDs: [UUID]? = nil,
        pointsAwarded: Int? = nil
    ) {
        self.relatedGoalID = relatedGoalID
        self.relatedSessionIDs = relatedSessionIDs
        self.pointsAwarded = pointsAwarded
    }
}

public struct AchievementBadge: Codable, Equatable, Identifiable {
    public let id: UUID
    public let childProfileID: String
    public var type: BadgeType
    public var title: String
    public var description: String
    public var earnedAt: Date
    public var icon: String  // SF Symbol name or asset name
    public var isRare: Bool
    public var metadata: BadgeMetadata

    public init(
        id: UUID = UUID(),
        childProfileID: String,
        type: BadgeType,
        title: String,
        description: String,
        earnedAt: Date,
        icon: String,
        isRare: Bool,
        metadata: BadgeMetadata
    ) {
        self.id = id
        self.childProfileID = childProfileID
        self.type = type
        self.title = title
        self.description = description
        self.earnedAt = earnedAt
        self.icon = icon
        self.isRare = isRare
        self.metadata = metadata
    }
}

// MARK: - Permission Models

public enum PermissionRole: String, Codable, CaseIterable {
    case owner = "owner"
    case coParent = "coParent"
    case viewer = "viewer" // For v1.2

    public var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .coParent:
            return "Co-Parent"
        case .viewer:
            return "Viewer"
        }
    }

    public var hasFullAccess: Bool {
        switch self {
        case .owner, .coParent:
            return true
        case .viewer:
            return false
        }
    }
}

public enum PermissionAction: String, Codable, CaseIterable {
    case view = "view"
    case edit = "edit"
    case delete = "delete"
    case invite = "invite"
    case remove = "remove"

    public var displayName: String {
        switch self {
        case .view:
            return "View"
        case .edit:
            return "Edit"
        case .delete:
            return "Delete"
        case .invite:
            return "Invite"
        case .remove:
            return "Remove"
        }
    }
}

public struct PermissionCheck: Codable {
    public let userID: String
    public let familyID: String
    public let action: PermissionAction
    public let targetEntity: String?

    public init(userID: String, familyID: String, action: PermissionAction, targetEntity: String? = nil) {
        self.userID = userID
        self.familyID = familyID
        self.action = action
        self.targetEntity = targetEntity
    }
}

public enum PermissionError: Error, LocalizedError {
    case unauthorized(action: PermissionAction)
    case invalidRole
    case familyNotFound
    case userNotFound

    public var errorDescription: String? {
        switch self {
        case .unauthorized(let action):
            return "You don't have permission to \(action.displayName.lowercased()) this item."
        case .invalidRole:
            return "Invalid permission role."
        case .familyNotFound:
            return "Family not found."
        case .userNotFound:
            return "User not found in family."
        }
    }
}

// MARK: - Repository Protocols

@available(iOS 15.0, macOS 12.0, *)
public protocol ChildProfileRepository {
    func createChild(_ child: ChildProfile) async throws -> ChildProfile
    func fetchChild(id: String) async throws -> ChildProfile?
    func fetchChildren(for familyID: String) async throws -> [ChildProfile]
    func updateChild(_ child: ChildProfile) async throws -> ChildProfile
    func deleteChild(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol RewardRepository {
    func createReward(_ reward: Reward) async throws -> Reward
    func fetchReward(id: String) async throws -> Reward?
    func fetchRewards() async throws -> [Reward]
    func updateReward(_ reward: Reward) async throws -> Reward
    func deleteReward(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol ScreenTimeSessionRepository {
    func createSession(_ session: ScreenTimeSession) async throws -> ScreenTimeSession
    func fetchSession(id: String) async throws -> ScreenTimeSession?
    func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [ScreenTimeSession]
    func updateSession(_ session: ScreenTimeSession) async throws -> ScreenTimeSession
    func deleteSession(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol AppCategorizationRepository {
    func createAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization
    func fetchAppCategorization(id: String) async throws -> AppCategorization?
    func fetchAppCategorizations(for childID: String) async throws -> [AppCategorization]
    func updateAppCategorization(_ categorization: AppCategorization) async throws -> AppCategorization
    func deleteAppCategorization(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol UsageSessionRepository {
    func createSession(_ session: UsageSession) async throws -> UsageSession
    func fetchSession(id: String) async throws -> UsageSession?
    func fetchSessions(for childID: String, dateRange: DateRange?) async throws -> [UsageSession]
    func updateSession(_ session: UsageSession) async throws -> UsageSession
    func deleteSession(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol PointTransactionRepository {
    func createTransaction(_ transaction: PointTransaction) async throws -> PointTransaction
    func fetchTransaction(id: String) async throws -> PointTransaction?
    func fetchTransactions(for childID: String, limit: Int?) async throws -> [PointTransaction]
    func fetchTransactions(for childID: String, dateRange: DateRange?) async throws -> [PointTransaction]
    func deleteTransaction(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol PointToTimeRedemptionRepository {
    func createPointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption
    func fetchPointToTimeRedemption(id: String) async throws -> PointToTimeRedemption?
    func fetchPointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption]
    func fetchActivePointToTimeRedemptions(for childID: String) async throws -> [PointToTimeRedemption]
    func updatePointToTimeRedemption(_ redemption: PointToTimeRedemption) async throws -> PointToTimeRedemption
    func deletePointToTimeRedemption(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol FamilyRepository {
    func createFamily(_ family: Family) async throws -> Family
    func fetchFamily(id: String) async throws -> Family?
    func fetchFamilies(for userID: String) async throws -> [Family]
    func updateFamily(_ family: Family) async throws -> Family
    func deleteFamily(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol FamilySettingsRepository {
    func createSettings(_ settings: FamilySettings) async throws -> FamilySettings
    func fetchSettings(for familyID: String) async throws -> FamilySettings?
    func updateSettings(_ settings: FamilySettings) async throws -> FamilySettings
    func deleteSettings(id: String) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public protocol SubscriptionEntitlementRepository {
    func createEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement
    func fetchEntitlement(id: String) async throws -> SubscriptionEntitlement?
    func fetchEntitlement(for familyID: String) async throws -> SubscriptionEntitlement?
    func fetchEntitlements(for familyID: String) async throws -> [SubscriptionEntitlement]
    func fetchEntitlement(byTransactionID transactionID: String) async throws -> SubscriptionEntitlement?
    func fetchEntitlement(byOriginalTransactionID originalTransactionID: String) async throws -> SubscriptionEntitlement?
    func updateEntitlement(_ entitlement: SubscriptionEntitlement) async throws -> SubscriptionEntitlement
    func deleteEntitlement(id: String) async throws
    func validateEntitlement(for familyID: String) async throws -> SubscriptionEntitlement?
}

// MARK: - Parent Coordination Models

public enum ParentCoordinationEventType: String, Codable, CaseIterable {
    case usageSessionChanged
    case appCategorizationChanged
    case settingsUpdated
    case pointsAdjusted
    case rewardRedeemed
    case childProfileModified
}

// Simple codable dictionary for changes
public struct CodableDictionary: Codable, Equatable {
    private let values: [String: String]
    
    public init(_ dictionary: [String: String]) {
        self.values = dictionary
    }
    
    public subscript(key: String) -> String? {
        return values[key]
    }
    
    public var dictionary: [String: String] {
        return values
    }
}

public struct ParentCoordinationEvent: Codable, Identifiable {
    public let id: UUID
    public let familyID: UUID
    public let triggeringUserID: String
    public let eventType: ParentCoordinationEventType
    public let targetEntity: String
    public let targetEntityID: UUID
    public let changes: CodableDictionary
    public let timestamp: Date
    public let deviceID: String?
    
    public init(
        id: UUID,
        familyID: UUID,
        triggeringUserID: String,
        eventType: ParentCoordinationEventType,
        targetEntity: String,
        targetEntityID: UUID,
        changes: CodableDictionary,
        timestamp: Date,
        deviceID: String?
    ) {
        self.id = id
        self.familyID = familyID
        self.triggeringUserID = triggeringUserID
        self.eventType = eventType
        self.targetEntity = targetEntity
        self.targetEntityID = targetEntityID
        self.changes = changes
        self.timestamp = timestamp
        self.deviceID = deviceID
    }
}

// MARK: - Helper Types

public struct NotificationPreferences: Codable {
    public var enabledNotifications: Set<NotificationEvent>
    public var quietHoursStart: Date?
    public var quietHoursEnd: Date?
    public var digestMode: Bool
    public var lastNotificationSent: Date?
    public var notificationsEnabled: Bool
    
    public init(
        enabledNotifications: Set<NotificationEvent> = Set(NotificationEvent.allCases),
        quietHoursStart: Date? = nil,
        quietHoursEnd: Date? = nil,
        digestMode: Bool = false,
        lastNotificationSent: Date? = nil,
        notificationsEnabled: Bool = true
    ) {
        self.enabledNotifications = enabledNotifications
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.digestMode = digestMode
        self.lastNotificationSent = lastNotificationSent
        self.notificationsEnabled = notificationsEnabled
    }
}

public enum NotificationEvent: String, CaseIterable, Codable {
    case pointsEarned = "points_earned"
    case goalAchieved = "goal_achieved"
    case weeklyMilestone = "weekly_milestone"
    case streakAchieved = "streak_achieved"
}

// MARK: - Application Usage Models

public enum ApplicationCategory: String, Codable, Equatable {
    case educational = "educational"
    case entertainment = "entertainment"
    case social = "social"
    case productivity = "productivity"
    case game = "game"
    case other = "other"
}

public struct ApplicationUsage: Codable, Equatable {
    public let token: String
    public let displayName: String
    public let category: ApplicationCategory
    public let timeSpent: TimeInterval
    public let pointsEarned: Int

    public init(
        token: String,
        displayName: String,
        category: ApplicationCategory,
        timeSpent: TimeInterval,
        pointsEarned: Int
    ) {
        self.token = token
        self.displayName = displayName
        self.category = category
        self.timeSpent = timeSpent
        self.pointsEarned = pointsEarned
    }
}

public struct UsageReport: Codable, Equatable {
    public let childID: String
    public let date: Date
    public let applications: [ApplicationUsage]
    public let totalScreenTime: TimeInterval

    public init(
        childID: String,
        date: Date,
        applications: [ApplicationUsage],
        totalScreenTime: TimeInterval
    ) {
        self.childID = childID
        self.date = date
        self.applications = applications
        self.totalScreenTime = totalScreenTime
    }
}

// MARK: - Device Activity Schedule

public struct DeviceActivitySchedule: Codable, Equatable {
    public let intervalStart: DateComponents
    public let intervalEnd: DateComponents
    public let repeats: Bool

    public init(
        intervalStart: DateComponents,
        intervalEnd: DateComponents,
        repeats: Bool = true
    ) {
        self.intervalStart = intervalStart
        self.intervalEnd = intervalEnd
        self.repeats = repeats
    }

    public static func dailySchedule(from startTime: DateComponents, to endTime: DateComponents) -> DeviceActivitySchedule {
        return DeviceActivitySchedule(
            intervalStart: startTime,
            intervalEnd: endTime,
            repeats: true
        )
    }

    public static func allDay() -> DeviceActivitySchedule {
        return DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }
}

// MARK: - Notification Models
// NotificationEvent enum has been moved to RewardCore module to avoid circular dependency

// MARK: - Validation Models (Moved from RewardCore to avoid circular dependency)

// MARK: - Admin Action Models

public enum AdminActionType: String, Codable, CaseIterable {
    case suspendFamily = "suspendFamily"
    case activateFamily = "activateFamily"
    case extendTrial = "extendTrial"
    case refundTransaction = "refundTransaction"
    case adjustPoints = "adjustPoints"
    case resetUsage = "resetUsage"
    case investigateFraud = "investigateFraud"
}

public struct AdminAction: Codable, Identifiable {
    public let id: String
    public let adminUserID: String
    public let targetFamilyID: String
    public let action: AdminActionType
    public let reason: String
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        adminUserID: String,
        targetFamilyID: String,
        action: AdminActionType,
        reason: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.adminUserID = adminUserID
        self.targetFamilyID = targetFamilyID
        self.action = action
        self.reason = reason
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

public struct AdminSession: Codable, Identifiable {
    public let id: String
    public let adminUserID: String
    public let sessionStartTime: Date
    public var sessionEndTime: Date?
    public let deviceInfo: [String: String]
    public var actionsPerformed: [String] // Action IDs
    public var isActive: Bool

    public init(
        id: String = UUID().uuidString,
        adminUserID: String,
        sessionStartTime: Date = Date(),
        sessionEndTime: Date? = nil,
        deviceInfo: [String: String] = [:],
        actionsPerformed: [String] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.adminUserID = adminUserID
        self.sessionStartTime = sessionStartTime
        self.sessionEndTime = sessionEndTime
        self.deviceInfo = deviceInfo
        self.actionsPerformed = actionsPerformed
        self.isActive = isActive
    }
}

// MARK: - Family Invitation Models

public struct FamilyInvitation: Codable, Identifiable {
    public let id: UUID
    public let familyID: String
    public let invitingUserID: String
    public let inviteeEmail: String?
    public let token: UUID
    public let createdAt: Date
    public let expiresAt: Date
    public var isUsed: Bool
    public let deepLinkURL: String

    public init(
        id: UUID = UUID(),
        familyID: String,
        invitingUserID: String,
        inviteeEmail: String? = nil,
        token: UUID = UUID(),
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(72 * 60 * 60), // 72 hours
        isUsed: Bool = false,
        deepLinkURL: String
    ) {
        self.id = id
        self.familyID = familyID
        self.invitingUserID = invitingUserID
        self.inviteeEmail = inviteeEmail
        self.token = token
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isUsed = isUsed
        self.deepLinkURL = deepLinkURL
    }
}

@available(iOS 15.0, macOS 12.0, *)
public protocol FamilyInvitationRepository {
    func createInvitation(_ invitation: FamilyInvitation) async throws -> FamilyInvitation
    func fetchInvitation(by token: UUID) async throws -> FamilyInvitation?
    func fetchInvitations(for familyID: String) async throws -> [FamilyInvitation]
    func fetchInvitations(by invitingUserID: String) async throws -> [FamilyInvitation]
    func updateInvitation(_ invitation: FamilyInvitation) async throws -> FamilyInvitation
    func deleteInvitation(id: UUID) async throws
    func deleteExpiredInvitations() async throws
}

// MARK: - Repository Protocols for Audit

@available(iOS 15.0, macOS 12.0, *)
public protocol ValidationAuditRepository {
    func createAuditLog(_ log: ValidationAuditLog) async throws -> ValidationAuditLog
    func fetchAuditLogs(for familyID: String, eventType: ValidationEventType?) async throws -> [ValidationAuditLog]
    func fetchAuditLogs(for familyID: String, since date: Date) async throws -> [ValidationAuditLog]
}

@available(iOS 15.0, macOS 12.0, *)
public protocol FraudDetectionRepository {
    func createFraudEvent(_ event: FraudDetectionEvent) async throws -> FraudDetectionEvent
    func fetchFraudEvents(for familyID: String) async throws -> [FraudDetectionEvent]
    func fetchHighRiskEvents() async throws -> [FraudDetectionEvent]
}

@available(iOS 15.0, macOS 12.0, *)
public protocol AdminAuditRepository {
    func createAdminAction(_ action: AdminAction) async throws -> AdminAction
    func fetchAllActions() async throws -> [AdminAction]
    func fetchActionsForFamily(_ familyID: String) async throws -> [AdminAction]
    func fetchActionsByAdmin(_ adminUserID: String) async throws -> [AdminAction]
}

// MARK: - Parent Activity Models

public enum ParentActivityType: String, Codable, CaseIterable {
    case appCategorizationAdded = "appCategorizationAdded"
    case appCategorizationModified = "appCategorizationModified"
    case appCategorizationRemoved = "appCategorizationRemoved"
    case pointsAdjusted = "pointsAdjusted"
    case rewardRedeemed = "rewardRedeemed"
    case childProfileModified = "childProfileModified"
    case settingsUpdated = "settingsUpdated"
    case childAdded = "childAdded"

    public var displayName: String {
        switch self {
        case .appCategorizationAdded:
            return "App Added to Category"
        case .appCategorizationModified:
            return "App Category Modified"
        case .appCategorizationRemoved:
            return "App Removed from Category"
        case .pointsAdjusted:
            return "Points Adjusted"
        case .rewardRedeemed:
            return "Reward Redeemed"
        case .childProfileModified:
            return "Child Profile Updated"
        case .settingsUpdated:
            return "Settings Updated"
        case .childAdded:
            return "Child Added"
        }
    }

    public var icon: String {
        switch self {
        case .appCategorizationAdded, .appCategorizationModified, .appCategorizationRemoved:
            return "apps.iphone"
        case .pointsAdjusted:
            return "star.fill"
        case .rewardRedeemed:
            return "gift.fill"
        case .childProfileModified:
            return "person.fill"
        case .settingsUpdated:
            return "gearshape.fill"
        case .childAdded:
            return "person.badge.plus.fill"
        }
    }
}

public struct ParentActivity: Codable, Identifiable, Equatable {
    public let id: UUID
    public let familyID: UUID
    public let triggeringUserID: String
    public let activityType: ParentActivityType
    public let targetEntity: String
    public let targetEntityID: UUID
    public let changes: CodableDictionary
    public let timestamp: Date
    public let deviceID: String?

    public init(
        id: UUID = UUID(),
        familyID: UUID,
        triggeringUserID: String,
        activityType: ParentActivityType,
        targetEntity: String,
        targetEntityID: UUID,
        changes: CodableDictionary,
        timestamp: Date = Date(),
        deviceID: String? = nil
    ) {
        self.id = id
        self.familyID = familyID
        self.triggeringUserID = triggeringUserID
        self.activityType = activityType
        self.targetEntity = targetEntity
        self.targetEntityID = targetEntityID
        self.changes = changes
        self.timestamp = timestamp
        self.deviceID = deviceID
    }
}

// MARK: - ParentActivity Extensions

public extension ParentActivity {
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var detailedDescription: String {
        let changes = self.changes.dictionary

        switch activityType {
        case .appCategorizationAdded:
            let appName = changes["appName"] ?? "Unknown App"
            let category = changes["category"] ?? "Unknown"
            return "\(appName) was added to \(category) category"

        case .appCategorizationModified:
            let appName = changes["appName"] ?? "Unknown App"
            let oldCategory = changes["oldCategory"] ?? "Unknown"
            let newCategory = changes["newCategory"] ?? "Unknown"
            return "\(appName) moved from \(oldCategory) to \(newCategory)"

        case .appCategorizationRemoved:
            let appName = changes["appName"] ?? "Unknown App"
            let category = changes["category"] ?? "Unknown"
            return "\(appName) was removed from \(category) category"

        case .pointsAdjusted:
            let childName = changes["childName"] ?? "Unknown Child"
            let pointsChange = changes["pointsChange"] ?? "0"
            let reason = changes["reason"] ?? "Manual adjustment"
            return "\(childName)'s points adjusted by \(pointsChange) (\(reason))"

        case .rewardRedeemed:
            let childName = changes["childName"] ?? "Unknown Child"
            let rewardName = changes["rewardName"] ?? "Unknown Reward"
            let pointsSpent = changes["pointsSpent"] ?? "0"
            return "\(childName) redeemed \(rewardName) for \(pointsSpent) points"

        case .childProfileModified:
            let childName = changes["childName"] ?? "Unknown Child"
            let modifications = changes["modifications"] ?? "profile information"
            return "\(childName)'s \(modifications) was updated"

        case .settingsUpdated:
            let settingsType = changes["settingsType"] ?? "family settings"
            return "\(settingsType) were updated"

        case .childAdded:
            let childName = changes["childName"] ?? "Unknown Child"
            return "\(childName) was added to the family"
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
public protocol ParentActivityRepository {
    func createActivity(_ activity: ParentActivity) async throws -> ParentActivity
    func fetchActivity(id: UUID) async throws -> ParentActivity?
    func fetchActivities(for familyID: UUID, limit: Int?) async throws -> [ParentActivity]
    func fetchActivities(for familyID: UUID, since date: Date) async throws -> [ParentActivity]
    func fetchActivities(for familyID: UUID, dateRange: DateRange) async throws -> [ParentActivity]
    func deleteActivity(id: UUID) async throws
    func deleteOldActivities(olderThan date: Date) async throws
}

// MARK: - Conflict Resolution Models

public struct ConflictMetadata: Codable, Identifiable {
    public let id: String
    public let familyID: String
    public let recordType: String
    public let recordID: String
    public let conflictingChanges: [ConflictChange]
    public let resolutionStrategy: ResolutionStrategy
    public let resolvedBy: String?
    public let resolvedAt: Date?
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        familyID: String,
        recordType: String,
        recordID: String,
        conflictingChanges: [ConflictChange],
        resolutionStrategy: ResolutionStrategy,
        resolvedBy: String? = nil,
        resolvedAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.familyID = familyID
        self.recordType = recordType
        self.recordID = recordID
        self.conflictingChanges = conflictingChanges
        self.resolutionStrategy = resolutionStrategy
        self.resolvedBy = resolvedBy
        self.resolvedAt = resolvedAt
        self.metadata = metadata
    }
}

public struct ConflictChange: Codable {
    public let userID: String
    public let changeType: ChangeType
    public let fieldChanges: [FieldChange]
    public let timestamp: Date
    public let deviceInfo: String

    public init(
        userID: String,
        changeType: ChangeType,
        fieldChanges: [FieldChange],
        timestamp: Date,
        deviceInfo: String
    ) {
        self.userID = userID
        self.changeType = changeType
        self.fieldChanges = fieldChanges
        self.timestamp = timestamp
        self.deviceInfo = deviceInfo
    }
}

public enum ChangeType: String, Codable {
    case create = "create"
    case update = "update"
    case delete = "delete"
}

public struct FieldChange: Codable {
    public let fieldName: String
    public let oldValue: String?
    public let newValue: String?

    public init(fieldName: String, oldValue: String?, newValue: String?) {
        self.fieldName = fieldName
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

public enum ResolutionStrategy: String, Codable {
    case automaticLastWriteWins = "automaticLastWriteWins"
    case automaticMerge = "automaticMerge"
    case manualSelection = "manualSelection"
    case priorityBased = "priorityBased"
}

@available(iOS 15.0, macOS 12.0, *)
public protocol ConflictMetadataRepository {
    func createConflictMetadata(_ metadata: ConflictMetadata) async throws -> ConflictMetadata
    func fetchConflictMetadata(id: String) async throws -> ConflictMetadata?
    func fetchConflicts(for familyID: String) async throws -> [ConflictMetadata]
    func updateConflictMetadata(_ metadata: ConflictMetadata) async throws -> ConflictMetadata
    func deleteConflictMetadata(id: String) async throws
}
