import SwiftUI
import SubscriptionService
import SharedModels

/// Upgrade prompt for when users hit feature limits
@available(iOS 15.0, *)
struct FeatureLimitUpgradePrompt: View {
    let title: String
    let message: String
    let featureIcon: String
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Feature icon
            Image(systemName: featureIcon)
                .font(.system(size: 60))
                .foregroundColor(.blue)

            // Title and message
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Premium features list
            VStack(spacing: 12) {
                UpgradeFeatureRow(icon: "person.3.fill", text: "Unlimited children")
                UpgradeFeatureRow(icon: "chart.bar.fill", text: "Advanced analytics")
                UpgradeFeatureRow(icon: "icloud.fill", text: "Cloud sync")
                UpgradeFeatureRow(icon: "bell.fill", text: "Smart notifications")
            }

            // Action buttons
            VStack(spacing: 12) {
                Button("Upgrade to Premium") {
                    onUpgrade()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("Maybe Later") {
                    onDismiss()
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 20)
        )
        .padding()
    }
}

/// Contextual upgrade prompt that appears in specific features
@available(iOS 15.0, *)
struct ContextualUpgradePrompt: View {
    let context: UpgradeContext
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: context.icon)
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(context.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Upgrade") {
                    showPaywall = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// Smart upgrade prompt that tracks user behavior
@available(iOS 15.0, *)
struct SmartUpgradePrompt: View {
    @StateObject private var paywalltriggerService = PaywallTriggerService.shared
    @State private var showPaywall = false
    @State private var promptType: SmartPromptType = .usage

    var body: some View {
        Group {
            switch promptType {
            case .usage:
                UsageBasedPrompt()
            case .feature:
                FeatureBasedPrompt()
            case .value:
                ValueBasedPrompt()
            }
        }
        .onAppear {
            determinePromptType()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func UsageBasedPrompt() -> some View {
        VStack(spacing: 12) {
            Text("You're a power user! 🚀")
                .font(.headline)
                .fontWeight(.bold)

            Text("Unlock unlimited features to supercharge your family's screen time management")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("See Premium Features") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func FeatureBasedPrompt() -> some View {
        VStack(spacing: 12) {
            Text("Unlock More Children")
                .font(.headline)
                .fontWeight(.bold)

            Text("Add unlimited children to your family with Premium")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Upgrade Now") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func ValueBasedPrompt() -> some View {
        VStack(spacing: 12) {
            Text("Save Time with Automation")
                .font(.headline)
                .fontWeight(.bold)

            Text("Premium users save 2+ hours per week with smart features")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Start Free Trial") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func determinePromptType() {
        // Logic to determine which prompt to show based on user behavior
        // This would integrate with analytics and usage tracking
        promptType = .usage
    }
}

/// Upgrade prompt for navigation bar
@available(iOS 15.0, *)
struct NavigationUpgradePrompt: View {
    @State private var showPaywall = false

    var body: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)

                Text("Upgrade")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Supporting Types

enum UpgradeContext {
    case childLimit
    case analytics
    case cloudSync
    case notifications

    var icon: String {
        switch self {
        case .childLimit: return "person.3.fill"
        case .analytics: return "chart.bar.fill"
        case .cloudSync: return "icloud.fill"
        case .notifications: return "bell.fill"
        }
    }

    var title: String {
        switch self {
        case .childLimit: return "Child Limit Reached"
        case .analytics: return "Advanced Analytics"
        case .cloudSync: return "Cloud Sync Available"
        case .notifications: return "Smart Notifications"
        }
    }

    var subtitle: String {
        switch self {
        case .childLimit: return "Add unlimited children with Premium"
        case .analytics: return "Get detailed usage insights"
        case .cloudSync: return "Sync across all devices"
        case .notifications: return "Intelligent alerts and reminders"
        }
    }
}

enum SmartPromptType {
    case usage
    case feature
    case value
}

struct UpgradeFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)

            Spacer()

            Image(systemName: "checkmark")
                .foregroundColor(.green)
                .font(.caption)
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct UpgradePrompts_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FeatureLimitUpgradePrompt(
                title: "Child Limit Reached",
                message: "You've reached the maximum number of children for the free plan. Upgrade to Premium to add unlimited children.",
                featureIcon: "person.3.fill",
                onUpgrade: { print("Upgrade") },
                onDismiss: { print("Dismiss") }
            )

            ContextualUpgradePrompt(context: .childLimit)

            SmartUpgradePrompt()

            NavigationUpgradePrompt()
        }
        .padding()
    }
}
#endif