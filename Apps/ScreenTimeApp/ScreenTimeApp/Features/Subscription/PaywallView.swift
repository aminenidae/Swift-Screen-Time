import SwiftUI
import Combine
import SubscriptionService
import SharedModels
import StoreKit

/// Main paywall view for subscription purchases
@available(iOS 15.0, *)
struct PaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductId: String?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    let onPurchaseComplete: (() -> Void)?

    init(onPurchaseComplete: (() -> Void)? = nil) {
        self.onPurchaseComplete = onPurchaseComplete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)

                        Text("Unlock Premium Features")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Get unlimited children, detailed analytics, and exclusive features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Features List
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "person.3.fill",
                            title: "Unlimited Children",
                            description: "Add as many children as you need to your family"
                        )

                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Detailed Analytics",
                            description: "Advanced reports and usage insights"
                        )

                        FeatureRow(
                            icon: "bell.fill",
                            title: "Smart Notifications",
                            description: "Intelligent alerts and reminders"
                        )

                        FeatureRow(
                            icon: "icloud.fill",
                            title: "Cloud Sync",
                            description: "Sync data across all family devices"
                        )
                    }

                    // Subscription Plans
                    if subscriptionService.isLoading {
                        ProgressView("Loading subscription plans...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        VStack(spacing: 16) {
                            Text("Choose Your Plan")
                                .font(.title2)
                                .fontWeight(.bold)

                            ForEach(subscriptionService.availableProducts, id: \.id) { product in
                                SubscriptionPlanCard(
                                    product: product,
                                    isSelected: selectedProductId == product.id,
                                    onSelect: { selectedProductId = product.id }
                                )
                            }
                        }
                    }

                    // Purchase Button
                    if !subscriptionService.isLoading && !subscriptionService.availableProducts.isEmpty {
                        VStack(spacing: 16) {
                            Button(action: purchaseSelected) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(isPurchasing ? "Processing..." : "Start Subscription")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedProductId != nil ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(selectedProductId == nil || isPurchasing)

                            Button("Restore Purchases") {
                                restorePurchases()
                            }
                            .foregroundColor(.blue)
                        }
                    }

                    // Footer
                    VStack(spacing: 8) {
                        Text("Auto-renewing subscription. Cancel anytime.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 20) {
                            Button("Terms of Service") {
                                // Open terms
                            }
                            .font(.caption)

                            Button("Privacy Policy") {
                                // Open privacy policy
                            }
                            .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await subscriptionService.fetchProducts()
            // Auto-select the first product if none selected
            if selectedProductId == nil && !subscriptionService.availableProducts.isEmpty {
                selectedProductId = subscriptionService.availableProducts.first?.id
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func purchaseSelected() {
        guard let productId = selectedProductId else { return }

        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                let result = try await subscriptionService.purchase(productId)

                switch result {
                case .success(let verification):
                    // Handle successful purchase
                    switch verification {
                    case .verified(_):
                        await MainActor.run {
                            onPurchaseComplete?()
                            dismiss()
                        }
                    case .unverified(_, let error):
                        await MainActor.run {
                            errorMessage = "Purchase verification failed: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                case .userCancelled:
                    // User cancelled, no action needed
                    break
                case .pending:
                    await MainActor.run {
                        errorMessage = "Purchase is pending approval"
                        showError = true
                    }
                @unknown default:
                    await MainActor.run {
                        errorMessage = "Unknown purchase result"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func restorePurchases() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                try await subscriptionService.restorePurchases()
                await MainActor.run {
                    onPurchaseComplete?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

/// Feature row component for paywall
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

/// Subscription plan card component
struct SubscriptionPlanCard: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(product.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.priceFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text(product.subscriptionPeriod.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let offer = product.introductoryOffer {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Text(getOfferText(offer))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)

                        Spacer()
                    }
                }

                if isSelected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Selected")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func getOfferText(_ offer: StoreKit.Product.SubscriptionOffer) -> String {
        switch offer.type {
        case .introductory:
            return "Free trial or introductory offer available"
        case .promotional:
            return "Limited time offer"
        default:
            return "Special offer available"
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
#endif
