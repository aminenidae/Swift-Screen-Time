import SwiftUI

/// Enhanced child progress card with better visual design
struct EnhancedChildProgressCard: View {
    let name: String
    let points: Int
    let learningMinutes: Int
    let streak: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Child avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(name.prefix(1))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            // Progress information
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(points) pts")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(learningMinutes) min")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(streak) days")
                            .font(.subheadline)
                    }
                }
            }
            
            Spacer()
            
            // Quick action button
            Button(action: {
                // Navigate to child settings
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}