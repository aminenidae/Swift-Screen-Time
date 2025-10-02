import Foundation
import Combine
import SharedModels

/// Service responsible for triggering paywall presentation at appropriate points
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class PaywallTriggerService: ObservableObject {

    // MARK: - Singleton

    public static let shared = PaywallTriggerService()

    // MARK: - Published Properties

    @Published public private(set) var shouldShowPaywall = false
    @Published public private(set) var paywallContext: PaywallContext?
    @Published public private(set) var isLoading = false

    // MARK: - Private Properties

    private let featureGateService = FeatureGateService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupObservers()
    }

    // MARK: - Public Methods

    /// Trigger paywall for child limit exceeded scenario
    /// - Parameters:
    ///   - familyID: The family ID
    ///   - currentChildCount: Current number of children
    /// - Returns: True if paywall should be shown
    public func triggerChildLimitPaywall(for familyID: String, currentChildCount: Int) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let accessResult = await featureGateService.canAddChildProfile(for: familyID, currentChildCount: currentChildCount)

        switch accessResult {
        case .denied(.tierLimitExceeded):
            await showPaywall(context: .childLimitExceeded(currentCount: currentChildCount))
            return true
        case .denied(.noSubscription):
            await showPaywall(context: .noSubscription)
            return true
        case .denied(.subscriptionExpired):
            await showPaywall(context: .subscriptionExpired)
            return true
        case .allowed, .trial:
            return false
        case .denied(.validationError):
            return false
        }
    }

    /// Trigger paywall for premium analytics access
    /// - Parameter familyID: The family ID
    /// - Returns: True if paywall should be shown
    public func triggerAnalyticsPaywall(for familyID: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let accessResult = await featureGateService.checkFeatureAccess(.advancedAnalytics, for: familyID)

        switch accessResult {
        case .denied(.noSubscription):
            await showPaywall(context: .premiumAnalytics)
            return true
        case .denied(.subscriptionExpired):
            await showPaywall(context: .subscriptionExpired)
            return true
        case .allowed, .trial:
            return false
        case .denied(.tierLimitExceeded), .denied(.validationError):
            return false
        }
    }

    /// Trigger paywall for export reports feature
    /// - Parameter familyID: The family ID
    /// - Returns: True if paywall should be shown
    public func triggerExportReportsPaywall(for familyID: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let accessResult = await featureGateService.checkFeatureAccess(.exportReports, for: familyID)

        switch accessResult {
        case .denied(.noSubscription):
            await showPaywall(context: .exportReports)
            return true
        case .denied(.subscriptionExpired):
            await showPaywall(context: .subscriptionExpired)
            return true
        case .allowed, .trial:
            return false
        case .denied(.tierLimitExceeded), .denied(.validationError):
            return false
        }
    }

    /// Trigger paywall for trial expiration conversion
    /// - Parameter familyID: The family ID
    /// - Returns: True if paywall should be shown
    public func triggerTrialExpirationPaywall(for familyID: String) async -> Bool {
        await showPaywall(context: .trialExpiration)
        return true
    }

    /// Trigger paywall for lapsed subscription re-activation
    /// - Parameter familyID: The family ID
    /// - Returns: True if paywall should be shown
    public func triggerReSubscribePaywall(for familyID: String) async -> Bool {
        await showPaywall(context: .reSubscribe)
        return true
    }

    /// Trigger paywall for multi-parent invitations feature
    /// - Parameter familyID: The family ID
    /// - Returns: True if paywall should be shown
    public func triggerMultiParentInvitationsPaywall(for familyID: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let accessResult = await featureGateService.checkFeatureAccess(.multiParentInvitations, for: familyID)

        switch accessResult {
        case .denied(.noSubscription):
            await showPaywall(context: .multiParentInvitations)
            return true
        case .denied(.subscriptionExpired):
            await showPaywall(context: .subscriptionExpired)
            return true
        case .allowed, .trial:
            return false
        case .denied(.tierLimitExceeded), .denied(.validationError):
            return false
        }
    }

    /// Dismiss the current paywall
    public func dismissPaywall() {
        shouldShowPaywall = false
        paywallContext = nil
    }

    /// Check if feature access should trigger paywall and handle automatically
    /// - Parameters:
    ///   - feature: The feature being accessed
    ///   - familyID: The family ID
    /// - Returns: True if access is allowed, false if paywall was triggered
    public func checkFeatureAccessAndTriggerPaywall(_ feature: Feature, for familyID: String) async -> Bool {
        let accessResult = await featureGateService.checkFeatureAccess(feature, for: familyID)

        switch accessResult {
        case .allowed, .trial:
            return true
        case .denied(let reason):
            let context = paywallContext(for: feature, deniedReason: reason)
            await showPaywall(context: context)
            return false
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observer for automatic paywall dismissal when subscription becomes active
        featureGateService.$hasAccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasAccess in
                if hasAccess && self?.shouldShowPaywall == true {
                    self?.dismissPaywall()
                }
            }
            .store(in: &cancellables)
    }

    private func showPaywall(context: PaywallContext) async {
        paywallContext = context
        shouldShowPaywall = true
    }

    private func paywallContext(for feature: Feature, deniedReason: DeniedReason) -> PaywallContext {
        switch feature {
        case .childProfileCreation:
            switch deniedReason {
            case .tierLimitExceeded:
                return .childLimitExceeded(currentCount: 0) // Would need actual count
            case .noSubscription:
                return .noSubscription
            case .subscriptionExpired:
                return .subscriptionExpired
            case .validationError:
                return .noSubscription
            }
        case .advancedAnalytics:
            return .premiumAnalytics
        case .exportReports:
            return .exportReports
        case .multiParentInvitations:
            return .multiParentInvitations
        case .fullAccess:
            switch deniedReason {
            case .subscriptionExpired:
                return .subscriptionExpired
            default:
                return .noSubscription
            }
        }
    }
}

// MARK: - Supporting Types

/// Context for paywall presentation with specific messaging and CTAs
public enum PaywallContext: Equatable {
    case childLimitExceeded(currentCount: Int)
    case premiumAnalytics
    case exportReports
    case multiParentInvitations
    case trialExpiration
    case subscriptionExpired
    case reSubscribe
    case noSubscription

    public var title: String {
        switch self {
        case .childLimitExceeded:
            return "Add More Children"
        case .premiumAnalytics:
            return "Unlock Advanced Analytics"
        case .exportReports:
            return "Export Your Reports"
        case .multiParentInvitations:
            return "Invite Multiple Parents"
        case .trialExpiration:
            return "Your Trial is Ending"
        case .subscriptionExpired:
            return "Subscription Expired"
        case .reSubscribe:
            return "Welcome Back!"
        case .noSubscription:
            return "Unlock Premium Features"
        }
    }

    public var message: String {
        switch self {
        case .childLimitExceeded(let count):
            return "You currently have \(count) child profiles. Upgrade to add more children and unlock unlimited family members."
        case .premiumAnalytics:
            return "Get detailed insights into your family's screen time patterns with advanced analytics and custom reports."
        case .exportReports:
            return "Export your family's screen time reports to PDF or CSV format for sharing or record keeping."
        case .multiParentInvitations:
            return "Invite multiple parents to manage your family's screen time together with shared controls."
        case .trialExpiration:
            return "Your free trial is ending soon. Subscribe now to continue enjoying all premium features."
        case .subscriptionExpired:
            return "Your subscription has expired. Renew now to regain access to all premium features."
        case .reSubscribe:
            return "Reactivate your subscription to continue managing your family's screen time with premium features."
        case .noSubscription:
            return "Start your free trial to access advanced parental controls and family management features."
        }
    }

    public var primaryButtonTitle: String {
        switch self {
        case .childLimitExceeded:
            return "Upgrade Plan"
        case .premiumAnalytics, .exportReports, .multiParentInvitations:
            return "Unlock with Premium"
        case .trialExpiration:
            return "Subscribe Now"
        case .subscriptionExpired, .reSubscribe:
            return "Renew Subscription"
        case .noSubscription:
            return "Start Free Trial"
        }
    }

    public var secondaryButtonTitle: String {
        switch self {
        case .trialExpiration:
            return "Remind Me Later"
        default:
            return "Maybe Later"
        }
    }
}