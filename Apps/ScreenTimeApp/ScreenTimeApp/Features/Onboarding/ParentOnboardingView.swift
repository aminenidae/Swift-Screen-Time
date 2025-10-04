import SwiftUI
import FamilyControlsKit

/// Multi-step onboarding flow for parents
struct ParentOnboardingView: View {
    let step: Int
    let onStepChange: (Int) -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case 0:
                FamilySetupIntroView(onContinue: { onStepChange(1) })
            case 1:
                FamilyDetailsView(onContinue: { onStepChange(2) })
            case 2:
                RewardSystemIntroView(onContinue: onComplete)
            default:
                FamilySetupIntroView(onContinue: { onStepChange(1) })
            }
        }
    }
}

/// Step 1: Family setup introduction
struct FamilySetupIntroView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Set Up Your Family")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("ScreenTime Rewards works with Apple Family Sharing to manage your children's screen time")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingBenefitRow(
                        icon: "person.2.fill",
                        title: "See all your children's activity in one place",
                        color: .blue
                    )
                    
                    OnboardingBenefitRow(
                        icon: "target",
                        title: "Set individual goals and rewards",
                        color: .green
                    )
                    
                    OnboardingBenefitRow(
                        icon: "iphone",
                        title: "Track learning progress across devices",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

/// Step 2: Family details and member sync
struct FamilyDetailsView: View {
    @StateObject private var familyMemberService = FamilyMemberService()
    @State private var parentName = ""
    @State private var familyName = ""
    @State private var isSyncing = false
    
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Family Details")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Enter your name", text: $parentName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Family Name (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("e.g., The Johnson Family", text: $familyName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(.horizontal)
                
                Button(action: syncFamilyMembers) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Sync Family Members")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSyncing)
                .padding(.horizontal)
                
                if !familyMemberService.familyMembers.filter({ $0.isChild }).isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Added Children")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        ForEach(familyMemberService.familyMembers.filter { $0.isChild }) { child in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(child.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(child.hasAppInstalled ? "App Installed" : "Setup Required")
                                        .font(.caption)
                                        .foregroundColor(child.hasAppInstalled ? .green : .orange)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.horizontal)
                } else if !isSyncing && !familyMemberService.familyMembers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("No children found in Family Sharing")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Make sure you've added children to your Apple Family Sharing group")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            // Load existing family members if any
            Task {
                await loadFamilyMembers()
            }
        }
    }
    
    private func syncFamilyMembers() {
        isSyncing = true
        Task {
            do {
                let members = try await familyMemberService.fetchFamilyMembers()
                await MainActor.run {
                    familyMemberService.familyMembers = members
                    isSyncing = false
                }
            } catch {
                print("Error syncing family members: \(error)")
                await MainActor.run {
                    isSyncing = false
                }
            }
        }
    }
    
    private func loadFamilyMembers() async {
        do {
            let members = try await familyMemberService.fetchFamilyMembers()
            await MainActor.run {
                familyMemberService.familyMembers = members
            }
        } catch {
            print("Error loading family members: \(error)")
        }
    }
}

/// Step 3: Reward system introduction
struct RewardSystemIntroView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                VStack(spacing: 16) {
                    Text("How Rewards Work")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Children earn points for using educational apps and can redeem them for entertainment time")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingBenefitRow(
                        icon: "graduationcap.fill",
                        title: "Learning Apps = Earn Points",
                        description: "Children earn 1 point per minute of educational app usage",
                        color: .green
                    )
                    
                    OnboardingBenefitRow(
                        icon: "tv.fill",
                        title: "Entertainment Apps = Spend Points",
                        description: "Children spend points to unlock entertainment apps",
                        color: .orange
                    )
                    
                    OnboardingBenefitRow(
                        icon: "target",
                        title: "Set daily goals for consistent learning",
                        description: "Encourage regular educational app usage with daily targets",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

/// Reusable benefit row component
struct OnboardingBenefitRow: View {
    let icon: String
    let title: String
    let description: String?
    let color: Color
    
    init(icon: String, title: String, description: String? = nil, color: Color) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    ParentOnboardingView(step: 0, onStepChange: { _ in }, onComplete: {})
}