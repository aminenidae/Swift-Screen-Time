import SwiftUI
import SubscriptionService
import SharedModels

// Type alias to avoid conflicts with StoreKit
typealias AppAppSubscriptionStatus = SharedModels.AppSubscriptionStatus

/// Subscription status indicator for showing throughout the app
@available(iOS 15.0, *)
struct AppSubscriptionStatusIndicator: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var subscriptionStatus: AppAppSubscriptionStatus = .expired
    @State private var showPaywall = false

    var body: some View {
        Group {
            switch subscriptionStatus {
            case .trial:
                TrialStatusView()
            case .expired, .revoked:
                ExpiredStatusView()
            case .gracePeriod:
                GracePeriodStatusView()
            case .active:
                EmptyView() // No indicator needed for active subscriptions
            }
        }
        .task {
            await loadAppSubscriptionStatus()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                Task {
                    await loadAppSubscriptionStatus()
                }
            }
        }
    }

    @ViewBuilder
    private func TrialStatusView() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "star.circle")
                .foregroundColor(.blue)

            Text("Premium Trial")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            Button("Upgrade") {
                showPaywall = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }

    @ViewBuilder
    private func ExpiredStatusView() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)

            Text("Premium Expired")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            Button("Upgrade") {
                showPaywall = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
        )
    }

    @ViewBuilder
    private func GracePeriodStatusView() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .foregroundColor(.red)

            Text("Payment Issue")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            Button("Fix") {
                showPaywall = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.1))
        )
    }

    private func loadAppSubscriptionStatus() async {
        // In a real app, this would check the actual subscription status
        // For now, we'll simulate having a trial subscription
        subscriptionStatus = .trial
    }
}

/// Compact subscription status indicator for navigation bars
@available(iOS 15.0, *)
struct CompactAppSubscriptionStatusIndicator: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var subscriptionStatus: AppAppSubscriptionStatus = .expired
    @State private var showPaywall = false

    var body: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)

                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.1))
            )
        }
        .task {
            await loadAppSubscriptionStatus()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                Task {
                    await loadAppSubscriptionStatus()
                }
            }
        }
    }

    private var statusIcon: String {
        switch subscriptionStatus {
        case .active:
            return "star.fill"
        case .trial:
            return "star.circle"
        case .expired, .revoked:
            return "exclamationmark.triangle"
        case .gracePeriod:
            return "creditcard.trianglebadge.exclamationmark"
        }
    }

    private var statusText: String {
        switch subscriptionStatus {
        case .active:
            return "Premium"
        case .trial:
            return "Trial"
        case .expired, .revoked:
            return "Expired"
        case .gracePeriod:
            return "Issue"
        }
    }

    private var statusColor: Color {
        switch subscriptionStatus {
        case .active:
            return .green
        case .trial:
            return .blue
        case .expired, .revoked:
            return .orange
        case .gracePeriod:
            return .red
        }
    }

    private func loadAppSubscriptionStatus() async {
        // In a real app, this would check the actual subscription status
        // For now, we'll simulate having a trial subscription
        subscriptionStatus = .trial
    }
}

/// Premium feature gate view
@available(iOS 15.0, *)
struct PremiumFeatureGate: View {
    let feature: String
    let description: String
    let icon: String
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Premium Feature")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(feature)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Upgrade to Premium") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct AppSubscriptionStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppSubscriptionStatusIndicator()

            CompactAppSubscriptionStatusIndicator()

            PremiumFeatureGate(
                feature: "Unlimited Children",
                description: "Add as many children as you need to your family",
                icon: "person.3.fill"
            )
        }
        .padding()
    }
}
#endif