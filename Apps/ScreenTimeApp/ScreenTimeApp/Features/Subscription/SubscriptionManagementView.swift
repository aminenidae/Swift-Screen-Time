import SwiftUI
import Combine
import SubscriptionService
import SharedModels
import StoreKit

/// Subscription management view for current subscribers
@available(iOS 15.0, *)
struct SubscriptionManagementView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var subscriptionStatus: SharedModels.SubscriptionStatus = .expired
    @State private var currentProduct: SubscriptionProduct?
    @State private var showCancelConfirmation = false
    @State private var showUpgradeSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Current Plan Section
                Section("Current Plan") {
                    if let product = currentProduct {
                        CurrentPlanCard(
                            product: product,
                            status: subscriptionStatus,
                            onUpgrade: { showUpgradeSheet = true },
                            onManage: { openSubscriptionManagement() }
                        )
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.orange)

                            Text("No Active Subscription")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("Subscribe to unlock premium features")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button("View Plans") {
                                showUpgradeSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }

                // Subscription Details Section
                if currentProduct != nil {
                    Section("Subscription Details") {
                        SubscriptionDetailRow(
                            title: "Status",
                            value: getStatusText(subscriptionStatus),
                            valueColor: getStatusColor(subscriptionStatus)
                        )

                        SubscriptionDetailRow(
                            title: "Billing Cycle",
                            value: currentProduct?.subscriptionPeriod.displayName ?? "Unknown"
                        )

                        SubscriptionDetailRow(
                            title: "Price",
                            value: currentProduct?.priceFormatted ?? "Unknown"
                        )

                        if subscriptionStatus == .trial {
                            SubscriptionDetailRow(
                                title: "Trial Ends",
                                value: getTrialEndDate(),
                                valueColor: .orange
                            )
                        }
                    }
                }

                // Actions Section
                Section("Actions") {
                    Button("View All Plans") {
                        showUpgradeSheet = true
                    }

                    Button("Restore Purchases") {
                        restorePurchases()
                    }

                    if currentProduct != nil {
                        Button("Manage Subscription") {
                            openSubscriptionManagement()
                        }
                    }
                }

                // Support Section
                Section("Support") {
                    Button("Contact Support") {
                        // Open support
                    }

                    Button("Billing Help") {
                        // Open billing help
                    }
                }
            }
            .navigationTitle("Subscription")
            .refreshable {
                await loadSubscriptionInfo()
            }
        }
        .task {
            await loadSubscriptionInfo()
        }
        .sheet(isPresented: $showUpgradeSheet) {
            PaywallView {
                Task {
                    await loadSubscriptionInfo()
                }
            }
        }
        .alert("Cancel Subscription", isPresented: $showCancelConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                openSubscriptionManagement()
            }
        } message: {
            Text("To cancel your subscription, you'll be redirected to your account settings.")
        }
    }

    private func loadSubscriptionInfo() async {
        await subscriptionService.fetchProducts()

        // In a real app, this would check the actual subscription status
        // For now, we'll simulate having a subscription
        if let firstProduct = subscriptionService.availableProducts.first {
            currentProduct = firstProduct
            subscriptionStatus = .active // This should come from SubscriptionStatusService
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await subscriptionService.restorePurchases()
                await loadSubscriptionInfo()
            } catch {
                // Handle error
                print("Failed to restore purchases: \(error)")
            }
        }
    }

    private func openSubscriptionManagement() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            Task {
                try await StoreKit.AppStore.showManageSubscriptions(in: windowScene)
            }
        }
    }

    private func getStatusText(_ status: SharedModels.SubscriptionStatus) -> String {
        switch status {
        case .active:
            return "Active"
        case .trial:
            return "Free Trial"
        case .expired:
            return "Expired"
        case .gracePeriod:
            return "Payment Issue"
        case .revoked:
            return "Cancelled"
        }
    }

    private func getStatusColor(_ status: SharedModels.SubscriptionStatus) -> Color {
        switch status {
        case .active:
            return .green
        case .trial:
            return .blue
        case .expired, .revoked:
            return .red
        case .gracePeriod:
            return .orange
        }
    }

    private func getTrialEndDate() -> String {
        // This should come from actual subscription data
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date().addingTimeInterval(7 * 24 * 60 * 60)) // 7 days from now
    }
}

/// Current plan card component
struct CurrentPlanCard: View {
    let product: SubscriptionProduct
    let status: SharedModels.SubscriptionStatus
    let onUpgrade: () -> Void
    let onManage: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .fontWeight(.bold)

                        Spacer()

                        StatusBadge(status: status)
                    }

                    Text(product.priceFormatted)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    Text("per \(product.subscriptionPeriod.displayName.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if status == .trial {
                TrialCountdownBanner(daysRemaining: 5) {
                    onUpgrade()
                }
            }

            HStack(spacing: 12) {
                Button("Upgrade Plan") {
                    onUpgrade()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Manage") {
                    onManage()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Subscription detail row component
struct SubscriptionDetailRow: View {
    let title: String
    let value: String
    let valueColor: Color

    init(title: String, value: String, valueColor: Color = .primary) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
        }
    }
}

/// Status badge component
struct StatusBadge: View {
    let status: SharedModels.SubscriptionStatus

    var body: some View {
        Text(getStatusText())
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(getStatusColor())
            )
    }

    private func getStatusText() -> String {
        switch status {
        case .active:
            return "Active"
        case .trial:
            return "Trial"
        case .expired:
            return "Expired"
        case .gracePeriod:
            return "Issue"
        case .revoked:
            return "Cancelled"
        }
    }

    private func getStatusColor() -> Color {
        switch status {
        case .active:
            return .green
        case .trial:
            return .blue
        case .expired, .revoked:
            return .red
        case .gracePeriod:
            return .orange
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct SubscriptionManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionManagementView()
    }
}
#endif
