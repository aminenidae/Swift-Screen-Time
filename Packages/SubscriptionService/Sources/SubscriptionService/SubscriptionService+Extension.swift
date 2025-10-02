import Foundation
import SharedModels

// MARK: - SubscriptionService Public Interface

@available(iOS 15.0, macOS 12.0, *)
extension SubscriptionService {
    /// Get products organized by subscription tier (number of children)
    public var productsByTier: [Int: [SubscriptionProduct]] {
        var tiers: [Int: [SubscriptionProduct]] = [:]

        for product in availableProducts {
            let childCount = extractChildCount(from: product.id)
            if tiers[childCount] == nil {
                tiers[childCount] = []
            }
            tiers[childCount]?.append(product)
        }

        return tiers
    }

    /// Get monthly products
    public var monthlyProducts: [SubscriptionProduct] {
        availableProducts.filter { product in
            product.subscriptionPeriod.unit == .month && product.subscriptionPeriod.value == 1
        }
    }

    /// Get yearly products
    public var yearlyProducts: [SubscriptionProduct] {
        availableProducts.filter { product in
            product.subscriptionPeriod.unit == .year && product.subscriptionPeriod.value == 1
        }
    }

    /// Get the best value product (yearly pricing)
    public var bestValueProducts: [SubscriptionProduct] {
        yearlyProducts
    }

    /// Calculate savings percentage for yearly vs monthly
    public func calculateYearlySavings(monthlyProduct: SubscriptionProduct, yearlyProduct: SubscriptionProduct) -> Int? {
        guard monthlyProduct.subscriptionPeriod.unit == .month,
              yearlyProduct.subscriptionPeriod.unit == .year else {
            return nil
        }

        let monthlyAnnualCost = monthlyProduct.price * 12
        let yearlyCost = yearlyProduct.price
        let savings = monthlyAnnualCost - yearlyCost
        let savingsPercentage = (savings / monthlyAnnualCost) * 100

        return Int(NSDecimalNumber(decimal: savingsPercentage).doubleValue.rounded())
    }

    private func extractChildCount(from productId: String) -> Int {
        if productId.contains("1child") {
            return 1
        } else if productId.contains("2child") {
            return 2
        }
        return 1 // Default to 1 child
    }

    /// Create a trial eligibility service instance
    public func createTrialEligibilityService(familyRepository: FamilyRepository) -> TrialEligibilityService {
        return TrialEligibilityService(familyRepository: familyRepository)
    }

    /// Check if family is eligible for trial
    public func checkTrialEligibility(for familyID: String, using familyRepository: FamilyRepository) async -> TrialEligibilityResult {
        let trialService = createTrialEligibilityService(familyRepository: familyRepository)
        return await trialService.checkTrialEligibility(for: familyID)
    }

    /// Activate trial for family
    public func activateTrial(for familyID: String, using familyRepository: FamilyRepository) async -> TrialActivationResult {
        let trialService = createTrialEligibilityService(familyRepository: familyRepository)
        return await trialService.activateTrial(for: familyID)
    }
}