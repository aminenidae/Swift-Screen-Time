import SwiftUI

/// Multi-step onboarding flow for children
struct ChildOnboardingView: View {
    let step: Int
    let onStepChange: (Int) -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case 0:
                ChildIntroView(onContinue: { onStepChange(1) })
            case 1:
                PointsExplanationView(onContinue: { onStepChange(2) })
            case 2:
                RedeemingGuideView(onContinue: onComplete)
            default:
                ChildIntroView(onContinue: { onStepChange(1) })
            }
        }
    }
}

/// Step 1: Child introduction
struct ChildIntroView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                VStack(spacing: 16) {
                    Text("Welcome! Let's Learn and Earn Rewards!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Use learning apps to earn points, then spend them to unlock fun time!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

/// Step 2: Points explanation
struct PointsExplanationView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.title)
                    }
                }
                .font(.system(size: 30))
                
                VStack(spacing: 16) {
                    Text("Earning Points")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("You earn 1 point for every minute you use learning apps like Khan Academy or Duolingo")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(.green)
                        Text("Khan Academy")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(.green)
                        Text("Duolingo")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(.green)
                        Text("Brilliant")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

/// Step 3: Redeeming guide
struct RedeemingGuideView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text("Redeeming Rewards")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Save your points to unlock entertainment apps like YouTube or games")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    RewardExampleRow(
                        icon: "tv.fill",
                        appName: "YouTube",
                        points: 15,
                        time: 15
                    )
                    
                    RewardExampleRow(
                        icon: "gamecontroller.fill",
                        appName: "Minecraft",
                        points: 30,
                        time: 30
                    )
                    
                    RewardExampleRow(
                        icon: "music.note.tv",
                        appName: "Spotify",
                        points: 20,
                        time: 20
                    )
                }
                .padding(.horizontal)
                
                Text("The more you learn, the more fun you can have!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

/// Reward example row component
struct RewardExampleRow: View {
    let icon: String
    let appName: String
    let points: Int
    let time: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(points) points = \(time) minutes")
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    ChildOnboardingView(step: 0, onStepChange: { _ in }, onComplete: {})
}