import SwiftUI

/// Summary view for quick access to important settings from the dashboard
struct SettingsSummaryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: ParentSystemSettingsView()) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SettingsShortcutCard(
                    title: "Family Setup",
                    icon: "house.fill",
                    color: .blue
                ) {
                    // Navigate to Family Setup
                }
                
                SettingsShortcutCard(
                    title: "Time Limits",
                    icon: "clock.fill",
                    color: .orange
                ) {
                    // Navigate to Time Limits
                }
                
                SettingsShortcutCard(
                    title: "Learning Points",
                    icon: "graduationcap.fill",
                    color: .green
                ) {
                    // Navigate to Learning Points
                }
                
                SettingsShortcutCard(
                    title: "Reward Apps",
                    icon: "gift.fill",
                    color: .purple
                ) {
                    // Navigate to Reward Apps
                }
            }
        }
    }
}

/// Card view for a settings shortcut
struct SettingsShortcutCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsSummaryView()
}