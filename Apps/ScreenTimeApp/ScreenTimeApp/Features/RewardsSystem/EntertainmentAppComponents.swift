import SwiftUI
import SharedModels
import FamilyControlsKit

/// Card for unlocking entertainment apps with points
struct EntertainmentAppUnlockCard: View {
    let app: FamilyControlsKit.EntertainmentAppConfig
    let currentPoints: Int
    let isUnlocked: Bool
    let onUnlock: (Int) -> Void

    @State private var showingDurationPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(app.bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isUnlocked {
                        Label("Currently Unlocked", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Blocked", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Text("\(app.pointsCostPer30Min)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("/ 30min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isUnlocked {
                        Button("Already Unlocked") {
                            // Already unlocked, can't unlock again
                        }
                        .buttonStyle(.bordered)
                        .disabled(true)
                    } else {
                        Button("Unlock App") {
                            showingDurationPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentPoints < app.pointsCostPer30Min)
                    }
                }
            }

            // Duration and cost options
            if !isUnlocked {
                HStack(spacing: 16) {
                    DurationOptionButton(
                        duration: 30,
                        cost: app.pointsCostPer30Min,
                        canAfford: currentPoints >= app.pointsCostPer30Min,
                        onTap: { onUnlock(30) }
                    )

                    DurationOptionButton(
                        duration: 60,
                        cost: app.pointsCostPer60Min,
                        canAfford: currentPoints >= app.pointsCostPer60Min,
                        onTap: { onUnlock(60) }
                    )
                }
            }

            // Insufficient points warning
            if !isUnlocked && currentPoints < app.pointsCostPer30Min {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text("Need \(app.pointsCostPer30Min - currentPoints) more points")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(isUnlocked ? 0.8 : 1.0)
        .sheet(isPresented: $showingDurationPicker) {
            AppUnlockDurationPickerView(
                app: app,
                currentPoints: currentPoints,
                onUnlock: onUnlock
            )
        }
    }
}

/// Quick duration option button for app unlocking
struct DurationOptionButton: View {
    let duration: Int
    let cost: Int
    let canAfford: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(duration) min")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(cost) pts")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(canAfford ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canAfford ? Color.blue : Color.gray, lineWidth: 1)
            )
        }
        .disabled(!canAfford)
        .buttonStyle(.plain)
    }
}

/// Full-screen duration picker for app unlocking
struct AppUnlockDurationPickerView: View {
    let app: FamilyControlsKit.EntertainmentAppConfig
    let currentPoints: Int
    let onUnlock: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDuration = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // App Info
                VStack(spacing: 16) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Unlock \(app.displayName)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose how long you want to unlock this app")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Duration Options
                VStack(spacing: 16) {
                    DurationPickerRow(
                        duration: 15,
                        cost: app.pointsCost(for: 15),
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 15,
                        onSelect: { selectedDuration = 15 }
                    )

                    DurationPickerRow(
                        duration: 30,
                        cost: app.pointsCostPer30Min,
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 30,
                        onSelect: { selectedDuration = 30 }
                    )

                    DurationPickerRow(
                        duration: 60,
                        cost: app.pointsCostPer60Min,
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 60,
                        onSelect: { selectedDuration = 60 }
                    )

                    DurationPickerRow(
                        duration: 120,
                        cost: app.pointsCost(for: 120),
                        currentPoints: currentPoints,
                        isSelected: selectedDuration == 120,
                        onSelect: { selectedDuration = 120 }
                    )
                }

                Spacer()

                // Unlock Button
                Button("Unlock for \(selectedDuration) minutes") {
                    onUnlock(selectedDuration)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(currentPoints < app.pointsCost(for: selectedDuration))
            }
            .padding()
            .navigationTitle("Unlock Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Row component for duration selection in the picker
struct DurationPickerRow: View {
    let duration: Int
    let cost: Int
    let currentPoints: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var canAfford: Bool {
        currentPoints >= cost
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(duration) minutes")
                        .font(.headline)
                        .fontWeight(.medium)

                    if canAfford {
                        Text("You have enough points")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Need \(cost - currentPoints) more points")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(cost) points")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!canAfford)
        .buttonStyle(.plain)
    }
}
