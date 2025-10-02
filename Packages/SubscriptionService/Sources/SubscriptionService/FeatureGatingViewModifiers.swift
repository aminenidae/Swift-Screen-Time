import SwiftUI
import SharedModels

// MARK: - Feature Gating View Modifiers

@available(iOS 15.0, macOS 12.0, *)
public struct FeatureGatedViewModifier: ViewModifier {
    let feature: Feature
    let familyID: String
    let onPaywallTrigger: () -> Void

    @StateObject private var featureGateService = FeatureGateService.shared
    @StateObject private var paywallTriggerService = PaywallTriggerService.shared
    @State private var hasAccess = false
    @State private var isChecking = false

    public func body(content: Content) -> some View {
        content
            .disabled(!hasAccess)
            .overlay {
                if !hasAccess && !isChecking {
                    PremiumFeatureLockOverlay()
                        .onTapGesture {
                            Task {
                                let shouldShowPaywall = await paywallTriggerService.checkFeatureAccessAndTriggerPaywall(feature, for: familyID)
                                if !shouldShowPaywall {
                                    onPaywallTrigger()
                                }
                            }
                        }
                }
            }
            .task {
                await checkFeatureAccess()
            }
    }

    private func checkFeatureAccess() async {
        isChecking = true
        let result = await featureGateService.checkFeatureAccess(feature, for: familyID)
        await MainActor.run {
            hasAccess = (result == .allowed || result == .trial)
            isChecking = false
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
public struct PremiumBadgeModifier: ViewModifier {
    let feature: Feature
    let familyID: String

    @StateObject private var featureGateService = FeatureGateService.shared
    @State private var hasAccess = false

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if !hasAccess {
                    PremiumBadge()
                        .offset(x: 8, y: -8)
                }
            }
            .task {
                let result = await featureGateService.checkFeatureAccess(feature, for: familyID)
                await MainActor.run {
                    hasAccess = (result == .allowed || result == .trial)
                }
            }
    }
}

// MARK: - UI Components

@available(iOS 15.0, macOS 12.0, *)
public struct PremiumFeatureLockOverlay: View {
    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.white)

                Text("Premium Feature")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text("Tap to unlock")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
public struct PremiumBadge: View {
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            Text("Premium")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
            Capsule()
                .fill(Color.orange)
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
public struct UpgradePromptButton: View {
    let feature: Feature
    let familyID: String
    let onUpgrade: () -> Void

    @StateObject private var paywallTriggerService = PaywallTriggerService.shared

    public init(feature: Feature, familyID: String, onUpgrade: @escaping () -> Void) {
        self.feature = feature
        self.familyID = familyID
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        Button(action: {
            Task {
                let shouldShowPaywall = await paywallTriggerService.checkFeatureAccessAndTriggerPaywall(feature, for: familyID)
                if !shouldShowPaywall {
                    onUpgrade()
                }
            }
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Unlock with Premium")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
public struct TrialCountdownBanner: View {
    let daysRemaining: Int
    let onSubscribe: () -> Void

    public init(daysRemaining: Int, onSubscribe: @escaping () -> Void) {
        self.daysRemaining = daysRemaining
        self.onSubscribe = onSubscribe
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Trial")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)

                Text("\(daysRemaining) days remaining")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Subscribe to continue enjoying premium features")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Subscribe") {
                onSubscribe()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - View Extensions

@available(iOS 15.0, macOS 12.0, *)
public extension View {
    /// Apply feature gating to this view
    /// - Parameters:
    ///   - feature: The feature to gate
    ///   - familyID: The family ID to check access for
    ///   - onPaywallTrigger: Callback when paywall should be shown
    func featureGated(_ feature: Feature, for familyID: String, onPaywallTrigger: @escaping () -> Void = {}) -> some View {
        modifier(FeatureGatedViewModifier(feature: feature, familyID: familyID, onPaywallTrigger: onPaywallTrigger))
    }

    /// Add a premium badge to indicate this is a premium feature
    /// - Parameters:
    ///   - feature: The feature to check access for
    ///   - familyID: The family ID to check access for
    func premiumBadge(for feature: Feature, familyID: String) -> some View {
        modifier(PremiumBadgeModifier(feature: feature, familyID: familyID))
    }
}