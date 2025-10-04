import SwiftUI

/// Enhanced recent activity row with better styling
struct EnhancedRecentActivityRow: View {
    let childName: String
    let activity: String
    let points: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(childName.prefix(1))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(childName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(points)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                
                Text(activity)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}