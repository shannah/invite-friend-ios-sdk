# App Clip Integration Guide

This guide explains how to set up an App Clip to handle invite URLs and pass attribution data to your main app.

## Overview

App Clips provide a lightweight way to handle invite links without requiring app installation. When a user taps an invite link:

1. The App Clip launches instantly
2. CN1InviteKit parses the URL and extracts attribution data
3. The data is stored in App Groups (shared with the main app)
4. A StoreKit overlay prompts the user to install the full app
5. When the full app is installed, it reads the attribution data

## Prerequisites

- An existing iOS app
- Apple Developer Program membership
- App configured for App Clips in App Store Connect

## Step 1: Create the App Clip Target

1. In Xcode, select **File → New → Target**
2. Choose **App Clip**
3. Name it (e.g., `YourAppClip`)
4. Ensure the bundle ID is `{main-app-bundle-id}.Clip`

## Step 2: Add CN1InviteKit Dependency

Add the `CN1InviteKit` library to your App Clip target:

1. Select your project in Xcode
2. Select the App Clip target
3. Go to **General → Frameworks, Libraries, and Embedded Content**
4. Add `CN1InviteKit`

Or update your Package.swift:

```swift
.target(
    name: "YourAppClip",
    dependencies: [
        .product(name: "CN1InviteKit", package: "invite-friend-ios-sdk")
    ]
)
```

## Step 3: Configure App Groups

Both targets must share the same App Group:

1. Select your project
2. For **both** main app and App Clip targets:
   - Go to **Signing & Capabilities**
   - Add **App Groups** capability
   - Add: `group.{your-bundle-id}.invite`

The App Group identifier must match in both targets.

## Step 4: Configure Associated Domains

Enable your App Clip to handle invite URLs:

1. Select the App Clip target
2. Go to **Signing & Capabilities**
3. Add **Associated Domains** capability
4. Add your domain: `appclips:{your-domain}.cn1invite.com`

### Server Configuration

On your server, create an `apple-app-site-association` file at `/.well-known/apple-app-site-association`:

```json
{
  "appclips": {
    "apps": [
      "TEAMID.com.yourcompany.yourapp.Clip"
    ]
  },
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": [
          "TEAMID.com.yourcompany.yourapp.Clip"
        ],
        "components": [
          {
            "/": "/i/*",
            "comment": "Matches invite URLs"
          }
        ]
      }
    ]
  }
}
```

Replace `TEAMID` with your Apple Team ID.

## Step 5: Implement the App Clip

### App Entry Point

```swift
import SwiftUI
import CN1InviteKit

@main
struct YourAppClip: App {
    init() {
        // Configure with your App Store ID
        // Find this in App Store Connect
        CN1InviteKit.configure(appStoreId: "123456789")
    }

    var body: some Scene {
        WindowGroup {
            AppClipContentView()
        }
    }
}
```

### Content View with URL Handling

```swift
import SwiftUI
import CN1InviteKit

struct AppClipContentView: View {
    @State private var inviteData: InviteData?
    @State private var status: String = "Waiting for invite..."

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Welcome!")
                .font(.title)

            Text(status)
                .foregroundColor(.secondary)

            if let invite = inviteData {
                VStack(alignment: .leading) {
                    Text("Invited by: \(invite.referrerId)")
                    Text("Code: \(invite.shortCode)")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            Spacer()

            Button("Get Full App") {
                presentAppOverlay()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            handleUserActivity(activity)
        }
        .onOpenURL { url in
            handleInviteURL(url)
        }
    }

    private func handleUserActivity(_ activity: NSUserActivity) {
        guard let url = activity.webpageURL else {
            status = "No URL in activity"
            return
        }
        handleInviteURL(url)
    }

    private func handleInviteURL(_ url: URL) {
        status = "Processing invite..."

        // Option 1: Manual step-by-step
        guard let invite = CN1InviteKit.parseInviteURL(url) else {
            status = "Invalid invite URL"
            return
        }

        if CN1InviteKit.storeInvite(invite) {
            inviteData = invite
            status = "Invite processed!"
            presentAppOverlay()
        } else {
            status = "Failed to store invite"
        }

        // Option 2: Convenience method (does all the above)
        // if let windowScene = getWindowScene() {
        //     inviteData = CN1InviteKit.handleInvite(url: url, in: windowScene)
        // }
    }

    private func presentAppOverlay() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        CN1InviteKit.presentFullAppOverlay(in: windowScene)
    }
}
```

## Step 6: Handle Attribution in Main App

In your main app, check for attribution:

```swift
import InviteKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure SDK
        InviteKit.configure(apiKey: "your-api-key")

        // Check for attribution from App Clip
        checkAttribution()

        return true
    }

    private func checkAttribution() {
        guard let invite = InviteKit.checkForInvite() else {
            print("No attribution from App Clip")
            return
        }

        print("User referred by: \(invite.referrerId)")

        // Process the referral
        processReferral(invite)

        // Record the event
        Task {
            try? await InviteKit.recordEvent(
                shortCode: invite.shortCode,
                eventType: .installed
            )
        }

        // Clear after processing
        InviteKit.clearInvite()
    }
}
```

## URL Format

Invite URLs follow this format:

```
https://{project-slug}.cn1invite.com/i/{shortCode}?ref={referrerId}&meta={base64-metadata}
```

| Component | Description |
|-----------|-------------|
| `project-slug` | Your project identifier |
| `shortCode` | Unique invite code |
| `ref` | Referrer's user ID |
| `meta` | Base64-encoded JSON metadata (optional) |

Example:
```
https://myapp.cn1invite.com/i/abc123?ref=user456&meta=eyJjYW1wYWlnbiI6InN1bW1lciJ9
```

## Testing

### Testing in Simulator

App Clips can be tested in the simulator:

1. Set the App Clip target as active scheme
2. Edit scheme → Run → Options
3. Under "App Clip URL", enter a test URL:
   ```
   https://myapp.cn1invite.com/i/test123?ref=testuser
   ```
4. Run the app

### Testing on Device

1. Build and install the App Clip on a device
2. In Settings → Developer → Local Experiences, add your App Clip
3. Configure with your test URL
4. Tap the link to launch

### Verifying App Group Storage

To verify data is being stored correctly:

```swift
// In App Clip - after storing
let defaults = UserDefaults(suiteName: "group.your-bundle-id.invite")
print("Stored referrerId: \(defaults?.string(forKey: "invite.referrerId") ?? "nil")")

// In Main App - check if data exists
if let invite = InviteKit.checkForInvite() {
    print("Found attribution: \(invite.referrerId)")
}
```

## Troubleshooting

### App Clip Not Launching

- Verify Associated Domains are configured correctly
- Check the `apple-app-site-association` file is served with correct MIME type
- Ensure the domain matches exactly

### Attribution Data Not Found

- Verify both targets use the same App Group identifier
- Check App Groups capability is enabled on both targets
- Ensure the App Group exists in your developer account

### StoreKit Overlay Not Showing

- Verify the App Store ID is correct
- The overlay won't show in simulator - test on device
- Ensure the app is published (or use TestFlight)

See [Troubleshooting Guide](Troubleshooting.md) for more solutions.
