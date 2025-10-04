import SwiftUI

// MARK: - App Category Card

struct AppCategoryCard: View {
    let category: AppCategory
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .font(.title2)

                        Text(category.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { isEnabled },
                            set: { onToggle($0) }
                        ))
                        .labelsHidden()
                    }

                    Text(category.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    HStack {
                        Text("Apps in this category will be:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text("Managed by Screen Time controls")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        .stroke(isEnabled ? category.color.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .opacity(isEnabled ? 1.0 : 0.7)
    }
}

// MARK: - Learning App Card

struct LearningAppCard: View {
    let app: LearningAppConfig
    let onPointsChanged: (Int) -> Void
    let onToggle: (Bool) -> Void
    let onRemove: () -> Void

    @State private var showingPointsEditor = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Bundle ID: \(app.bundleID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { app.isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }

            if app.isEnabled {
                VStack(spacing: 12) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Points per minute")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Child earns \(app.pointsPerMinute) points for each minute using this app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { showingPointsEditor = true }) {
                            Text("\(app.pointsPerMinute)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.1))
                                )
                        }
                    }

                    HStack {
                        Button("Remove", role: .destructive) {
                            onRemove()
                        }
                        .font(.caption)

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
                        .stroke(app.isEnabled ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .opacity(app.isEnabled ? 1.0 : 0.7)
        .sheet(isPresented: $showingPointsEditor) {
            PointsEditorView(
                title: "Points per Minute",
                currentValue: app.pointsPerMinute,
                range: 1...10,
                onSave: onPointsChanged
            )
        }
    }
}

// MARK: - Reward App Card

struct RewardAppCard: View {
    let app: RewardAppConfig
    let onCostChanged: (UnlockDuration, Int) -> Void
    let onToggle: (Bool) -> Void
    let onRemove: () -> Void

    @State private var expandedDuration: UnlockDuration?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Bundle ID: \(app.bundleID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { app.isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }

            if app.isEnabled {
                VStack(spacing: 12) {
                    Divider()

                    Text("Unlock Costs")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        UnlockDurationRow(
                            duration: .fifteen,
                            cost: app.cost15Min,
                            isExpanded: expandedDuration == .fifteen,
                            onTap: { toggleExpanded(.fifteen) },
                            onCostChanged: { newCost in
                                onCostChanged(.fifteen, newCost)
                            }
                        )

                        UnlockDurationRow(
                            duration: .thirty,
                            cost: app.cost30Min,
                            isExpanded: expandedDuration == .thirty,
                            onTap: { toggleExpanded(.thirty) },
                            onCostChanged: { newCost in
                                onCostChanged(.thirty, newCost)
                            }
                        )

                        UnlockDurationRow(
                            duration: .sixty,
                            cost: app.cost60Min,
                            isExpanded: expandedDuration == .sixty,
                            onTap: { toggleExpanded(.sixty) },
                            onCostChanged: { newCost in
                                onCostChanged(.sixty, newCost)
                            }
                        )
                    }

                    HStack {
                        Button("Remove", role: .destructive) {
                            onRemove()
                        }
                        .font(.caption)

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
                        .stroke(app.isEnabled ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .opacity(app.isEnabled ? 1.0 : 0.7)
    }

    private func toggleExpanded(_ duration: UnlockDuration) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedDuration = expandedDuration == duration ? nil : duration
        }
    }
}


// MARK: - Supporting Components

struct UnlockDurationRow: View {
    let duration: UnlockDuration
    let cost: Int
    let isExpanded: Bool
    let onTap: () -> Void
    let onCostChanged: (Int) -> Void

    @State private var showingCostEditor = false

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(duration.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(cost)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isExpanded ? Color.purple.opacity(0.1) : Color(.systemBackground))
            )
        }
        .overlay(
            Group {
                if isExpanded {
                    VStack {
                        Spacer()
                        Button("Edit Cost") {
                            showingCostEditor = true
                        }
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.bottom, 4)
                    }
                }
            }
        )
        .sheet(isPresented: $showingCostEditor) {
            PointsEditorView(
                title: "Cost for \(duration.displayName)",
                currentValue: cost,
                range: 5...200,
                onSave: onCostChanged
            )
        }
    }
}

struct PointsEditorView: View {
    let title: String
    let currentValue: Int
    let range: ClosedRange<Int>
    let onSave: (Int) -> Void

    @State private var value: Int
    @Environment(\.dismiss) private var dismiss

    init(title: String, currentValue: Int, range: ClosedRange<Int>, onSave: @escaping (Int) -> Void) {
        self.title = title
        self.currentValue = currentValue
        self.range = range
        self.onSave = onSave
        self._value = State(initialValue: currentValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set \(title.lowercased())")
                    .font(.headline)

                Stepper(value: $value, in: range) {
                    HStack {
                        Text("\(value)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        if title.contains("minute") {
                            Text("points/min")
                                .foregroundColor(.secondary)
                        } else {
                            Text("points")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)

                HStack {
                    Text("\(range.lowerBound)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(range.upperBound)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(value)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#if DEBUG
struct ChildSpecificViewComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                AppCategoryCard(
                    category: .entertainment,
                    isEnabled: true,
                    onToggle: { _ in }
                )

                LearningAppCard(
                    app: LearningAppConfig(
                        bundleID: "com.khanacademy.khanacademykids",
                        displayName: "Khan Academy Kids",
                        pointsPerMinute: 2,
                        isEnabled: true
                    ),
                    onPointsChanged: { _ in },
                    onToggle: { _ in },
                    onRemove: { }
                )

                RewardAppCard(
                    app: RewardAppConfig(
                        bundleID: "com.zhiliaoapp.musically",
                        displayName: "TikTok",
                        cost15Min: 25,
                        cost30Min: 40,
                        cost60Min: 70,
                        isEnabled: true
                    ),
                    onCostChanged: { _, _ in },
                    onToggle: { _ in },
                    onRemove: { }
                )
            }
            .padding()
        }
    }
}
#endif