# ``CN1InviteKit``

Lightweight SDK for handling invite URLs in App Clips.

## Overview

CN1InviteKit is designed for App Clips, providing minimal footprint while handling invite URL parsing and attribution storage. It shares data with the main app through App Groups.

### App Clip Setup

```swift
import CN1InviteKit

@main
struct MyAppClip: App {
    init() {
        CN1InviteKit.configure(appStoreId: "123456789")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    handleActivity(activity)
                }
        }
    }

    func handleActivity(_ activity: NSUserActivity) {
        guard let url = activity.webpageURL,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene }).first else { return }

        CN1InviteKit.handleInvite(url: url, in: scene)
    }
}
```

### URL Format

Invite URLs follow this format:
```
https://{slug}.cn1invite.com/i/{shortCode}?ref={referrerId}&meta={metadata}
```

## Topics

### Configuration

- ``CN1InviteKit/configure(appStoreId:)``

### URL Handling

- ``CN1InviteKit/parseInviteURL(_:)``
- ``CN1InviteKit/storeInvite(_:)``
- ``CN1InviteKit/handleInvite(url:in:)``
- ``CN1InviteKit/getStoredInvite()``

### StoreKit Integration

- ``CN1InviteKit/presentFullAppOverlay(in:)``
- ``CN1InviteKit/dismissFullAppOverlay(in:)``

### Data Types

- ``InviteData``
