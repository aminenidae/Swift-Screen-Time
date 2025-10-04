import SwiftUI
import FamilyControlsKit

/// Main onboarding flow for new users
struct OnboardingView: View {
    @AppStorage("userRole") private var userRole: String = "parent"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentStep = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressView(currentStep: currentStep, totalSteps: getTotalSteps())
                    .padding(.top)
                    .padding(.horizontal)
                
                // Content area
                ZStack {
                    // Welcome step
                    if currentStep == 0 {
                        WelcomeView(onGetStarted: {
                            withAnimation {
                                currentStep = 1
                            }
                        })
                    }
                    // Role selection step
                    else if currentStep == 1 {
                        RoleSelectionView(
                            selectedRole: $userRole,
                            onContinue: {
                                withAnimation {
                                    currentStep = 2
                                }
                            }
                        )
                    }
                    // Role-specific onboarding
                    else {
                        if userRole == "parent" {
                            ParentOnboardingView(
                                step: currentStep - 2,
                                onStepChange: { newStep in
                                    withAnimation {
                                        currentStep = newStep + 2
                                    }
                                },
                                onComplete: {
                                    completeOnboarding()
                                }
                            )
                        } else {
                            ChildOnboardingView(
                                step: currentStep - 2,
                                onStepChange: { newStep in
                                    withAnimation {
                                        currentStep = newStep + 2
                                    }
                                },
                                onComplete: {
                                    completeOnboarding()
                                }
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.blue)
                }
                
                // Back button (except on welcome screen)
                if currentStep > 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            withAnimation {
                                if currentStep > 0 {
                                    currentStep -= 1
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func getTotalSteps() -> Int {
        // Welcome + Role selection + Role-specific steps
        return 2 + (userRole == "parent" ? 3 : 3)
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
}