# Getting Started

Install and configure InviteKit in your iOS application.

## Overview

This guide walks you through the initial setup of InviteKit, from installation to creating your first invite link.

## Installation

### Swift Package Manager

Add InviteKit to your project using Xcode:

1. Open **File → Add Package Dependencies**
2. Enter the repository URL
3. Add `InviteKit` to your main app target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/invite-friend-ios-sdk.git", from: "1.0.0")
]
```

## Configuration

### App Groups

Set up App Groups to share data with your App Clip:

1. Select your project in Xcode
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability
4. Create: `group.{your-bundle-id}.invite`

### SDK Initialization

Configure the SDK in your app's entry point:

```swift
import InviteKit

@main
struct MyApp: App {
    init() {
        InviteKit.configure(apiKey: "your-api-key")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Creating Your First Invite

```swift
import InviteKit

func shareInvite() async {
    do {
        let result = try await InviteKit.createInviteLink(
            referrerId: currentUser.id
        )

        // Share the URL
        if let url = result.inviteURL {
            await presentShareSheet(url: url)
        }
    } catch {
        print("Error: \(error)")
    }
}
```

## Next Steps

- Set up your App Clip for URL handling
- Implement attribution checking
- Record events for analytics
