import SwiftUI

/// Trial countdown banner component
@available(iOS 15.0, *)
struct TrialCountdownBanner: View {
    let daysRemaining: Int
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(.orange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trial expires in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Upgrade now to keep all premium features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Upgrade") {
                    onUpgrade()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct TrialCountdownBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TrialCountdownBanner(daysRemaining: 3) {
                print("Upgrade tapped")
            }

            TrialCountdownBanner(daysRemaining: 1) {
                print("Upgrade tapped")
            }
        }
        .padding()
    }
}
#endif