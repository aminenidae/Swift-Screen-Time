import SwiftUI

/// Profile view for children showing their stats and account management
struct ChildProfileView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingProfileSwitcher = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Alex")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Learning Enthusiast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Stats")
                            .font(.headline)
                            .fontWeight(.semibold)

                        HStack(spacing: 20) {
                            ProfileStatCard(title: "Total Points", value: "1,250", icon: "star.fill", color: .yellow)
                            ProfileStatCard(title: "Learning Hours", value: "24.5", icon: "book.fill", color: .green)
                            ProfileStatCard(title: "Current Streak", value: "3", icon: "flame.fill", color: .orange)
                        }
                    }

                    // Profile Switching Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Button(action: {
                            showingProfileSwitcher = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading) {
                                    Text("Switch Profile")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text("Switch to parent view or change user")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingProfileSwitcher) {
                ProfileSwitcherView()
            }
        }
    }
}

/// Profile stat card component for displaying child statistics
struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// Profile Switcher View - allows switching between parent and child views
struct ProfileSwitcherView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Switch Profile")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose your view mode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Profile Options
                VStack(spacing: 16) {
                    // Parent Profile Option
                    Button(action: {
                        userRole = "parent"
                        dismiss()
                    }) {
                        ProfileOptionCard(
                            title: "Parent View",
                            subtitle: "Manage family screen time and settings",
                            icon: "person.circle.fill",
                            isSelected: userRole == "parent"
                        )
                    }
                    .buttonStyle(.plain)

                    // Child Profile Option
                    Button(action: {
                        userRole = "child"
                        dismiss()
                    }) {
                        ProfileOptionCard(
                            title: "Child View",
                            subtitle: "View your stats and earned rewards",
                            icon: "person.crop.circle.fill",
                            isSelected: userRole == "child"
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Switch Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Profile option card component
struct ProfileOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

#if DEBUG
struct ChildProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileView()
    }
}
#endif