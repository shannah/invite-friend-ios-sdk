# ``InviteKit``

Create invite links and track referral attribution in your iOS app.

## Overview

InviteKit is a Swift SDK for implementing "invite a friend" functionality with reliable referral attribution. It uses App Clips for deterministic attribution that survives app installation.

### How It Works

1. A user creates an invite link in your app
2. The invitee taps the link, launching your App Clip
3. The App Clip stores attribution data in shared App Groups
4. When the invitee installs your app, it retrieves the attribution

### Getting Started

Configure the SDK early in your app's lifecycle:

```swift
import InviteKit

@main
struct MyApp: App {
    init() {
        InviteKit.configure(apiKey: "your-api-key")
    }
}
```

### Creating Invite Links

```swift
let result = try await InviteKit.createInviteLink(
    referrerId: "user123",
    metadata: ["campaign": "summer"]
)

// Share result.inviteURL with the user
```

### Checking Attribution

```swift
if let invite = InviteKit.checkForInvite() {
    print("Referred by: \(invite.referrerId)")

    // Process the referral
    creditReferrer(invite.referrerId)

    // Record the event
    try await InviteKit.recordEvent(
        shortCode: invite.shortCode,
        eventType: .attributed
    )
}
```

## Topics

### Configuration

- ``InviteKit/configure(apiKey:)``
- ``InviteKit/configure(apiKey:baseURL:)``

### Creating Invites

- ``InviteKit/createInviteLink(referrerId:metadata:)-7x9vt``
- ``InviteKit/createInviteLink(referrerId:metadata:completion:)``

### Attribution

- ``InviteKit/checkForInvite()``
- ``InviteKit/clearInvite()``
- ``InviteKit/registerInviteObserver(_:)``

### Event Recording

- ``InviteKit/recordEvent(shortCode:eventType:)-5kz8a``
- ``InviteKit/recordEvent(shortCode:eventType:completion:)``

### Data Types

- ``InviteResult``
- ``InviteError``
- ``InviteEventType``
- ``InviteConfig``
- ``ObservationToken``

### Protocols

- ``InviteStorageProtocol``
- ``InviteAPIClientProtocol``
