import Foundation
import SharedModels
import CloudKitService

/// Service responsible for handling point-to-screen-time conversions and redemptions
@available(iOS 15.0, macOS 12.0, *)
public class PointRedemptionService {
    public static let shared = PointRedemptionService(
        childProfileRepository: CloudKitService.shared,
        pointToTimeRedemptionRepository: CloudKitService.shared,
        pointTransactionRepository: CloudKitService.shared,
        appCategorizationRepository: CloudKitService.shared
    )

    public enum RedemptionResult {
        case success(redemptionID: String)
        case insufficientPoints(required: Int, available: Int)
        case invalidApp
        case conversionRateNotSet
        case systemError(String)
    }

    public enum ValidationResult {
        case valid
        case insufficientPoints(required: Int, available: Int)
        case rewardInactive
        case invalidConversionRate
        case appNotFound
        case parentSettingsRestricted
        case timeLimitExceeded
        case systemError(String)
        
        public var isValid: Bool {
            if case .valid = self {
                return true
            }
            return false
        }
    }

    private let childProfileRepository: SharedModels.ChildProfileRepository
    private let pointToTimeRedemptionRepository: SharedModels.PointToTimeRedemptionRepository
    private let pointTransactionRepository: SharedModels.PointTransactionRepository
    private let appCategorizationRepository: SharedModels.AppCategorizationRepository

    // Default conversion rate: 10 points = 1 minute
    private let defaultPointsPerMinute: Double = 10.0

    public init(childProfileRepository: SharedModels.ChildProfileRepository,
                pointToTimeRedemptionRepository: SharedModels.PointToTimeRedemptionRepository,
                pointTransactionRepository: SharedModels.PointTransactionRepository,
                appCategorizationRepository: SharedModels.AppCategorizationRepository) {
        self.childProfileRepository = childProfileRepository
        self.pointToTimeRedemptionRepository = pointToTimeRedemptionRepository
        self.pointTransactionRepository = pointTransactionRepository
        self.appCategorizationRepository = appCategorizationRepository
    }

    /// Validates a point-to-time conversion before processing
    public func validateRedemption(
        childID: String,
        appCategorizationID: String,
        pointsToSpend: Int
    ) async throws -> ValidationResult {
        // Check if child exists and has sufficient points
        guard let childProfile = try await childProfileRepository.fetchChild(id: childID) else {
            return .systemError("Child profile not found")
        }

        if childProfile.pointBalance < pointsToSpend {
            return .insufficientPoints(required: pointsToSpend, available: childProfile.pointBalance)
        }

        // Check if app categorization exists
        guard let appCategorization = try await appCategorizationRepository.fetchAppCategorization(id: appCategorizationID) else {
            return .appNotFound
        }

        // Validate conversion rate
        let conversionRate = getConversionRate(for: appCategorization)
        if conversionRate <= 0 {
            return .invalidConversionRate
        }

        // Check daily time limits and parent settings
        let timeMinutes = calculateTimeMinutes(points: pointsToSpend, conversionRate: conversionRate)
        if let validationError = try await validateTimeAllocation(childID: childID, timeMinutes: timeMinutes) {
            return validationError
        }

        return .valid
    }

    /// Converts points to screen time for a specific reward app
    public func redeemPointsForScreenTime(
        childID: String,
        appCategorizationID: String,
        pointsToSpend: Int
    ) async throws -> RedemptionResult {
        // Validate the redemption first
        let validationResult = try await validateRedemption(
            childID: childID,
            appCategorizationID: appCategorizationID,
            pointsToSpend: pointsToSpend
        )

        switch validationResult {
        case .valid:
            break // Continue with redemption
        case .insufficientPoints(let required, let available):
            return .insufficientPoints(required: required, available: available)
        case .invalidConversionRate:
            return .conversionRateNotSet
        case .appNotFound:
            return .invalidApp
        case .parentSettingsRestricted, .timeLimitExceeded:
            return .systemError("Time allocation restricted by parent settings")
        case .systemError(let message):
            return .systemError(message)
        case .rewardInactive:
            return .invalidApp
        }

        // Get app categorization for conversion rate
        guard let appCategorization = try await appCategorizationRepository.fetchAppCategorization(id: appCategorizationID) else {
            return .invalidApp
        }

        let conversionRate = getConversionRate(for: appCategorization)
        let timeMinutes = calculateTimeMinutes(points: pointsToSpend, conversionRate: conversionRate)

        // Create redemption record
        let redemptionID = UUID().uuidString
        let redemption = PointToTimeRedemption(
            id: redemptionID,
            childProfileID: childID,
            appCategorizationID: appCategorizationID,
            pointsSpent: pointsToSpend,
            timeGrantedMinutes: timeMinutes,
            conversionRate: conversionRate,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 3600), // 24 hours from now
            timeUsedMinutes: 0,
            status: RedemptionStatus.active
        )

        // Save redemption record
        let _ = try await pointToTimeRedemptionRepository.createPointToTimeRedemption(redemption)

        // Create transaction record for point deduction
        let transaction = PointTransaction(
            id: UUID().uuidString,
            childProfileID: childID,
            points: -pointsToSpend,
            reason: "Redeemed \(pointsToSpend) points for \(timeMinutes) minutes of screen time",
            timestamp: Date()
        )
        let _ = try await pointTransactionRepository.createTransaction(transaction)

        // Update child's point balance
        let updatedChild = try await updateChildPointBalance(childID: childID, pointsDelta: -pointsToSpend)
        guard updatedChild != nil else {
            throw RedemptionError.balanceUpdateFailed
        }

        return .success(redemptionID: redemptionID)
    }

    /// Calculates the current conversion rate for a specific app categorization
    public func getConversionRate(for appCategorization: AppCategorization) -> Double {
        // For reward apps, use a fixed conversion rate
        // This could be enhanced to support parent-configurable rates
        return defaultPointsPerMinute
    }

    /// Calculates screen time minutes based on points and conversion rate
    public func calculateTimeMinutes(points: Int, conversionRate: Double) -> Int {
        return Int(Double(points) / conversionRate)
    }

    /// Calculates required points for a given amount of screen time
    public func calculateRequiredPoints(timeMinutes: Int, conversionRate: Double) -> Int {
        return Int(Double(timeMinutes) * conversionRate)
    }

    /// Fetches active redemptions for a child that haven't expired
    public func getActiveRedemptions(for childID: String) async throws -> [PointToTimeRedemption] {
        let allRedemptions = try await pointToTimeRedemptionRepository.fetchActivePointToTimeRedemptions(for: childID)
        let now = Date()

        return allRedemptions.filter { redemption in
            redemption.status == RedemptionStatus.active && redemption.expiresAt > now
        }
    }

    /// Updates the used time for a redemption (called by Family Controls when time is actually used)
    public func updateUsedTime(redemptionID: String, usedMinutes: Int) async throws {
        guard let redemption = try await pointToTimeRedemptionRepository.fetchPointToTimeRedemption(id: redemptionID) else {
            throw RedemptionError.redemptionNotFound
        }

        let updatedRedemption = PointToTimeRedemption(
            id: redemption.id,
            childProfileID: redemption.childProfileID,
            appCategorizationID: redemption.appCategorizationID,
            pointsSpent: redemption.pointsSpent,
            timeGrantedMinutes: redemption.timeGrantedMinutes,
            conversionRate: redemption.conversionRate,
            redeemedAt: redemption.redeemedAt,
            expiresAt: redemption.expiresAt,
            timeUsedMinutes: usedMinutes,
            status: usedMinutes >= redemption.timeGrantedMinutes ? .used : redemption.status
        )

        let _ = try await pointToTimeRedemptionRepository.updatePointToTimeRedemption(updatedRedemption)
    }

    // MARK: - Private Methods

    private func validateTimeAllocation(childID: String, timeMinutes: Int) async throws -> ValidationResult? {
        // Get active redemptions to check total allocated time
        let activeRedemptions = try await getActiveRedemptions(for: childID)
        let totalActiveMinutes = activeRedemptions.reduce(0) { $0 + ($1.timeGrantedMinutes - $1.timeUsedMinutes) }

        // Check if adding this redemption would exceed reasonable limits
        // This is a basic implementation - could be enhanced with parent-configurable limits
        let maxDailyRedemptionMinutes = 180 // 3 hours max per day
        if totalActiveMinutes + timeMinutes > maxDailyRedemptionMinutes {
            return .timeLimitExceeded
        }

        return nil
    }

    private func updateChildPointBalance(childID: String, pointsDelta: Int) async throws -> ChildProfile? {
        guard let currentChild = try await childProfileRepository.fetchChild(id: childID) else {
            return nil
        }

        let updatedChild = ChildProfile(
            id: currentChild.id,
            familyID: currentChild.familyID,
            name: currentChild.name,
            avatarAssetURL: currentChild.avatarAssetURL,
            birthDate: currentChild.birthDate,
            pointBalance: currentChild.pointBalance + pointsDelta,
            totalPointsEarned: currentChild.totalPointsEarned,
            deviceID: currentChild.deviceID,
            cloudKitZoneID: currentChild.cloudKitZoneID,
            createdAt: currentChild.createdAt,
            ageVerified: currentChild.ageVerified,
            verificationMethod: currentChild.verificationMethod,
            dataRetentionPeriod: currentChild.dataRetentionPeriod
        )

        return try await childProfileRepository.updateChild(updatedChild)
    }
}

// MARK: - Error Types

public enum RedemptionError: Error, LocalizedError {
    case redemptionNotFound
    case balanceUpdateFailed
    case invalidParameters

    public var errorDescription: String? {
        switch self {
        case .redemptionNotFound:
            return "Redemption record not found"
        case .balanceUpdateFailed:
            return "Failed to update child's point balance"
        case .invalidParameters:
            return "Invalid parameters provided"
        }
    }
}

// MARK: - ValidationResult Extension

@available(iOS 15.0, macOS 12.0, *)
extension PointRedemptionService.ValidationResult {
    public var errorMessage: String {
        switch self {
        case .valid:
            return "Validation passed"
        case .insufficientPoints(let required, let available):
            return "Insufficient points. Required: \(required), Available: \(available)"
        case .invalidConversionRate:
            return "Invalid conversion rate configured"
        case .appNotFound:
            return "App categorization not found"
        case .parentSettingsRestricted:
            return "Blocked by parent settings"
        case .timeLimitExceeded:
            return "Would exceed daily time limits"
        case .systemError(let message):
            return "System error: \(message)"
        case .rewardInactive:
            return "Reward is currently inactive"
        }
    }
}