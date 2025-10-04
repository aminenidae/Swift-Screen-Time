import SwiftUI

struct AccountTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    UserDefaults.standard.set("child", forKey: "userRole")
                }) {
                    Label("Switch to Child Profile", systemImage: "person.fill")
                        .foregroundColor(.blue)
                }

                Button(action: {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                }) {
                    Label("Reset App", systemImage: "arrow.clockwise")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Account")
        }
    }
}

#Preview {
    AccountTabView()
}
