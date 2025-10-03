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

// Forward declaration for ProfileSwitcherView - will be modularized later
struct ProfileSwitcherView: View {
    var body: some View {
        Text("Profile Switcher - To be modularized")
    }
}

#if DEBUG
struct ChildProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileView()
    }
}
#endif