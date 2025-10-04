import SwiftUI

/// A reusable view for numeric settings with both slider and direct input controls
struct NumericSettingView: View {
    let title: String
    let description: String
    let unit: String
    let minValue: Double
    let maxValue: Double
    let step: Double
    let isInteger: Bool
    
    @Binding var value: Double
    @State private var isEditingDirectly = false
    @State private var directInputValue: String = ""
    
    init(
        title: String,
        description: String = "",
        unit: String = "",
        value: Binding<Double>,
        minValue: Double = 0,
        maxValue: Double = 100,
        step: Double = 1,
        isInteger: Bool = true
    ) {
        self.title = title
        self.description = description
        self.unit = unit
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.isInteger = isInteger
        self._directInputValue = State(initialValue: isInteger ? String(Int(value.wrappedValue)) : String(value.wrappedValue))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
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
                
                Spacer()
                
                Text("\(formattedValue) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            Slider(
                value: $value,
                in: minValue...maxValue,
                step: step
            ) {
                Text(title)
            }
            .accentColor(.blue)
            
            HStack {
                Text("\(minValue, specifier: isInteger ? "%.0f" : "%.1f") \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Edit") {
                    directInputValue = formattedValue
                    isEditingDirectly = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(maxValue, specifier: isInteger ? "%.0f" : "%.1f") \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isEditingDirectly) {
            NumericInputDialogView(
                title: title,
                unit: unit,
                value: $directInputValue,
                minValue: minValue,
                maxValue: maxValue,
                isInteger: isInteger
            ) { newValue in
                value = newValue
                isEditingDirectly = false
            }
        }
    }
    
    private var formattedValue: String {
        isInteger ? String(Int(value)) : String(format: "%.1f", value)
    }
}

/// Dialog view for direct numeric input
struct NumericInputDialogView: View {
    let title: String
    let unit: String
    @Binding var value: String
    let minValue: Double
    let maxValue: Double
    let isInteger: Bool
    let onSubmit: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter value", text: $value)
                        .keyboardType(isInteger ? .numberPad : .decimalPad)
                } footer: {
                    Text("Value must be between \(minValue, specifier: isInteger ? "%.0f" : "%.1f") and \(maxValue, specifier: isInteger ? "%.0f" : "%.1f") \(unit)")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let numericValue = Double(value) {
                            let clampedValue = max(minValue, min(maxValue, numericValue))
                            onSubmit(clampedValue)
                        }
                        dismiss()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let numericValue = Double(value) else { return false }
        return numericValue >= minValue && numericValue <= maxValue
    }
}

#Preview {
    NavigationStack {
        Form {
            NumericSettingView(
                title: "Daily Learning Time",
                description: "Set the target daily learning time for your child",
                unit: "minutes",
                value: .constant(60),
                minValue: 15,
                maxValue: 240,
                step: 15
            )
            
            NumericSettingView(
                title: "Points per Minute",
                description: "Number of points earned per minute of educational app usage",
                unit: "points",
                value: .constant(1.5),
                minValue: 0.5,
                maxValue: 5.0,
                step: 0.5,
                isInteger: false
            )
        }
    }
}