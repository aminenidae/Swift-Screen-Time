import SwiftUI

/// Welcome screen for the onboarding flow
struct WelcomeView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon/illustration
            Image(systemName: "hands.sparkles.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolRenderingMode(.multicolor)
            
            // Title and description
            VStack(spacing: 16) {
                Text("Transform Screen Time into Learning Time")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Earn rewards for educational activities and unlock fun time with ScreenTime Rewards")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Get Started button
            Button(action: onGetStarted) {
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

#Preview {
    WelcomeView(onGetStarted: {})
}