import Foundation
import SharedModels

/// Service responsible for handling trial expiration and graceful feature lockout
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class TrialExpirationService: ObservableObject {
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: AppError?

    private let familyRepository: FamilyRepository
    private let trialService: TrialEligibilityService
    private let featureGateService: FeatureGateService

    public init(familyRepository: FamilyRepository) {
        self.familyRepository = familyRepository
        self.trialService = TrialEligibilityService(familyRepository: familyRepository)
        self.featureGateService = FeatureGateService.shared
    }

    /// Check and handle trial expiration for a family
    /// - Parameter familyID: The family ID to check
    /// - Returns: Expiration handling result
    public func handleTrialExpiration(for familyID: String) async -> TrialExpirationResult {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Get current trial status
        let trialStatus = await trialService.getTrialStatus(for: familyID)

        switch trialStatus {
        case .notStarted:
            return .noTrialFound

        case .active(let daysRemaining):
            if daysRemaining == 0 {
                // Trial expires today - initiate graceful expiration
                return await performGracefulExpiration(for: familyID)
            } else {
                return .stillActive(daysRemaining: daysRemaining)
            }

        case .expired:
            // Trial already expired - ensure proper lockout
            return await ensureFeatureLockout(for: familyID)
        }
    }

    /// Perform graceful trial expiration
    /// - Parameter familyID: The family ID
    /// - Returns: Expiration result
    private func performGracefulExpiration(for familyID: String) async -> TrialExpirationResult {
        do {
            // Update family metadata to mark trial as expired
            guard var family = try await familyRepository.fetchFamily(id: familyID) else {
                return .error(message: "Family not found")
            }

            // Ensure trial is marked as inactive
            if family.subscriptionMetadata != nil {
                family.subscriptionMetadata?.isActive = false
            }

            // Save updated family
            _ = try await familyRepository.updateFamily(family)

            return .expiredSuccessfully(
                familyID: familyID,
                expiredAt: Date(),
                dataPreserved: true
            )

        } catch {
            await updateError(error as? AppError ?? .systemError(error.localizedDescription))
            return .error(message: "Failed to process trial expiration")
        }
    }

    /// Ensure proper feature lockout for expired trial
    /// - Parameter familyID: The family ID
    /// - Returns: Expiration result
    private func ensureFeatureLockout(for familyID: String) async -> TrialExpirationResult {
        // Verify that features are properly locked out
        let hasAccess = await featureGateService.checkAccess(for: familyID)

        if hasAccess {
            // This shouldn't happen - log the issue and force lockout
            await updateError(.systemError("Trial is expired but user still has access"))
            return .error(message: "Inconsistent access state detected")
        }

        return .alreadyExpired(
            familyID: familyID,
            featuresLocked: true
        )
    }

    /// Get trial expiration information
    /// - Parameter familyID: The family ID
    /// - Returns: Expiration information
    public func getExpirationInfo(for familyID: String) async -> TrialExpirationInfo? {
        do {
            guard let family = try await familyRepository.fetchFamily(id: familyID),
                  let metadata = family.subscriptionMetadata,
                  let trialEndDate = metadata.trialEndDate else {
                return nil
            }

            let now = Date()
            let isExpired = now > trialEndDate
            let daysUntilExpiration = isExpired ? 0 : Calendar.current.dateComponents([.day], from: now, to: trialEndDate).day ?? 0

            return TrialExpirationInfo(
                familyID: familyID,
                trialEndDate: trialEndDate,
                isExpired: isExpired,
                daysUntilExpiration: daysUntilExpiration,
                hasUsedTrial: metadata.hasUsedTrial,
                canStartNewTrial: !metadata.hasUsedTrial
            )

        } catch {
            await updateError(error as? AppError ?? .systemError(error.localizedDescription))
            return nil
        }
    }

    /// Present paywall for expired trial users
    /// - Parameter familyID: The family ID
    /// - Returns: Paywall presentation result
    public func shouldPresentPaywall(for familyID: String) async -> PaywallPresentationReason? {
        let trialStatus = await trialService.getTrialStatus(for: familyID)

        switch trialStatus {
        case .expired:
            return .trialExpired

        case .active(let daysRemaining):
            if daysRemaining <= 1 {
                return .trialEndingSoon(daysRemaining: daysRemaining)
            }
            return nil

        case .notStarted:
            let eligibility = await trialService.checkTrialEligibility(for: familyID)
            switch eligibility {
            case .eligible:
                return .trialEligible
            case .ineligible:
                return .requiresSubscription
            }
        }
    }

    /// Check if family data should be preserved during expiration
    /// - Parameter familyID: The family ID
    /// - Returns: True if data should be preserved
    public func shouldPreserveData(for familyID: String) async -> Bool {
        // Always preserve trial data - never delete user data on expiration
        return true
    }

    /// Get feature lockout status
    /// - Parameter familyID: The family ID
    /// - Returns: Lockout status information
    public func getFeatureLockoutStatus(for familyID: String) async -> FeatureLockoutStatus {
        let hasAccess = await featureGateService.checkAccess(for: familyID)
        let trialStatus = await trialService.getTrialStatus(for: familyID)

        return FeatureLockoutStatus(
            familyID: familyID,
            hasAccess: hasAccess,
            trialStatus: trialStatus,
            lockedFeatures: hasAccess ? [] : getAllPremiumFeatures(),
            accessStatusMessage: await featureGateService.getAccessStatusMessage(for: familyID)
        )
    }

    // MARK: - Private Methods

    private func updateError(_ error: AppError) async {
        await MainActor.run {
            self.error = error
        }
    }

    private func getAllPremiumFeatures() -> [PremiumFeature] {
        return [
            .unlimitedFamilyMembers,
            .advancedAnalytics,
            .smartNotifications,
            .enhancedParentalControls,
            .cloudSync,
            .prioritySupport
        ]
    }
}

// MARK: - Supporting Types

public enum TrialExpirationResult {
    case noTrialFound
    case stillActive(daysRemaining: Int)
    case expiredSuccessfully(familyID: String, expiredAt: Date, dataPreserved: Bool)
    case alreadyExpired(familyID: String, featuresLocked: Bool)
    case error(message: String)
}

public struct TrialExpirationInfo {
    public let familyID: String
    public let trialEndDate: Date
    public let isExpired: Bool
    public let daysUntilExpiration: Int
    public let hasUsedTrial: Bool
    public let canStartNewTrial: Bool

    public init(
        familyID: String,
        trialEndDate: Date,
        isExpired: Bool,
        daysUntilExpiration: Int,
        hasUsedTrial: Bool,
        canStartNewTrial: Bool
    ) {
        self.familyID = familyID
        self.trialEndDate = trialEndDate
        self.isExpired = isExpired
        self.daysUntilExpiration = daysUntilExpiration
        self.hasUsedTrial = hasUsedTrial
        self.canStartNewTrial = canStartNewTrial
    }
}

public enum PaywallPresentationReason {
    case trialExpired
    case trialEndingSoon(daysRemaining: Int)
    case trialEligible
    case requiresSubscription
}

public struct FeatureLockoutStatus {
    public let familyID: String
    public let hasAccess: Bool
    public let trialStatus: TrialStatus
    public let lockedFeatures: [PremiumFeature]
    public let accessStatusMessage: String

    public init(
        familyID: String,
        hasAccess: Bool,
        trialStatus: TrialStatus,
        lockedFeatures: [PremiumFeature],
        accessStatusMessage: String
    ) {
        self.familyID = familyID
        self.hasAccess = hasAccess
        self.trialStatus = trialStatus
        self.lockedFeatures = lockedFeatures
        self.accessStatusMessage = accessStatusMessage
    }
}

// MARK: - Background Task Integration

@available(iOS 15.0, macOS 12.0, *)
extension TrialExpirationService {
    /// Background task to check and handle trial expirations
    /// This should be called by a background task scheduler
    public func performBackgroundExpirationCheck() async {
        // This would be called by BackgroundTasks framework
        // Implementation would check all families and handle expirations
    }

    /// Check if any trials are expiring soon and need attention
    /// - Parameter withinDays: Number of days to look ahead
    /// - Returns: List of families with expiring trials
    public func getFamiliesWithExpiringTrials(withinDays: Int = 1) async -> [String] {
        // Implementation would query families with trials expiring within specified days
        // This is a placeholder for the background task integration
        return []
    }
}