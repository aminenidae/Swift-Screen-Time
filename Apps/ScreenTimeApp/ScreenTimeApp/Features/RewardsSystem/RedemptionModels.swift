import SwiftUI
import Foundation

// MARK: - Reward Redemption Models

/// Model representing a redeemed reward by a child
struct RedeemedReward: Identifiable {
    let id: UUID
    let name: String
    let cost: Int
    let redeemedAt: Date
    var status: RedemptionStatus
}

/// Status of a reward redemption
enum RedemptionStatus {
    case pending
    case approved
    case denied

    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .denied: return .red
        }
    }

    var text: String {
        switch self {
        case .pending: return "Pending Approval"
        case .approved: return "Approved"
        case .denied: return "Denied"
        }
    }
}

/// Component for displaying recent redemption information
struct RecentRedemptionRow: View {
    let reward: RedeemedReward

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(reward.redeemedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("-\(reward.cost) pts")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)

                Text(reward.status.text)
                    .font(.caption)
                    .foregroundColor(reward.status.color)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}