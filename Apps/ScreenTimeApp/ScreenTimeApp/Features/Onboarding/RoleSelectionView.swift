import SwiftUI

/// Role selection view for onboarding
struct RoleSelectionView: View {
    @Binding var selectedRole: String
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Who is using this device?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Role selection cards
            VStack(spacing: 24) {
                RoleCard(
                    icon: "person.2.circle.fill",
                    title: "I'm a Parent",
                    description: "Set up family members and manage rewards",
                    isSelected: selectedRole == "parent"
                ) {
                    selectedRole = "parent"
                }
                
                RoleCard(
                    icon: "person.circle.fill",
                    title: "I'm a Child",
                    description: "Earn points and unlock rewards",
                    isSelected: selectedRole == "child"
                ) {
                    selectedRole = "child"
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedRole.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(selectedRole.isEmpty)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

/// Reusable role card component
struct RoleCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : (title.contains("Parent") ? .blue : .green))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? (title.contains("Parent") ? Color.blue : Color.green) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView(selectedRole: .constant("parent"), onContinue: {})
}