import SwiftUI

/// Main parent dashboard view with family overview, activity, and settings tabs
struct ParentMainView: View {
    var body: some View {
        TabView {
            // Family Overview Tab
            FamilyOverviewView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Family")
                }

            // Activity Tab
            ActivityView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Activity")
                }

            // Settings Tab
            ParentSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}

#if DEBUG
struct ParentMainView_Previews: PreviewProvider {
    static var previews: some View {
        ParentMainView()
    }
}
#endif