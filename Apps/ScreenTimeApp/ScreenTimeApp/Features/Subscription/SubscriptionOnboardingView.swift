import SwiftUI
import SubscriptionService
import SharedModels

/// Subscription onboarding flow for new users
@available(iOS 15.0, *)
struct SubscriptionOnboardingView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var currentStep = 0
    @State private var showPaywall = false

    let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Progress indicator
                ProgressIndicator(currentStep: currentStep, totalSteps: 3)

                // Step content
                switch currentStep {
                case 0:
                    WelcomeStep()
                case 1:
                    FeaturesStep()
                case 2:
                    PricingStep()
                default:
                    WelcomeStep()
                }

                Spacer()

                // Navigation buttons
                VStack(spacing: 16) {
                    if currentStep < 2 {
                        Button("Continue") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Start Free Trial") {
                            showPaywall = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)

                        Button("Maybe Later") {
                            onComplete()
                        }
                        .foregroundColor(.secondary)
                    }

                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .navigationTitle("Premium Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        onComplete()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                onComplete()
            }
        }
    }
}

/// Progress indicator for onboarding steps
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
    }
}

/// Welcome step of onboarding
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.yellow)
                .shadow(radius: 10)

            VStack(spacing: 12) {
                Text("Welcome to Premium!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Unlock the full potential of ScreenTime Rewards with our premium features designed for growing families.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                OnboardingBenefit(
                    icon: "person.3.fill",
                    title: "Unlimited Children",
                    description: "Add as many children as you need"
                )

                OnboardingBenefit(
                    icon: "chart.bar.fill",
                    title: "Detailed Analytics",
                    description: "Comprehensive usage reports"
                )

                OnboardingBenefit(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    description: "Sync across all family devices"
                )
            }
        }
    }
}

/// Features step of onboarding
struct FeaturesStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("Powerful Features")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("See what premium unlocks for your family's screen time management.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                FeatureComparison(
                    feature: "Children",
                    freeValue: "Up to 2",
                    premiumValue: "Unlimited",
                    isPremium: true
                )

                FeatureComparison(
                    feature: "Analytics",
                    freeValue: "Basic",
                    premiumValue: "Advanced Reports",
                    isPremium: true
                )

                FeatureComparison(
                    feature: "Notifications",
                    freeValue: "Standard",
                    premiumValue: "Smart Alerts",
                    isPremium: true
                )

                FeatureComparison(
                    feature: "Data Sync",
                    freeValue: "Local Only",
                    premiumValue: "Cloud Sync",
                    isPremium: true
                )

                FeatureComparison(
                    feature: "Support",
                    freeValue: "Community",
                    premiumValue: "Priority Support",
                    isPremium: true
                )
            }
        }
    }
}

/// Pricing step of onboarding
struct PricingStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gift.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("Try Premium Free")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Start with a 7-day free trial, then continue for just $4.99/month. Cancel anytime.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                PricingCard(
                    title: "Premium",
                    price: "$4.99",
                    period: "month",
                    features: [
                        "7-day free trial",
                        "Unlimited children",
                        "Advanced analytics",
                        "Cloud sync",
                        "Priority support"
                    ],
                    isRecommended: true
                )
            }

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
    }
}

/// Onboarding benefit row
struct OnboardingBenefit: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

/// Feature comparison row
struct FeatureComparison: View {
    let feature: String
    let freeValue: String
    let premiumValue: String
    let isPremium: Bool

    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("Free")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(freeValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Premium")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }

                Text(premiumValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .frame(width: 100)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Pricing card component
struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let features: [String]
    let isRecommended: Bool

    var body: some View {
        VStack(spacing: 16) {
            if isRecommended {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Recommended")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Spacer()
                }
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(alignment: .bottom, spacing: 4) {
                    Text(price)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("/ \(period)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(feature)
                            .font(.subheadline)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isRecommended ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct SubscriptionOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionOnboardingView {
            print("Onboarding completed")
        }
    }
}
#endif