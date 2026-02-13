# InviteKit iOS SDK

Native iOS SDK for creating invite links and tracking referral attribution using App Clips.

[![Swift 5.5+](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![iOS 14+](https://img.shields.io/badge/iOS-14.0+-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Overview

InviteKit enables iOS developers to implement "invite a friend" functionality with reliable referral attribution that survives app installation. It uses App Clips for deterministic attribution without fingerprinting or tracking.

### How It Works

1. **User A** creates an invite link in your app
2. **User B** taps the link, launching your App Clip
3. The App Clip stores attribution data in App Groups
4. **User B** installs the full app
5. Your app retrieves the attribution data and credits **User A**

## Features

- Simple async/await API for invite link creation
- App Clips integration for zero-friction invites
- Automatic attribution tracking via App Groups
- Swift Package Manager support
- iOS 14+ / macOS 11+ support
- No external dependencies (Apple frameworks only)
- Protocol-based design for easy testing

## Installation

### Swift Package Manager

Add InviteKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/invite-friend-ios-sdk.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version and add to your target

### Targets

| Library | Use Case |
|---------|----------|
| `InviteKit` | Main app - full SDK functionality |
| `CN1InviteKit` | App Clip - lightweight URL parsing and storage |

## Quick Start

### Main App Setup

```swift
import InviteKit

// 1. Configure SDK (typically in AppDelegate or App init)
InviteKit.configure(apiKey: "your-api-key")

// 2. Create an invite link
let result = try await InviteKit.createInviteLink(
    referrerId: "user123",
    metadata: ["campaign": "summer2024"]
)
print("Share this link: \(result.inviteURL)")

// 3. Check for attribution (e.g., on app launch)
if let invite = InviteKit.checkForInvite() {
    print("Referred by: \(invite.referrerId)")

    // Record the attribution event
    try await InviteKit.recordEvent(
        shortCode: invite.shortCode,
        eventType: .attributed
    )
}
```

### App Clip Setup

```swift
import SwiftUI
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
                    if let url = activity.webpageURL,
                       let windowScene = UIApplication.shared.connectedScenes
                           .compactMap({ $0 as? UIWindowScene }).first {
                        CN1InviteKit.handleInvite(url: url, in: windowScene)
                    }
                }
        }
    }
}
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](Documentation/GettingStarted.md) | Installation and basic setup |
| [App Clip Integration](Documentation/AppClipIntegration.md) | Complete App Clip setup guide |
| [API Reference](Documentation/APIReference.md) | Full API documentation |
| [Troubleshooting](Documentation/Troubleshooting.md) | Common issues and solutions |

## Demo App

A complete demo application is included in `Examples/InviteKitDemo/`. See the [demo README](Examples/InviteKitDemo/README.md) for setup instructions.

## API Overview

### InviteKit (Main App)

```swift
// Configuration
InviteKit.configure(apiKey: String)
InviteKit.configure(apiKey: String, baseURL: URL)

// Create Invites
InviteKit.createInviteLink(referrerId: String, metadata: [String: String]?) async throws -> InviteResult

// Attribution
InviteKit.checkForInvite() -> InviteResult?
InviteKit.clearInvite()

// Events
InviteKit.recordEvent(shortCode: String, eventType: InviteEventType) async throws
```

### CN1InviteKit (App Clip)

```swift
// Configuration
CN1InviteKit.configure(appStoreId: String)

// URL Handling
CN1InviteKit.parseInviteURL(_ url: URL) -> InviteData?
CN1InviteKit.storeInvite(_ invite: InviteData) -> Bool
CN1InviteKit.handleInvite(url: URL, in: UIWindowScene) -> InviteData?

// StoreKit Overlay
CN1InviteKit.presentFullAppOverlay(in: UIWindowScene)
CN1InviteKit.dismissFullAppOverlay(in: UIWindowScene)
```

## Requirements

- iOS 14.0+ / macOS 11.0+
- Swift 5.5+
- Xcode 13.0+

### Capabilities Required

| Capability | Target | Purpose |
|------------|--------|---------|
| App Groups | Both | Share data between app and App Clip |
| Associated Domains | App Clip | Handle invite URLs |

## Project Structure

```
invite-friend-ios-sdk/
├── Package.swift
├── Sources/
│   ├── InviteKit/           # Main SDK
│   │   ├── InviteKit.swift  # Public API
│   │   ├── API/             # Network layer
│   │   ├── Models/          # Data models
│   │   ├── Storage/         # App Group storage
│   │   └── Utils/           # Logging utilities
│   └── CN1InviteKit/        # App Clip SDK
│       ├── CN1InviteKit.swift
│       ├── Models/
│       ├── Storage/
│       └── Utils/
├── Tests/
│   ├── InviteKitTests/
│   └── CN1InviteKitTests/
├── Examples/
│   └── InviteKitDemo/       # Demo app with App Clip
├── Documentation/
└── rfc/
    └── ios-sdk-specification.md
```

## Testing

Run tests with:

```bash
swift test
```

Current test coverage: 19 tests covering configuration, API calls, storage, and URL parsing.

## Related Projects

- [invite-friend-server](../invite-friend-server/) - Backend API
- [invite-dashboard](../invite-dashboard/) - Web dashboard
- [invite-friend-android-sdk](../invite-friend-android-sdk/) - Android SDK

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read the RFC specification before submitting PRs.
