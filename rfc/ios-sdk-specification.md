# iOS SDK Specification - Invite Service

## Project Overview

**Project Name:** InviteKit (iOS SDK)
**Purpose:** Native iOS SDK for the Invite Service, providing seamless invite link generation and attribution tracking using App Clips
**Target Platforms:** iOS 14+, iPadOS 14+
**Language:** Swift 5.5+
**Distribution:** Swift Package Manager

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [Core Components](#3-core-components)
4. [App Clips Integration](#4-app-clips-integration)
5. [API Specification](#5-api-specification)
6. [Data Models](#6-data-models)
7. [Network Layer](#7-network-layer)
8. [Storage](#8-storage)
9. [Testing Strategy](#9-testing-strategy)
10. [Demo Application](#10-demo-application)
11. [Documentation](#11-documentation)
12. [Deployment](#12-deployment)

---

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────┐
│           Developer's App                    │
│  ┌────────────────────────────────────┐    │
│  │        InviteKit Framework          │    │
│  │  ┌──────────────┬────────────────┐ │    │
│  │  │ Public API   │  Storage Layer │ │    │
│  │  ├──────────────┼────────────────┤ │    │
│  │  │ Network      │  App Group     │ │    │
│  │  │ Client       │  Manager       │ │    │
│  │  └──────────────┴────────────────┘ │    │
│  └────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
                    │
                    ↓
        ┌───────────────────────┐
        │   Invite Service API   │
        └───────────────────────┘

┌─────────────────────────────────────────────┐
│           App Clip Target                    │
│  ┌────────────────────────────────────┐    │
│  │      CN1InviteKit Framework         │    │
│  │  ┌──────────────┬────────────────┐ │    │
│  │  │ URL Parser   │  Storage Layer │ │    │
│  │  ├──────────────┼────────────────┤ │    │
│  │  │ UI Helpers   │  StoreKit      │ │    │
│  │  │              │  Integration   │ │    │
│  │  └──────────────┴────────────────┘ │    │
│  └────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### 1.2 Key Design Principles

1. **Separation of Concerns**: Main app SDK and App Clip SDK are separate but share common storage
2. **Minimal Dependencies**: No external dependencies except Apple frameworks
3. **Privacy-First**: No data collection beyond what's needed for attribution
4. **Developer-Friendly**: Simple API, comprehensive error handling, async/await support
5. **Testable**: Protocols and dependency injection for easy testing

---

## 2. Project Structure

```
invite-friend-ios-sdk/
├── Sources/
│   ├── InviteKit/                      # Main SDK for full app
│   │   ├── InviteKit.swift            # Main entry point
│   │   ├── API/
│   │   │   ├── InviteAPIClient.swift
│   │   │   ├── InviteEndpoints.swift
│   │   │   └── APIError.swift
│   │   ├── Models/
│   │   │   ├── InviteResult.swift
│   │   │   ├── InviteConfig.swift
│   │   │   └── InviteEvent.swift
│   │   ├── Storage/
│   │   │   ├── AppGroupStorage.swift
│   │   │   └── InviteStorageProtocol.swift
│   │   └── Utils/
│   │       ├── Logger.swift
│   │       └── URLBuilder.swift
│   │
│   └── CN1InviteKit/                   # App Clip SDK
│       ├── CN1InviteKit.swift         # App Clip entry point
│       ├── InviteURLParser.swift
│       ├── AppClipStorage.swift
│       └── StoreKitHelper.swift
│
├── Tests/
│   ├── InviteKitTests/
│   │   ├── APIClientTests.swift
│   │   ├── StorageTests.swift
│   │   └── ModelTests.swift
│   └── CN1InviteKitTests/
│       ├── URLParserTests.swift
│       └── StorageTests.swift
│
├── Examples/
│   ├── InviteKitDemo/                  # Full demo app
│   │   ├── InviteKitDemo/
│   │   ├── InviteKitDemoClip/         # App Clip target
│   │   └── Shared/                     # Shared code
│   └── README.md
│
├── Documentation/
│   ├── GettingStarted.md
│   ├── APIReference.md
│   ├── AppClipGuide.md
│   └── Migration.md
│
├── Package.swift                       # Swift Package Manager manifest
├── README.md
├── LICENSE
└── rfc/
    └── ios-sdk-specification.md       # This file
```

---

## 3. Core Components

### 3.1 InviteKit (Main SDK)

**Purpose:** Primary SDK for the full app to create invite links and check for attribution.

**Key Responsibilities:**
- API communication with Invite Service
- Invite link creation
- Attribution checking via App Group storage
- Event recording
- Configuration management

### 3.2 CN1InviteKit (App Clip SDK)

**Purpose:** Lightweight SDK for App Clips to parse invite URLs and store attribution data.

**Key Responsibilities:**
- URL parsing and validation
- Extract invite parameters from invocation URL
- Store attribution data in shared App Group
- Present StoreKit overlay for app download
- Optional UI helpers for invite acceptance flow

---

## 4. App Clips Integration

### 4.1 App Clip Flow

```
User Taps Link
      ↓
iOS Launches App Clip
      ↓
App Clip Receives URL via NSUserActivity
      ↓
CN1InviteKit.parse(url)
      ↓
Extract referrerId, shortCode, metadata
      ↓
Store in App Group (UserDefaults)
      ↓
Show Invite UI (optional)
      ↓
Present StoreKit Overlay
      ↓
User Downloads Full App
      ↓
Full App Launches
      ↓
InviteKit.checkForInvite()
      ↓
Read from App Group
      ↓
Return InviteResult to Developer
      ↓
Record INSTALLED/ATTRIBUTED Events
      ↓
Clean Up App Group Storage
```

### 4.2 App Group Storage Schema

**Suite Name:** `group.{bundleId}.invite`

**Keys:**
- `invite.referrerId` - String: User who sent the invite
- `invite.shortCode` - String: Invite short code
- `invite.metadata` - String: JSON-encoded metadata dictionary
- `invite.createdAt` - String: ISO8601 timestamp
- `invite.version` - String: Schema version (currently "1.0")

**Example:**
```swift
let defaults = UserDefaults(suiteName: "group.com.example.myapp.invite")
defaults?.set("user123", forKey: "invite.referrerId")
defaults?.set("abc456", forKey: "invite.shortCode")
defaults?.set("{\"campaign\":\"summer2024\"}", forKey: "invite.metadata")
defaults?.set("2025-01-15T10:30:00Z", forKey: "invite.createdAt")
defaults?.set("1.0", forKey: "invite.version")
```

### 4.3 URL Format

**Invite URL:**
```
https://{project-slug}.cn1invite.com/i/{shortCode}?ref={referrerId}&meta={metadata}
```

**Example:**
```
https://myapp.cn1invite.com/i/abc123?ref=user456&meta=campaign:summer2024,source:email
```

**Query Parameters:**
- `ref` - referrerId (required)
- `meta` - comma-separated key:value pairs (optional)

---

## 5. API Specification

### 5.1 InviteKit Public API

#### Configure SDK

```swift
public class InviteKit {
    /// Configure the SDK with your API key
    /// Must be called before any other SDK methods
    public static func configure(apiKey: String)

    /// Configure with custom base URL (for testing)
    public static func configure(
        apiKey: String,
        baseURL: URL
    )
}
```

#### Create Invite Link

```swift
extension InviteKit {
    /// Create an invite link with optional metadata
    /// - Parameters:
    ///   - referrerId: Unique ID of the user sending the invite
    ///   - metadata: Optional key-value pairs (max 10 entries)
    /// - Returns: Full invite URL
    /// - Throws: InviteError if request fails
    public static func createInviteLink(
        referrerId: String,
        metadata: [String: String]? = nil
    ) async throws -> String

    /// Create an invite link with completion handler
    public static func createInviteLink(
        referrerId: String,
        metadata: [String: String]? = nil,
        completion: @escaping (Result<String, InviteError>) -> Void
    )
}
```

#### Check for Invite

```swift
extension InviteKit {
    /// Check if app was launched from an invite link
    /// Call this early in app initialization
    /// - Returns: InviteResult if invite found, nil otherwise
    /// - Throws: InviteError if check fails
    public static func checkForInvite() async throws -> InviteResult?

    /// Check for invite with completion handler
    public static func checkForInvite(
        completion: @escaping (Result<InviteResult?, InviteError>) -> Void
    )
}
```

#### Register Observer

```swift
extension InviteKit {
    /// Register an observer for invite resolution events
    /// Useful for handling delayed attribution
    /// - Parameter observer: Closure called when invite is resolved
    /// - Returns: Token to unregister observer
    public static func registerInviteObserver(
        _ observer: @escaping (InviteResult) -> Void
    ) -> InviteObserverToken

    /// Unregister an observer
    public static func unregister(_ token: InviteObserverToken)
}
```

#### Record Event (Optional)

```swift
extension InviteKit {
    /// Manually record an invite event
    /// Most events are recorded automatically
    /// - Parameters:
    ///   - shortCode: Invite short code
    ///   - eventType: Type of event to record
    public static func recordEvent(
        shortCode: String,
        eventType: InviteEventType
    ) async throws
}
```

### 5.2 CN1InviteKit Public API (App Clip)

```swift
public class CN1InviteKit {
    /// Parse invite data from App Clip invocation URL
    /// - Parameter url: URL from NSUserActivity
    /// - Returns: Parsed invite data
    /// - Throws: InviteError if URL is invalid
    public static func parseInviteURL(_ url: URL) throws -> InviteData

    /// Store invite data in shared App Group
    /// - Parameter invite: Invite data to store
    public static func storeInvite(_ invite: InviteData) throws

    /// Present StoreKit overlay for full app download
    /// - Parameter scene: Current window scene
    public static func presentFullAppOverlay(in scene: UIWindowScene)

    /// Convenience method: parse, store, and present overlay
    /// - Parameters:
    ///   - url: URL from NSUserActivity
    ///   - scene: Current window scene
    public static func handleInvite(
        url: URL,
        in scene: UIWindowScene
    ) throws
}
```

---

## 6. Data Models

### 6.1 InviteResult

```swift
public struct InviteResult {
    /// User who sent the invite
    public let referrerId: String

    /// Invite short code
    public let shortCode: String

    /// Custom metadata attached to invite
    public let metadata: [String: String]

    /// When the invite was created
    public let createdAt: Date
}
```

### 6.2 InviteData (App Clip)

```swift
public struct InviteData {
    public let referrerId: String
    public let shortCode: String
    public let metadata: [String: String]
    public let timestamp: Date
}
```

### 6.3 InviteConfig

```swift
public struct InviteConfig: Codable {
    public let appName: String
    public let iconURL: URL?
    public let accentColor: String
    public let inviteTitle: String
    public let inviteMessage: String
    public let acceptButtonText: String
    public let appStoreURL: URL?
    public let playStoreURL: URL?
    public let showPoweredBy: Bool
}
```

### 6.4 InviteError

```swift
public enum InviteError: Error {
    case notConfigured
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case validationError(String)
    case rateLimited(retryAfter: Int)
    case serverError(statusCode: Int, message: String?)
    case storageError(Error)
    case invalidURL
    case unauthorized

    public var localizedDescription: String { ... }
}
```

### 6.5 InviteEventType

```swift
public enum InviteEventType: String {
    case accepted = "ACCEPTED"
    case installed = "INSTALLED"
    case attributed = "ATTRIBUTED"
}
```

---

## 7. Network Layer

### 7.1 API Client

```swift
protocol InviteAPIClientProtocol {
    func createInvite(
        referrerId: String,
        metadata: [String: String]?
    ) async throws -> InviteResponse

    func getInvite(shortCode: String) async throws -> InviteDetailResponse

    func recordEvent(
        shortCode: String,
        eventType: InviteEventType
    ) async throws

    func getConfig() async throws -> InviteConfig

    func ping() async throws -> PingResponse
}

class InviteAPIClient: InviteAPIClientProtocol {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession

    init(apiKey: String, baseURL: URL, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    // Implementation...
}
```

### 7.2 Request/Response Models

```swift
// Create Invite
struct CreateInviteRequest: Codable {
    let referrerId: String
    let metadata: [String: String]?
}

struct InviteResponse: Codable {
    let inviteUrl: String
    let shortCode: String
    let createdAt: String
    let warning: String?
}

// Event Recording
struct RecordEventRequest: Codable {
    let eventType: String
    let platform: String = "IOS"
}

// Ping
struct PingResponse: Codable {
    let status: String
    let projectId: String
    let projectName: String
}
```

### 7.3 Endpoint URLs

```swift
enum InviteEndpoint {
    case ping
    case config
    case createInvite
    case getInvite(shortCode: String)
    case recordEvent(shortCode: String)

    func path() -> String {
        switch self {
        case .ping:
            return "/api/v1/sdk/ping"
        case .config:
            return "/api/v1/sdk/config"
        case .createInvite:
            return "/api/v1/sdk/invites"
        case .getInvite(let shortCode):
            return "/api/v1/sdk/invites/\(shortCode)"
        case .recordEvent(let shortCode):
            return "/api/v1/sdk/invites/\(shortCode)/events"
        }
    }
}
```

### 7.4 HTTP Headers

All requests must include:
```
X-API-Key: {apiKey}
Content-Type: application/json
User-Agent: InviteKit-iOS/{version}
```

---

## 8. Storage

### 8.1 Storage Protocol

```swift
protocol InviteStorageProtocol {
    func saveInvite(_ invite: InviteData) throws
    func loadInvite() throws -> InviteData?
    func clearInvite() throws
    func hasStoredInvite() -> Bool
}
```

### 8.2 App Group Storage Implementation

```swift
class AppGroupStorage: InviteStorageProtocol {
    private let suiteName: String
    private var defaults: UserDefaults

    init(bundleId: String) {
        self.suiteName = "group.\(bundleId).invite"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults with suite name: \(suiteName)")
        }
        self.defaults = defaults
    }

    func saveInvite(_ invite: InviteData) throws {
        defaults.set(invite.referrerId, forKey: "invite.referrerId")
        defaults.set(invite.shortCode, forKey: "invite.shortCode")

        if let jsonData = try? JSONEncoder().encode(invite.metadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            defaults.set(jsonString, forKey: "invite.metadata")
        }

        let formatter = ISO8601DateFormatter()
        defaults.set(formatter.string(from: invite.timestamp), forKey: "invite.createdAt")
        defaults.set("1.0", forKey: "invite.version")

        defaults.synchronize()
    }

    func loadInvite() throws -> InviteData? {
        guard let referrerId = defaults.string(forKey: "invite.referrerId"),
              let shortCode = defaults.string(forKey: "invite.shortCode") else {
            return nil
        }

        let metadataString = defaults.string(forKey: "invite.metadata")
        var metadata: [String: String] = [:]

        if let metadataString = metadataString,
           let jsonData = metadataString.data(using: .utf8) {
            metadata = (try? JSONDecoder().decode([String: String].self, from: jsonData)) ?? [:]
        }

        let createdAtString = defaults.string(forKey: "invite.createdAt")
        let formatter = ISO8601DateFormatter()
        let timestamp = createdAtString.flatMap { formatter.date(from: $0) } ?? Date()

        return InviteData(
            referrerId: referrerId,
            shortCode: shortCode,
            metadata: metadata,
            timestamp: timestamp
        )
    }

    func clearInvite() throws {
        defaults.removeObject(forKey: "invite.referrerId")
        defaults.removeObject(forKey: "invite.shortCode")
        defaults.removeObject(forKey: "invite.metadata")
        defaults.removeObject(forKey: "invite.createdAt")
        defaults.removeObject(forKey: "invite.version")
        defaults.synchronize()
    }

    func hasStoredInvite() -> Bool {
        return defaults.string(forKey: "invite.referrerId") != nil
    }
}
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

**Coverage Goals:** >80% code coverage

**Test Cases:**
- URL parsing and validation
- Storage save/load/clear operations
- API request building
- Response parsing
- Error handling
- Metadata encoding/decoding

### 9.2 Integration Tests

- End-to-end invite creation flow
- Attribution checking with mock storage
- API client with mock URLSession
- App Group storage between app and extension

### 9.3 Mock Objects

```swift
class MockInviteAPIClient: InviteAPIClientProtocol {
    var createInviteResult: Result<InviteResponse, InviteError>?
    var recordEventResult: Result<Void, InviteError>?

    // Implement protocol methods with mock behavior
}

class MockStorage: InviteStorageProtocol {
    var storedInvite: InviteData?
    var shouldThrowError = false

    // Implement protocol methods with mock behavior
}
```

### 9.4 UI Tests (Demo App)

- App Clip launch and URL handling
- Full app invite checking
- StoreKit overlay presentation
- Error state handling

---

## 10. Demo Application

### 10.1 Demo App Structure

**InviteKitDemo** - Full app demonstrating all SDK features
**InviteKitDemoClip** - App Clip showing invite acceptance flow

### 10.2 Demo App Features

1. **Configuration Screen**
   - Enter API key
   - Test connectivity (ping endpoint)

2. **Create Invite Screen**
   - Enter referrer ID
   - Add metadata key-value pairs
   - Generate invite link
   - Share via UIActivityViewController

3. **Attribution Screen**
   - Check for invite on launch
   - Display InviteResult if found
   - Show attribution history

4. **Settings Screen**
   - Clear stored invites
   - View SDK version
   - Toggle debug logging

### 10.3 App Clip Features

1. URL parsing and display
2. Invite acceptance UI
3. StoreKit overlay presentation
4. Error handling display

---

## 11. Documentation

### 11.1 Required Documentation

1. **Getting Started Guide**
   - Installation via Swift Package Manager
   - Basic integration steps
   - Xcode configuration (App Groups, Associated Domains)

2. **API Reference**
   - All public classes, methods, and properties
   - Code examples for each API
   - DocC documentation

3. **App Clip Integration Guide**
   - Creating App Clip target
   - Configuring capabilities
   - Handling invocation URLs
   - Presenting StoreKit overlay

4. **Migration Guide**
   - For future version updates
   - Breaking changes and deprecations

5. **Troubleshooting**
   - Common issues and solutions
   - Debug logging
   - Testing with test invites

### 11.2 Code Documentation

All public APIs must have:
- Summary description
- Parameter documentation
- Return value documentation
- Thrown errors documentation
- Usage examples

**Example:**
```swift
/// Creates an invite link for the specified user
///
/// Call this method when a user wants to invite friends to your app.
/// The invite link will include the referrer ID and any custom metadata you provide.
///
/// ```swift
/// let metadata = ["campaign": "summer2024", "source": "share_button"]
/// let inviteUrl = try await InviteKit.createInviteLink(
///     referrerId: "user123",
///     metadata: metadata
/// )
/// ```
///
/// - Parameters:
///   - referrerId: Unique identifier for the user sending the invite (max 255 characters)
///   - metadata: Optional custom data to include (max 10 key-value pairs)
/// - Returns: Full invite URL that can be shared
/// - Throws: `InviteError.notConfigured` if SDK hasn't been configured
///           `InviteError.validationError` if parameters are invalid
///           `InviteError.networkError` if request fails
public static func createInviteLink(
    referrerId: String,
    metadata: [String: String]? = nil
) async throws -> String
```

---

## 12. Deployment

### 12.1 Swift Package Manager

**Package.swift:**
```swift
// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "InviteKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "InviteKit",
            targets: ["InviteKit"]
        ),
        .library(
            name: "CN1InviteKit",
            targets: ["CN1InviteKit"]
        )
    ],
    targets: [
        .target(
            name: "InviteKit",
            dependencies: []
        ),
        .target(
            name: "CN1InviteKit",
            dependencies: []
        ),
        .testTarget(
            name: "InviteKitTests",
            dependencies: ["InviteKit"]
        ),
        .testTarget(
            name: "CN1InviteKitTests",
            dependencies: ["CN1InviteKit"]
        )
    ]
)
```

### 12.2 Version Numbering

Follow Semantic Versioning (SemVer):
- **MAJOR**: Breaking API changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

Example: `1.2.3`

### 12.3 Release Process

1. Update version in Package.swift
2. Update CHANGELOG.md
3. Run all tests
4. Create git tag: `git tag v1.2.3`
5. Push tag: `git push origin v1.2.3`
6. Create GitHub release with notes
7. Update documentation

### 12.4 CocoaPods Support (Optional)

**InviteKit.podspec:**
```ruby
Pod::Spec.new do |s|
  s.name             = 'InviteKit'
  s.version          = '1.0.0'
  s.summary          = 'iOS SDK for Invite Service'
  s.homepage         = 'https://github.com/yourorg/invite-friend-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'email@example.com' }
  s.source           = { :git => 'https://github.com/yourorg/invite-friend-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.5'

  s.source_files = 'Sources/InviteKit/**/*'

  s.frameworks = 'Foundation', 'UIKit'
end
```

---

## Appendix A: Server API Reference

See `invite-friend-server/rfc/sdk-requirements.md` for complete server API documentation.

**Key Endpoints:**
- `GET /api/v1/sdk/ping` - Health check
- `POST /api/v1/sdk/invites` - Create invite
- `GET /api/v1/sdk/invites/{shortCode}` - Get invite details
- `POST /api/v1/sdk/invites/{shortCode}/events` - Record event
- `GET /api/v1/sdk/config` - Get runtime configuration

## Appendix B: iOS Configuration Checklist

**Required Xcode Capabilities:**
- [ ] App Groups (both app and App Clip)
- [ ] Associated Domains (App Clip only)

**Info.plist Entries:**
- [ ] `NSUserActivityTypes` (App Clip)
- [ ] Privacy descriptions if using location/notifications

**Build Settings:**
- [ ] iOS Deployment Target: 14.0+
- [ ] Swift Language Version: 5.5+
- [ ] App Clip size: <15MB

## Appendix C: Testing Checklist

- [ ] Unit tests passing (>80% coverage)
- [ ] Integration tests passing
- [ ] Demo app builds and runs
- [ ] App Clip launches from URL
- [ ] Attribution works end-to-end
- [ ] Error handling works correctly
- [ ] Documentation builds (DocC)
- [ ] All public APIs documented

---

## Document Version

- **Version:** 1.0
- **Last Updated:** 2025-02-13
- **Author:** Invite Service Team
