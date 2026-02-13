import SwiftUI
import InviteKit

struct ContentView: View {
    var body: some View {
        TabView {
            CreateInviteView()
                .tabItem {
                    Label("Create", systemImage: "link.badge.plus")
                }

            AttributionView()
                .tabItem {
                    Label("Attribution", systemImage: "person.2")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
