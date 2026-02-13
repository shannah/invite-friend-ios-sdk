import SwiftUI
import InviteKit

@main
struct InviteKitDemoApp: App {

    init() {
        // Configure InviteKit with your API key
        // In a real app, you would use your actual API key
        InviteKit.configure(apiKey: "demo-api-key")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
