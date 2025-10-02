import Foundation
import Combine
import SharedModels
import CloudKitService

/// Service responsible for controlling access to premium features based on subscription and trial status
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class FeatureGateService: ObservableObject {

    // MARK: - Singleton

    public static let shared = FeatureGateService()

    // MARK: - Published Properties

    @Published public private(set) var hasAccess = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: AppError?

    // MARK: - Private Properties

    private let entitlementValidationService: EntitlementValidationService
    private let childProfileRepository: ChildProfileRepository
    private var cache: [String: CachedFeatureAccess] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Initialize with dependencies from existing services
        let entitlementRepository = CloudKitSubscriptionEntitlementRepository()
        let fraudDetectionService = DefaultFraudDetectionService()
        let childProfileRepository = CloudKitService.shared

        self.entitlementValidationService = EntitlementValidationService(
            entitlementRepository: entitlementRepository,
            fraudDetectionService: fraudDetectionService
        )
        self.childProfileRepository = childProfileRepository

        setupSubscriptionStatusObserver()
    }

    /// Convenience initializer for testing with dependency injection
    public init(entitlementValidationService: EntitlementValidationService, childProfileRepository: ChildProfileRepository) {
        self.entitlementValidationService = entitlementValidationService
        self.childProfileRepository = childProfileRepository
        setupSubscriptionStatusObserver()
    }

    // MARK: - Public Methods

    /// Check feature access with detailed result information
    /// - Parameters:
    ///   - feature: The feature to check access for
    ///   - familyID: The family ID to check access for
    /// - Returns: FeatureAccessResult indicating allowed/denied/trial status
    public func checkFeatureAccess(_ feature: Feature, for familyID: String) async -> FeatureAccessResult {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Check cache first
        let cacheKey = "\(familyID)_\(feature.rawValue)"
        if let cachedResult = getCachedResult(for: cacheKey) {
            return cachedResult.result
        }

        do {
            let entitlement = try await entitlementValidationService.validateEntitlement(for: familyID)

            guard let entitlement = entitlement else {
                let result = FeatureAccessResult.denied(.noSubscription)
                cacheResult(result, for: cacheKey)
                await updateAccessStatus(false)
                return result
            }

            let result = evaluateFeatureAccess(feature, entitlement: entitlement, familyID: familyID)
            cacheResult(result, for: cacheKey)

            let hasAccess = result == .allowed
            await updateAccessStatus(hasAccess)

            return result

        } catch {
            let appError = error as? AppError ?? .unknownError(error.localizedDescription)
            await updateAccessStatus(false, error: appError)
            return .denied(.validationError)
        }
    }

    /// Legacy method for backward compatibility
    /// - Parameter familyID: The family ID to check access for
    /// - Returns: True if family has access (active subscription or trial)
    public func checkAccess(for familyID: String) async -> Bool {
        let result = await checkFeatureAccess(.fullAccess, for: familyID)
        return result == .allowed
    }

    /// Check access for specific premium features (legacy method)
    public func hasFeatureAccess(_ feature: PremiumFeature, for familyID: String) async -> Bool {
        // Map PremiumFeature to new Feature enum
        let newFeature: Feature
        switch feature {
        case .unlimitedFamilyMembers:
            newFeature = .childProfileCreation
        case .advancedAnalytics:
            newFeature = .advancedAnalytics
        default:
            newFeature = .fullAccess
        }

        let result = await checkFeatureAccess(newFeature, for: familyID)
        return result == .allowed
    }

    /// Refresh access status for a family
    public func refreshAccess(for familyID: String) async {
        clearCache(for: familyID)
        _ = await checkAccess(for: familyID)
    }

    /// Get feature access status for multiple features
    public func getFeatureAccessStatus(for familyID: String) async -> FeatureAccessStatus {
        let hasAccess = await checkAccess(for: familyID)

        if !hasAccess {
            return FeatureAccessStatus(
                unlimitedFamilyMembers: false,
                advancedAnalytics: false,
                smartNotifications: false,
                enhancedParentalControls: false,
                cloudSync: false,
                prioritySupport: false
            )
        }

        return FeatureAccessStatus(
            unlimitedFamilyMembers: true,
            advancedAnalytics: true,
            smartNotifications: true,
            enhancedParentalControls: true,
            cloudSync: true,
            prioritySupport: true
        )
    }


    /// Get user-friendly access status message
    public func getAccessStatusMessage(for familyID: String) async -> String {
        do {
            let entitlement = try await entitlementValidationService.validateEntitlement(for: familyID)

            guard let entitlement = entitlement else {
                return "No subscription found - Start your free trial to access premium features"
            }

            // Check trial status
            if entitlement.isInTrial {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: entitlement.expirationDate).day ?? 0
                return "Free trial active - \(daysRemaining) days remaining"
            }

            // Check active subscription
            if entitlement.isActive && entitlement.expirationDate > Date() {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Premium subscription (\(entitlement.subscriptionTier.displayName)) active until \(formatter.string(from: entitlement.expirationDate))"
            }

            // Check grace period
            if let gracePeriodExpiry = entitlement.gracePeriodExpiresAt, gracePeriodExpiry > Date() {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: gracePeriodExpiry).day ?? 0
                return "Subscription in grace period - \(daysRemaining) days remaining to resolve payment"
            }

            return "Subscription expired - Subscribe to continue using premium features"

        } catch {
            return "Unable to determine access status"
        }
    }

    /// Get trial days remaining for a family
    /// - Parameter familyID: The family ID to check
    /// - Returns: Number of days remaining in trial, or nil if not in trial
    public func getTrialDaysRemaining(for familyID: String) async -> Int? {
        do {
            let entitlement = try await entitlementValidationService.validateEntitlement(for: familyID)

            guard let entitlement = entitlement, entitlement.isInTrial else {
                return nil
            }

            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: entitlement.expirationDate).day ?? 0
            return max(0, daysRemaining)
        } catch {
            return nil
        }
    }

    // MARK: - Private Methods

    private func setupSubscriptionStatusObserver() {
        entitlementValidationService.$currentEntitlement
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entitlement in
                self?.cache.removeAll() // Clear cache when entitlement changes
            }
            .store(in: &cancellables)
    }

    private func evaluateFeatureAccess(_ feature: Feature, entitlement: SubscriptionEntitlement, familyID: String) -> FeatureAccessResult {
        // Trial users get full access to all features
        if entitlement.isInTrial {
            return .trial
        }

        // Expired subscription -> read-only access only
        if !entitlement.isActive || entitlement.expirationDate <= Date() {
            // Check if we're in grace period
            if let gracePeriodExpiry = entitlement.gracePeriodExpiresAt, gracePeriodExpiry > Date() {
                return .allowed // Grace period still allows access
            }

            return .denied(.subscriptionExpired)
        }

        // Feature-specific access rules
        switch feature {
        case .childProfileCreation:
            return evaluateChildProfileCreationAccess(entitlement: entitlement, familyID: familyID)
        case .advancedAnalytics:
            return .allowed // All subscription tiers get analytics
        case .exportReports:
            return .allowed // All subscription tiers get export
        case .multiParentInvitations:
            return .allowed // All subscription tiers get this feature
        case .fullAccess:
            return .allowed // General premium access
        }
    }

    private func evaluateChildProfileCreationAccess(entitlement: SubscriptionEntitlement, familyID: String) -> FeatureAccessResult {
        // For trial users, allow unlimited child profiles
        if entitlement.isInTrial {
            return .trial
        }

        // Get the current child count for this family
        let currentChildCount = getChildCount(for: familyID)

        // Check if the current child count exceeds the subscription tier limit
        let maxAllowed = entitlement.subscriptionTier.maxChildren

        if currentChildCount >= maxAllowed {
            return .denied(.tierLimitExceeded)
        }

        return .allowed
    }

    private func getChildCount(for familyID: String) -> Int {
        // This is a placeholder implementation
        // In a real implementation, we would fetch the actual child count from the repository
        // For example:
        // let children = try? await childProfileRepository.fetchChildren(for: familyID)
        // return children?.count ?? 0
        
        // For now, return 0 as a placeholder
        return 0
    }

    /// Check if family can add a child profile based on current count and subscription tier
    /// - Parameters:
    ///   - familyID: The family ID to check
    ///   - currentChildCount: The current number of child profiles
    /// - Returns: FeatureAccessResult indicating if child can be added
    public func canAddChildProfile(for familyID: String, currentChildCount: Int) async -> FeatureAccessResult {
        do {
            let entitlement = try await entitlementValidationService.validateEntitlement(for: familyID)

            guard let entitlement = entitlement else {
                return .denied(.noSubscription)
            }

            // Trial users get full access
            if entitlement.isInTrial {
                return .trial
            }

            // Expired subscription -> denied
            if !entitlement.isActive || entitlement.expirationDate <= Date() {
                // Check if we're in grace period
                if let gracePeriodExpiry = entitlement.gracePeriodExpiresAt, gracePeriodExpiry > Date() {
                    // Allow during grace period but with different tier logic
                    return evaluateChildCountAccess(entitlement: entitlement, currentChildCount: currentChildCount)
                }
                return .denied(.subscriptionExpired)
            }

            return evaluateChildCountAccess(entitlement: entitlement, currentChildCount: currentChildCount)

        } catch {
            return .denied(.validationError)
        }
    }

    private func evaluateChildCountAccess(entitlement: SubscriptionEntitlement, currentChildCount: Int) -> FeatureAccessResult {
        let maxAllowed = entitlement.subscriptionTier.maxChildren

        if currentChildCount >= maxAllowed {
            return .denied(.tierLimitExceeded)
        }

        return .allowed
    }

    private func cacheResult(_ result: FeatureAccessResult, for key: String) {
        cache[key] = CachedFeatureAccess(result: result, timestamp: Date())
    }

    private func getCachedResult(for key: String) -> CachedFeatureAccess? {
        guard let cached = cache[key] else { return nil }

        // Check if cache is still valid
        let timeSinceCache = Date().timeIntervalSince(cached.timestamp)
        if timeSinceCache < cacheValidityDuration {
            return cached
        }

        // Remove expired cache entry
        cache.removeValue(forKey: key)
        return nil
    }

    private func clearCache(for familyID: String) {
        cache = cache.filter { !$0.key.hasPrefix(familyID) }
    }

    private func updateAccessStatus(_ hasAccess: Bool, error: AppError? = nil) async {
        await MainActor.run {
            self.hasAccess = hasAccess
            self.error = error
        }
    }
}

// MARK: - Supporting Types

/// Result of feature access checking with detailed information
public enum FeatureAccessResult: Equatable {
    case allowed
    case trial
    case denied(DeniedReason)
}

/// Reasons why feature access is denied
public enum DeniedReason: Equatable {
    case noSubscription
    case subscriptionExpired
    case tierLimitExceeded
    case validationError
}

/// Features that can be gated based on subscription status
public enum Feature: String, CaseIterable {
    case childProfileCreation = "childProfileCreation"
    case advancedAnalytics = "advancedAnalytics"
    case exportReports = "exportReports"
    case multiParentInvitations = "multiParentInvitations"
    case fullAccess = "fullAccess"
}

/// Cached feature access result with timestamp
private struct CachedFeatureAccess {
    let result: FeatureAccessResult
    let timestamp: Date
}

/// Legacy premium feature enum for backward compatibility
public enum PremiumFeature {
    case unlimitedFamilyMembers
    case advancedAnalytics
    case smartNotifications
    case enhancedParentalControls
    case cloudSync
    case prioritySupport
}

/// Legacy feature access status for backward compatibility
public struct FeatureAccessStatus {
    public let unlimitedFamilyMembers: Bool
    public let advancedAnalytics: Bool
    public let smartNotifications: Bool
    public let enhancedParentalControls: Bool
    public let cloudSync: Bool
    public let prioritySupport: Bool

    public init(
        unlimitedFamilyMembers: Bool,
        advancedAnalytics: Bool,
        smartNotifications: Bool,
        enhancedParentalControls: Bool,
        cloudSync: Bool,
        prioritySupport: Bool
    ) {
        self.unlimitedFamilyMembers = unlimitedFamilyMembers
        self.advancedAnalytics = advancedAnalytics
        self.smartNotifications = smartNotifications
        self.enhancedParentalControls = enhancedParentalControls
        self.cloudSync = cloudSync
        self.prioritySupport = prioritySupport
    }
}

// MARK: - Extensions


/// Convenience extension for quick feature checks (backward compatibility)
@available(iOS 15.0, macOS 12.0, *)
public extension FeatureGateService {
    /// Check if family can add more members (premium feature)
    func canAddFamilyMember(for familyID: String, currentMemberCount: Int) async -> Bool {
        let result = await canAddChildProfile(for: familyID, currentChildCount: currentMemberCount)
        return result == .allowed || result == .trial
    }

    /// Check if family can access detailed analytics
    func canAccessAnalytics(for familyID: String) async -> Bool {
        return await hasFeatureAccess(.advancedAnalytics, for: familyID)
    }

    /// Check if family can use enhanced controls
    func canUseEnhancedControls(for familyID: String) async -> Bool {
        return await hasFeatureAccess(.enhancedParentalControls, for: familyID)
    }
}