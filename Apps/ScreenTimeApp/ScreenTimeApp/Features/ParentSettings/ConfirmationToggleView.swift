import SwiftUI

/// A toggle view that requires confirmation for enabling certain settings
struct ConfirmationToggleView: View {
    let title: String
    let description: String
    let confirmationTitle: String
    let confirmationMessage: String
    let confirmationButton: String
    
    @Binding var isOn: Bool
    @State private var showingConfirmation = false
    
    init(
        title: String,
        description: String = "",
        confirmationTitle: String = "Confirm Change",
        confirmationMessage: String = "Are you sure you want to make this change?",
        confirmationButton: String = "Confirm",
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.description = description
        self.confirmationTitle = confirmationTitle
        self.confirmationMessage = confirmationMessage
        self.confirmationButton = confirmationButton
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isOn) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: isOn) { newValue in
                if newValue && !showingConfirmation {
                    // Temporarily revert the change until confirmation
                    isOn = false
                    showingConfirmation = true
                }
            }
            .alert(confirmationTitle, isPresented: $showingConfirmation) {
                Button("Cancel") {
                    // Keep the toggle off
                }
                Button(confirmationButton) {
                    // Confirm the change
                    isOn = true
                }
            } message: {
                Text(confirmationMessage)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    Form {
        ConfirmationToggleView(
            title: "Enable Bedtime Restrictions",
            description: "Restrict device usage during bedtime hours",
            confirmationTitle: "Enable Bedtime Restrictions",
            confirmationMessage: "This will restrict your child's device usage during bedtime hours. Are you sure you want to enable this?",
            confirmationButton: "Enable",
            isOn: .constant(false)
        )
        
        ConfirmationToggleView(
            title: "Enable Downtime",
            description: "Schedule daily downtime for device usage",
            confirmationTitle: "Enable Downtime",
            confirmationMessage: "This will schedule daily downtime for your child's device. Are you sure you want to enable this?",
            confirmationButton: "Enable",
            isOn: .constant(false)
        )
    }
}