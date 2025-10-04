import SwiftUI
import FamilyControls
import FamilyControlsKit

// MARK: - Learning App Rewards View (Main Entry Point)

/// Main entry point for learning app rewards management - shows child selection first
struct LearningAppRewardsView: View {
    var body: some View {
        ChildSelectionView(
            onChildSelected: { child in
                // Navigate to child-specific learning app view
            },
            destinationType: .learningAppSettings
        )
    }
}

// MARK: - Child-Specific App Categories View

struct ChildSpecificAppCategoriesView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var appCategories: [AppCategory] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                if familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    EmptyChildrenStateView()
                } else {
                    // Child selection
                    if familyMemberService.familyMembers.filter({ $0.isChild }).count > 1 {
                        ChildSelectorView(
                            children: familyMemberService.familyMembers.filter({ $0.isChild }),
                            selectedChild: $selectedChild
                        )
                    }

                    // App categories configuration
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(AppCategory.allCases, id: \.self) { category in
                                AppCategoryCard(
                                    category: category,
                                    isEnabled: appCategories.contains(category),
                                    onToggle: { enabled in
                                        toggleCategory(category, enabled: enabled)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("App Categories")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFamilyMembers()
            }
            .refreshable {
                loadAppCategories()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
                if let firstChild = familyMemberService.familyMembers.filter({ $0.isChild }).first {
                    selectedChild = firstChild
                    loadAppCategories()
                }
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }

    private func loadAppCategories() {
        // Load saved categories for the selected child
        // This would integrate with actual Family Controls API
        appCategories = [.educational, .entertainment, .social]
    }

    private func toggleCategory(_ category: AppCategory, enabled: Bool) {
        if enabled {
            appCategories.append(category)
        } else {
            appCategories.removeAll { $0 == category }
        }
        // Save changes to UserDefaults or CloudKit
        saveAppCategories()
    }

    private func saveAppCategories() {
        // Implementation for saving app categories
        print("Saving app categories: \(appCategories)")
    }
}

// MARK: - Child-Specific Learning Apps View

struct ChildSpecificLearningAppView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var learningApps: [LearningAppConfig] = []
    @State private var showingAddApp = false

    var body: some View {
        NavigationStack {
            VStack {
                if familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    EmptyChildrenStateView()
                } else {
                    // Child selection
                    if familyMemberService.familyMembers.filter({ $0.isChild }).count > 1 {
                        ChildSelectorView(
                            children: familyMemberService.familyMembers.filter({ $0.isChild }),
                            selectedChild: $selectedChild
                        )
                    }

                    // Learning apps list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header
                            VStack(spacing: 12) {
                                Image(systemName: "graduationcap.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)

                                Text("Learning Apps")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Configure which apps earn points and how many points per minute")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()

                            // Add new app button
                            Button(action: { showingAddApp = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Learning App")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Learning apps list
                            ForEach(learningApps, id: \.bundleID) { app in
                                LearningAppCard(
                                    app: app,
                                    onPointsChanged: { newPoints in
                                        updateAppPoints(app.bundleID, points: newPoints)
                                    },
                                    onToggle: { enabled in
                                        toggleApp(app.bundleID, enabled: enabled)
                                    },
                                    onRemove: {
                                        removeApp(app.bundleID)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Learning Apps")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddApp) {
                AddLearningAppView { app in
                    learningApps.append(app)
                    saveLearningApps()
                }
            }
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
                if let firstChild = familyMemberService.familyMembers.filter({ $0.isChild }).first {
                    selectedChild = firstChild
                    loadLearningApps()
                }
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }

    private func loadLearningApps() {
        // Load learning apps configuration
        learningApps = [
            LearningAppConfig(bundleID: "com.khanacademy.khanacademykids", displayName: "Khan Academy Kids", pointsPerMinute: 2, isEnabled: true),
            LearningAppConfig(bundleID: "com.duolingo.duolingoapp", displayName: "Duolingo", pointsPerMinute: 3, isEnabled: true),
            LearningAppConfig(bundleID: "com.brilliantorg.brilliant", displayName: "Brilliant", pointsPerMinute: 4, isEnabled: true)
        ]
    }

    private func updateAppPoints(_ bundleID: String, points: Int) {
        if let index = learningApps.firstIndex(where: { $0.bundleID == bundleID }) {
            learningApps[index].pointsPerMinute = points
            saveLearningApps()
        }
    }

    private func toggleApp(_ bundleID: String, enabled: Bool) {
        if let index = learningApps.firstIndex(where: { $0.bundleID == bundleID }) {
            learningApps[index].isEnabled = enabled
            saveLearningApps()
        }
    }

    private func removeApp(_ bundleID: String) {
        learningApps.removeAll { $0.bundleID == bundleID }
        saveLearningApps()
    }

    private func saveLearningApps() {
        // Save to UserDefaults or CloudKit
        print("Saving learning apps: \(learningApps)")
    }
}

// MARK: - Child-Specific Reward Apps View

struct ChildSpecificRewardAppView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var rewardApps: [RewardAppConfig] = []
    @State private var showingAddApp = false

    var body: some View {
        NavigationStack {
            VStack {
                if familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    EmptyChildrenStateView()
                } else {
                    // Child selection
                    if familyMemberService.familyMembers.filter({ $0.isChild }).count > 1 {
                        ChildSelectorView(
                            children: familyMemberService.familyMembers.filter({ $0.isChild }),
                            selectedChild: $selectedChild
                        )
                    }

                    // Reward apps list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header
                            VStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.purple)

                                Text("Reward Apps")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Set up entertainment apps that require points to unlock")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()

                            // Add new app button
                            Button(action: { showingAddApp = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Reward App")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Reward apps list
                            ForEach(rewardApps, id: \.bundleID) { app in
                                RewardAppCard(
                                    app: app,
                                    onCostChanged: { duration, newCost in
                                        updateAppCost(app.bundleID, duration: duration, cost: newCost)
                                    },
                                    onToggle: { enabled in
                                        toggleApp(app.bundleID, enabled: enabled)
                                    },
                                    onRemove: {
                                        removeApp(app.bundleID)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Reward Apps")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddApp) {
                AddRewardAppView { app in
                    rewardApps.append(app)
                    saveRewardApps()
                }
            }
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
                if let firstChild = familyMemberService.familyMembers.filter({ $0.isChild }).first {
                    selectedChild = firstChild
                    loadRewardApps()
                }
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }

    private func loadRewardApps() {
        // Load reward apps configuration
        rewardApps = [
            RewardAppConfig(bundleID: "com.zhiliaoapp.musically", displayName: "TikTok", cost15Min: 25, cost30Min: 40, cost60Min: 70, isEnabled: true),
            RewardAppConfig(bundleID: "com.instagram.instagram", displayName: "Instagram", cost15Min: 20, cost30Min: 35, cost60Min: 60, isEnabled: true),
            RewardAppConfig(bundleID: "com.youtube.youtube", displayName: "YouTube", cost15Min: 15, cost30Min: 25, cost60Min: 45, isEnabled: true),
            RewardAppConfig(bundleID: "com.netflix.Netflix", displayName: "Netflix", cost15Min: 30, cost30Min: 50, cost60Min: 85, isEnabled: true)
        ]
    }

    private func updateAppCost(_ bundleID: String, duration: UnlockDuration, cost: Int) {
        if let index = rewardApps.firstIndex(where: { $0.bundleID == bundleID }) {
            switch duration {
            case .fifteen:
                rewardApps[index].cost15Min = cost
            case .thirty:
                rewardApps[index].cost30Min = cost
            case .sixty:
                rewardApps[index].cost60Min = cost
            }
            saveRewardApps()
        }
    }

    private func toggleApp(_ bundleID: String, enabled: Bool) {
        if let index = rewardApps.firstIndex(where: { $0.bundleID == bundleID }) {
            rewardApps[index].isEnabled = enabled
            saveRewardApps()
        }
    }

    private func removeApp(_ bundleID: String) {
        rewardApps.removeAll { $0.bundleID == bundleID }
        saveRewardApps()
    }

    private func saveRewardApps() {
        // Save to UserDefaults or CloudKit
        print("Saving reward apps: \(rewardApps)")
    }
}

// MARK: - Child-Specific Special Rewards View

struct ChildSpecificSpecialRewardsView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var selectedChild: FamilyMemberInfo?
    @State private var specialRewards: [SpecialReward] = []
    @State private var showingAddReward = false

    var body: some View {
        NavigationStack {
            VStack {
                if familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    EmptyChildrenStateView()
                } else {
                    // Child selection
                    if familyMemberService.familyMembers.filter({ $0.isChild }).count > 1 {
                        ChildSelectorView(
                            children: familyMemberService.familyMembers.filter({ $0.isChild }),
                            selectedChild: $selectedChild
                        )
                    }

                    // Special rewards list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header
                            VStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.yellow)

                                Text("Special Rewards")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Create custom rewards beyond app unlocks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()

                            // Add new reward button
                            Button(action: { showingAddReward = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Special Reward")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Special rewards list
                            ForEach(specialRewards, id: \.id) { reward in
                                VStack {
                                    Text(reward.name)
                                        .font(.headline)
                                    Text("Cost: \(reward.pointsCost) points")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Special Rewards")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddReward) {
                AddSpecialRewardView { reward in
                    specialRewards.append(reward)
                    saveSpecialRewards()
                }
            }
            .onAppear {
                loadFamilyMembers()
            }
        }
    }

    private func loadFamilyMembers() {
        Task {
            do {
                let _ = try await familyMemberService.fetchFamilyMembers()
                if let firstChild = familyMemberService.familyMembers.filter({ $0.isChild }).first {
                    selectedChild = firstChild
                    loadSpecialRewards()
                }
            } catch {
                print("Error loading family members: \(error)")
            }
        }
    }

    private func loadSpecialRewards() {
        // Load special rewards configuration
        specialRewards = [
            SpecialReward(id: UUID(), name: "Extra Screen Time", description: "30 minutes of bonus screen time", pointsCost: 50, isEnabled: true),
            SpecialReward(id: UUID(), name: "Movie Night Choice", description: "Choose tonight's family movie", pointsCost: 75, isEnabled: true),
            SpecialReward(id: UUID(), name: "Late Bedtime", description: "Stay up 30 minutes later", pointsCost: 100, isEnabled: true),
            SpecialReward(id: UUID(), name: "Special Treat", description: "Ice cream or special dessert", pointsCost: 60, isEnabled: true),
            SpecialReward(id: UUID(), name: "Friend Playdate", description: "Invite a friend over", pointsCost: 150, isEnabled: true)
        ]
    }

    private func updateRewardCost(_ rewardID: UUID, cost: Int) {
        if let index = specialRewards.firstIndex(where: { $0.id == rewardID }) {
            specialRewards[index].pointsCost = cost
            saveSpecialRewards()
        }
    }

    private func toggleReward(_ rewardID: UUID, enabled: Bool) {
        if let index = specialRewards.firstIndex(where: { $0.id == rewardID }) {
            specialRewards[index].isEnabled = enabled
            saveSpecialRewards()
        }
    }

    private func removeReward(_ rewardID: UUID) {
        specialRewards.removeAll { $0.id == rewardID }
        saveSpecialRewards()
    }

    private func saveSpecialRewards() {
        // Save to UserDefaults or CloudKit
        print("Saving special rewards: \(specialRewards)")
    }
}

// MARK: - Supporting Models

enum AppCategory: String, CaseIterable {
    case educational = "Educational"
    case entertainment = "Entertainment"
    case social = "Social"
    case games = "Games"
    case productivity = "Productivity"
    case utilities = "Utilities"

    var icon: String {
        switch self {
        case .educational: return "graduationcap.fill"
        case .entertainment: return "tv.fill"
        case .social: return "person.2.fill"
        case .games: return "gamecontroller.fill"
        case .productivity: return "folder.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .educational: return .green
        case .entertainment: return .blue
        case .social: return .purple
        case .games: return .orange
        case .productivity: return .indigo
        case .utilities: return .gray
        }
    }

    var description: String {
        switch self {
        case .educational: return "Learning and educational apps"
        case .entertainment: return "Video, music, and entertainment apps"
        case .social: return "Social media and communication apps"
        case .games: return "Gaming apps and platforms"
        case .productivity: return "Work and productivity tools"
        case .utilities: return "System utilities and tools"
        }
    }
}

struct LearningAppConfig: Identifiable {
    let id = UUID()
    let bundleID: String
    let displayName: String
    var pointsPerMinute: Int
    var isEnabled: Bool
}

struct RewardAppConfig: Identifiable {
    let id = UUID()
    let bundleID: String
    let displayName: String
    var cost15Min: Int
    var cost30Min: Int
    var cost60Min: Int
    var isEnabled: Bool
}

enum UnlockDuration: CaseIterable {
    case fifteen, thirty, sixty

    var displayName: String {
        switch self {
        case .fifteen: return "15 min"
        case .thirty: return "30 min"
        case .sixty: return "60 min"
        }
    }
}

struct SpecialReward: Identifiable {
    let id: UUID
    var name: String
    var description: String
    var pointsCost: Int
    var isEnabled: Bool
}

// MARK: - Supporting Views

struct EmptyChildrenStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("No Children Found")
                .font(.title2)
                .fontWeight(.bold)

            Text("Set up Family Sharing to manage your children's screen time and rewards.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: FamilySetupView()) {
                Text("Set up Family Sharing")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct ChildSelectorView: View {
    let children: [FamilyMemberInfo]
    @Binding var selectedChild: FamilyMemberInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Child")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(children, id: \.id) { child in
                        Button(action: {
                            selectedChild = child
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("Child \(children.firstIndex(where: { $0.id == child.id }) ?? 0 + 1)")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedChild?.id == child.id ? Color.blue : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedChild?.id == child.id ? .white : .primary
                            )
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
}

// Placeholder views for sheets
struct AddLearningAppView: View {
    let onAdd: (LearningAppConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Learning App functionality would go here")
                Button("Cancel") { dismiss() }
            }
            .navigationTitle("Add Learning App")
        }
    }
}

struct AddRewardAppView: View {
    let onAdd: (RewardAppConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Reward App functionality would go here")
                Button("Cancel") { dismiss() }
            }
            .navigationTitle("Add Reward App")
        }
    }
}

struct AddSpecialRewardView: View {
    let onAdd: (SpecialReward) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Special Reward functionality would go here")
                Button("Cancel") { dismiss() }
            }
            .navigationTitle("Add Special Reward")
        }
    }
}


#if DEBUG
struct ChildSpecificViews_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChildSpecificRewardAppView()
        }
    }
}
#endif