import Foundation
import StoreKit
import SharedModels

/// Service responsible for determining trial eligibility for families
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class TrialEligibilityService: ObservableObject {
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: AppError?

    private let familyRepository: FamilyRepository

    public init(familyRepository: FamilyRepository) {
        self.familyRepository = familyRepository
    }

    /// Check if a family is eligible for a free trial
    /// - Parameter familyID: The family ID to check eligibility for
    /// - Returns: Trial eligibility result with reason codes
    public func checkTrialEligibility(for familyID: String) async -> TrialEligibilityResult {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            // Check CloudKit Family record for trial usage
            guard let family = try await familyRepository.fetchFamily(id: familyID) else {
                return .ineligible(reason: .familyNotFound)
            }

            // Check if family has already used trial
            if family.subscriptionMetadata?.hasUsedTrial == true {
                return .ineligible(reason: .trialPreviouslyUsed)
            }

            // Check if family currently has active subscription
            if family.subscriptionMetadata?.isActive == true {
                return .ineligible(reason: .activeSubscription)
            }

            // Check StoreKit 2 for previous trial usage across all products
            let hasStoreKitTrial = await checkStoreKitTrialEligibility()
            if hasStoreKitTrial {
                return .ineligible(reason: .storeKitTrialUsed)
            }

            return .eligible

        } catch {
            await MainActor.run {
                self.error = error as? AppError ?? .unknownError(error.localizedDescription)
            }
            return .ineligible(reason: .systemError)
        }
    }

    /// Activate trial for a family
    /// - Parameter familyID: The family ID to activate trial for
    /// - Returns: Trial activation result
    public func activateTrial(for familyID: String) async -> TrialActivationResult {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            // Check eligibility first
            let eligibilityResult = await checkTrialEligibility(for: familyID)
            guard case .eligible = eligibilityResult else {
                return .failed(reason: .notEligible)
            }

            // Fetch family record
            guard var family = try await familyRepository.fetchFamily(id: familyID) else {
                return .failed(reason: .familyNotFound)
            }

            // Calculate trial dates
            let trialStartDate = Date()
            let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: trialStartDate)!

            // Update family with trial metadata
            if family.subscriptionMetadata == nil {
                family.subscriptionMetadata = SubscriptionMetadata()
            }

            family.subscriptionMetadata?.trialStartDate = trialStartDate
            family.subscriptionMetadata?.trialEndDate = trialEndDate
            family.subscriptionMetadata?.hasUsedTrial = true
            family.subscriptionMetadata?.isActive = true

            // Save updated family record
            let updatedFamily = try await familyRepository.updateFamily(family)

            return .success(
                trialStartDate: trialStartDate,
                trialEndDate: trialEndDate,
                family: updatedFamily
            )

        } catch {
            await MainActor.run {
                self.error = error as? AppError ?? .unknownError(error.localizedDescription)
            }
            return .failed(reason: .systemError)
        }
    }

    /// Get current trial status for a family
    /// - Parameter familyID: The family ID to check
    /// - Returns: Current trial status
    public func getTrialStatus(for familyID: String) async -> TrialStatus {
        do {
            guard let family = try await familyRepository.fetchFamily(id: familyID),
                  let metadata = family.subscriptionMetadata else {
                return .notStarted
            }

            guard let trialStartDate = metadata.trialStartDate,
                  let trialEndDate = metadata.trialEndDate else {
                return .notStarted
            }

            let now = Date()

            if now < trialStartDate {
                return .notStarted
            } else if now >= trialStartDate && now <= trialEndDate {
                let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: trialEndDate).day ?? 0
                return .active(daysRemaining: max(0, daysRemaining))
            } else {
                return .expired
            }

        } catch {
            await MainActor.run {
                self.error = error as? AppError ?? .unknownError(error.localizedDescription)
            }
            return .notStarted
        }
    }

    // MARK: - Private Methods

    private func checkStoreKitTrialEligibility() async -> Bool {
        // Check if any of our subscription products have been trialed before
        for productID in ProductIdentifiers.allProducts {
            let eligibility = await Product.SubscriptionInfo.isEligibleForIntroOffer(for: productID)
            // If not eligible for intro offer, it means they've used it before
            if !eligibility {
                return true
            }
        }
        return false
    }
}

// MARK: - Supporting Types

public enum TrialEligibilityResult {
    case eligible
    case ineligible(reason: IneligibilityReason)

    public enum IneligibilityReason {
        case familyNotFound
        case trialPreviouslyUsed
        case activeSubscription
        case storeKitTrialUsed
        case systemError
    }
}

public enum TrialActivationResult {
    case success(trialStartDate: Date, trialEndDate: Date, family: Family)
    case failed(reason: FailureReason)

    public enum FailureReason {
        case notEligible
        case familyNotFound
        case systemError
    }
}

public enum TrialStatus {
    case notStarted
    case active(daysRemaining: Int)
    case expired
}