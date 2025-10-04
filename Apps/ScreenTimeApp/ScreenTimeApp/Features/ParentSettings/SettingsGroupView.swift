import SwiftUI

/// A reusable view for organizing settings into collapsible groups
struct SettingsGroupView<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    @State private var isExpanded: Bool = true
    
    init(
        title: String,
        icon: String,
        isExpanded: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self._isExpanded = State(initialValue: isExpanded)
        self.content = content
    }
    
    var body: some View {
        Section {
            if isExpanded {
                content()
            }
        } header: {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    List {
        SettingsGroupView(
            title: "General Settings",
            icon: "gear",
            isExpanded: true
        ) {
            Text("Family Setup")
            Text("Family Controls")
            Text("Family Members")
            Text("Subscription")
        }
        
        SettingsGroupView(
            title: "Reward System",
            icon: "star.fill",
            isExpanded: false
        ) {
            Text("Learning App Points")
        }
    }
}