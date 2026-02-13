# Getting Started with InviteKit

This guide walks you through installing and configuring InviteKit in your iOS application.

## Prerequisites

- Xcode 13.0 or later
- iOS 14.0+ deployment target
- Swift 5.5+
- An InviteKit API key (obtain from your dashboard)

## Installation

### Swift Package Manager (Recommended)

#### Using Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter the repository URL:
   ```
   https://github.com/anthropics/invite-friend-ios-sdk.git
   ```
4. Select your version requirements (e.g., "Up to Next Major Version" from 1.0.0)
5. Choose the target to add the library to:
   - Add `InviteKit` to your **main app** target
   - Add `CN1InviteKit` to your **App Clip** target (if applicable)

#### Using Package.swift

Add InviteKit to your package dependencies:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(
            url: "https://github.com/anthropics/invite-friend-ios-sdk.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "InviteKit", package: "invite-friend-ios-sdk")
            ]
        ),
        .target(
            name: "YourAppClip",
            dependencies: [
                .product(name: "CN1InviteKit", package: "invite-friend-ios-sdk")
            ]
        )
    ]
)
```

## Configuration

### 1. Configure App Groups

App Groups allow your main app and App Clip to share data. This is essential for attribution tracking.

1. In Xcode, select your project
2. Select your **main app** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability** and add **App Groups**
5. Create a new App Group: `group.{your-bundle-id}.invite`
6. Repeat for your **App Clip** target, using the same App Group

### 2. Initialize the SDK

#### Main App

In your `AppDelegate` or SwiftUI `App`:

```swift
import InviteKit

@main
struct YourApp: App {
    init() {
        // Configure with your API key
        InviteKit.configure(apiKey: "your-api-key")

        // Or with a custom base URL (for self-hosted servers)
        // InviteKit.configure(
        //     apiKey: "your-api-key",
        //     baseURL: URL(string: "https://your-server.com")!
        // )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### App Clip

```swift
import CN1InviteKit

@main
struct YourAppClip: App {
    init() {
        // Configure with your App Store ID
        CN1InviteKit.configure(appStoreId: "123456789")
    }

    var body: some Scene {
        WindowGroup {
            AppClipContentView()
        }
    }
}
```

## Basic Usage

### Creating an Invite Link

```swift
import InviteKit

func createInvite() async {
    do {
        // Create a simple invite
        let result = try await InviteKit.createInviteLink(
            referrerId: currentUser.id
        )

        // Share the invite URL
        shareURL(result.inviteURL)

    } catch let error as InviteError {
        // Handle specific errors
        switch error {
        case .notConfigured:
            print("SDK not configured")
        case .networkError(let underlying):
            print("Network error: \(underlying)")
        case .rateLimited:
            print("Too many requests, try again later")
        default:
            print("Error: \(error.localizedDescription)")
        }
    }
}

// With metadata
func createInviteWithMetadata() async throws -> InviteResult {
    return try await InviteKit.createInviteLink(
        referrerId: currentUser.id,
        metadata: [
            "campaign": "summer-promo",
            "source": "share-button"
        ]
    )
}
```

### Using Callback API

If you prefer callbacks over async/await:

```swift
InviteKit.createInviteLink(
    referrerId: currentUser.id,
    metadata: ["campaign": "test"]
) { result in
    switch result {
    case .success(let invite):
        print("Created invite: \(invite.shortCode)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Checking for Attribution

Check for attribution when your app launches or when appropriate:

```swift
func checkAttribution() {
    // Check if user was referred
    guard let invite = InviteKit.checkForInvite() else {
        print("No attribution found")
        return
    }

    print("User was referred by: \(invite.referrerId)")
    print("Invite code: \(invite.shortCode)")
    print("Created at: \(invite.createdAt)")

    if let metadata = invite.metadata {
        print("Campaign: \(metadata["campaign"] ?? "unknown")")
    }

    // Process the attribution (e.g., credit the referrer)
    processReferral(referrerId: invite.referrerId)

    // Record the attribution event
    Task {
        try? await InviteKit.recordEvent(
            shortCode: invite.shortCode,
            eventType: .attributed
        )
    }

    // Optionally clear the invite after processing
    InviteKit.clearInvite()
}
```

## Next Steps

- [App Clip Integration Guide](AppClipIntegration.md) - Set up your App Clip to handle invite URLs
- [API Reference](APIReference.md) - Complete API documentation
- [Troubleshooting](Troubleshooting.md) - Common issues and solutions

## Example Project

See the complete demo app in `Examples/InviteKitDemo/` for a working implementation including:

- Invite link creation with UI
- Attribution display
- App Clip with URL handling
- StoreKit overlay integration
