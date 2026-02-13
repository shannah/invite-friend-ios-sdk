import SwiftUI
import CN1InviteKit

@main
struct InviteKitDemoClipApp: App {

    init() {
        // Configure CN1InviteKit with your App Store ID
        // Replace with your actual App Store ID
        CN1InviteKit.configure(appStoreId: "123456789")
    }

    var body: some Scene {
        WindowGroup {
            AppClipContentView()
        }
    }
}
