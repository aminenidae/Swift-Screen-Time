import SwiftUI

/// Empty state for when no children are found
struct EmptyChildrenState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("No children found in Family Sharing")
                .font(.headline)
                .foregroundColor(.secondary)
            
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}