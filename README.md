# InviteKit - iOS SDK for Invite Service

Native iOS SDK providing seamless invite link generation and attribution tracking using App Clips.

## Overview

InviteKit enables iOS developers to implement "invite a friend" functionality with reliable referral attribution that survives app installation. Uses App Clips for deterministic attribution without fingerprinting.

## Features

- ✅ Simple API for invite link creation
- ✅ App Clips integration for zero-friction invites
- ✅ Automatic attribution tracking
- ✅ Swift Package Manager support
- ✅ iOS 14+ support
- ✅ No external dependencies (Apple frameworks only)

## Quick Start

```swift
import InviteKit

// 1. Configure SDK
InviteKit.configure(apiKey: "your_api_key")

// 2. Create invite link
let inviteUrl = try await InviteKit.createInviteLink(
    referrerId: "user123",
    metadata: ["campaign": "summer2024"]
)

// 3. Check for attribution
if let invite = try await InviteKit.checkForInvite() {
    print("Referred by: \(invite.referrerId)")
}
```

## Documentation

See **[rfc/ios-sdk-specification.md](rfc/ios-sdk-specification.md)** for complete specification including:

- Architecture overview
- Project structure
- API specification
- App Clips integration guide
- Native implementation details
- Testing strategy
- Deployment instructions

## Server API

This SDK communicates with the Invite Service API. See the server project for API documentation:
- Server: `../invite-friend-server/`
- Dashboard: `../invite-dashboard/`

## Related Projects

- **invite-friend-server** - Backend API
- **invite-dashboard** - Web dashboard
- **invite-friend-android-sdk** - Android SDK
- **invite-friend-cn1-sdk** - Codename One SDK
- **invite-friend-cli** - CLI tool

## Status

🚧 **Ready for Development** - RFC specification complete

## License

MIT
