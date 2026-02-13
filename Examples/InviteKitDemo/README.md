# InviteKit Demo App

A demonstration application showcasing the InviteKit SDK for iOS, including both the main app and App Clip integration.

## Features

### Main App
- **Create Invite**: Generate shareable invite links with referrer IDs and metadata
- **Attribution**: Check for and display attribution data from App Clip invites
- **Settings**: Configure API settings and debug options

### App Clip
- **URL Handling**: Automatically parses invite URLs when the App Clip is opened
- **Attribution Storage**: Stores invite data in App Groups for the main app
- **Full App Overlay**: Presents StoreKit overlay to encourage full app download

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 14.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optional, for project generation)

### Option 1: Using XcodeGen

1. Install XcodeGen if you haven't already:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   cd Examples/InviteKitDemo
   xcodegen generate
   ```

3. Open the generated project:
   ```bash
   open InviteKitDemo.xcodeproj
   ```

### Option 2: Manual Xcode Setup

1. Create a new Xcode project (App template)
2. Add the InviteKit package dependency:
   - File > Add Package Dependencies
   - Add local package: `../..` (the root SDK directory)
3. Create an App Clip target
4. Configure App Groups capability on both targets
5. Add the source files to appropriate targets

## Configuration

### App Groups

Both the main app and App Clip must share the same App Group to pass attribution data:

1. Enable "App Groups" capability in both targets
2. Create an App Group: `group.{your-bundle-id}.invite`
3. Add to both targets' entitlements

### Associated Domains (App Clip)

For the App Clip to handle invite URLs:

1. Enable "Associated Domains" capability
2. Add domain: `appclips:yourdomain.cn1invite.com`
3. Configure your server's `apple-app-site-association` file

### API Configuration

Update the API key in `InviteKitDemoApp.swift`:

```swift
InviteKit.configure(apiKey: "your-actual-api-key")
```

For the App Clip, update the App Store ID in `InviteKitDemoClipApp.swift`:

```swift
CN1InviteKit.configure(appStoreId: "your-app-store-id")
```

## Testing the Flow

### Testing Invite Creation

1. Run the main app
2. Go to "Create" tab
3. Enter a referrer ID (e.g., "user123")
4. Optionally add a campaign name
5. Tap "Create Invite Link"
6. Share the generated link

### Testing Attribution (Simulated)

1. Run the main app
2. Go to "Settings" tab
3. Tap "Simulate Invite Attribution"
4. Go to "Attribution" tab to see the simulated data

### Testing App Clip Flow

1. Build and run the App Clip target on a device
2. Use an invite URL to launch the App Clip:
   ```
   https://demo.cn1invite.com/i/abc123?ref=user456
   ```
3. The App Clip will parse and store the invite
4. Install the main app to see the attribution data

## Project Structure

```
InviteKitDemo/
├── project.yml                    # XcodeGen configuration
├── InviteKitDemo/                 # Main app target
│   ├── InviteKitDemoApp.swift     # App entry point
│   ├── ContentView.swift          # Tab-based main view
│   ├── Views/
│   │   ├── CreateInviteView.swift # Invite creation UI
│   │   ├── AttributionView.swift  # Attribution display UI
│   │   └── SettingsView.swift     # Settings & debug UI
│   ├── Info.plist
│   └── InviteKitDemo.entitlements
└── InviteKitDemoClip/             # App Clip target
    ├── InviteKitDemoClipApp.swift # App Clip entry point
    ├── AppClipContentView.swift   # App Clip UI
    ├── Info.plist
    └── InviteKitDemoClip.entitlements
```

## Troubleshooting

### Attribution data not appearing
- Verify both targets use the same App Group identifier
- Check that App Groups capability is enabled
- Ensure the App Group exists in your Apple Developer account

### App Clip not handling URLs
- Verify Associated Domains are configured correctly
- Check the `apple-app-site-association` file on your server
- Test with the App Clip diagnostics in Settings > Developer

### Build errors with package dependency
- Clean build folder (Cmd+Shift+K)
- Reset package caches (File > Packages > Reset Package Caches)
- Ensure the SDK path in `project.yml` is correct
