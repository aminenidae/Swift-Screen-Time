import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Screen Time Rewards")
                .font(.title)
                .padding()
            
            Text("Debug App")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}