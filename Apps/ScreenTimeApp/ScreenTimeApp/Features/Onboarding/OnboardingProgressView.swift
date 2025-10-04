import SwiftUI

/// Progress indicator for onboarding steps
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .progressViewStyle(.linear)
                .tint(.blue)
        }
    }
}

#Preview {
    OnboardingProgressView(currentStep: 1, totalSteps: 5)
}