# API Reference

Complete API documentation for InviteKit and CN1InviteKit.

## InviteKit (Main App SDK)

### Configuration

#### `configure(apiKey:)`

Configures the SDK with your API key using the default server URL.

```swift
public static func configure(apiKey: String)
```

**Parameters:**
- `apiKey`: Your InviteKit API key

**Example:**
```swift
InviteKit.configure(apiKey: "ik_live_abc123...")
```

---

#### `configure(apiKey:baseURL:)`

Configures the SDK with a custom server URL.

```swift
public static func configure(apiKey: String, baseURL: URL)
```

**Parameters:**
- `apiKey`: Your InviteKit API key
- `baseURL`: Custom API server URL

**Example:**
```swift
InviteKit.configure(
    apiKey: "ik_live_abc123...",
    baseURL: URL(string: "https://your-server.com")!
)
```

---

### Invite Creation

#### `createInviteLink(referrerId:metadata:)` (async)

Creates a new invite link.

```swift
public static func createInviteLink(
    referrerId: String,
    metadata: [String: String]? = nil
) async throws -> InviteResult
```

**Parameters:**
- `referrerId`: Unique identifier for the referring user
- `metadata`: Optional dictionary of custom metadata

**Returns:** `InviteResult` containing the created invite

**Throws:** `InviteError`

**Example:**
```swift
let invite = try await InviteKit.createInviteLink(
    referrerId: "user123",
    metadata: ["campaign": "launch", "reward": "premium"]
)
print("Share: \(invite.inviteURL!)")
```

---

#### `createInviteLink(referrerId:metadata:completion:)` (callback)

Creates a new invite link using a completion handler.

```swift
public static func createInviteLink(
    referrerId: String,
    metadata: [String: String]? = nil,
    completion: @escaping (Result<InviteResult, InviteError>) -> Void
)
```

**Example:**
```swift
InviteKit.createInviteLink(referrerId: "user123") { result in
    switch result {
    case .success(let invite):
        print("Created: \(invite.shortCode)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

---

### Attribution

#### `checkForInvite()`

Checks for stored invite attribution data.

```swift
public static func checkForInvite() -> InviteResult?
```

**Returns:** `InviteResult` if attribution exists, `nil` otherwise

**Example:**
```swift
if let invite = InviteKit.checkForInvite() {
    print("Referred by: \(invite.referrerId)")
}
```

---

#### `clearInvite()`

Clears any stored invite attribution data.

```swift
public static func clearInvite()
```

**Example:**
```swift
// After processing attribution
InviteKit.clearInvite()
```

---

### Event Recording

#### `recordEvent(shortCode:eventType:)` (async)

Records an event for tracking.

```swift
public static func recordEvent(
    shortCode: String,
    eventType: InviteEventType
) async throws
```

**Parameters:**
- `shortCode`: The invite's short code
- `eventType`: Type of event to record

**Throws:** `InviteError`

**Example:**
```swift
try await InviteKit.recordEvent(
    shortCode: "abc123",
    eventType: .attributed
)
```

---

#### `recordEvent(shortCode:eventType:completion:)` (callback)

Records an event using a completion handler.

```swift
public static func recordEvent(
    shortCode: String,
    eventType: InviteEventType,
    completion: @escaping (Result<Void, InviteError>) -> Void
)
```

---

### Observer Pattern

#### `registerInviteObserver(_:)`

Registers an observer for invite attribution changes.

```swift
@discardableResult
public static func registerInviteObserver(
    _ observer: @escaping (InviteResult) -> Void
) -> ObservationToken
```

**Returns:** `ObservationToken` to manage the observation

**Example:**
```swift
let token = InviteKit.registerInviteObserver { invite in
    print("New attribution: \(invite.referrerId)")
}

// Later, to stop observing:
token.cancel()
```

---

## CN1InviteKit (App Clip SDK)

### Configuration

#### `configure(appStoreId:)`

Configures the App Clip SDK with your App Store ID.

```swift
public static func configure(appStoreId: String)
```

**Parameters:**
- `appStoreId`: Your app's App Store ID (numeric string)

**Example:**
```swift
CN1InviteKit.configure(appStoreId: "123456789")
```

---

### URL Handling

#### `parseInviteURL(_:)`

Parses an invite URL and extracts data.

```swift
public static func parseInviteURL(_ url: URL) -> InviteData?
```

**Parameters:**
- `url`: The invite URL to parse

**Returns:** `InviteData` if valid, `nil` otherwise

**Example:**
```swift
let url = URL(string: "https://app.cn1invite.com/i/abc123?ref=user456")!
if let invite = CN1InviteKit.parseInviteURL(url) {
    print("Referrer: \(invite.referrerId)")
    print("Code: \(invite.shortCode)")
}
```

---

#### `storeInvite(_:)`

Stores invite data in App Groups.

```swift
@discardableResult
public static func storeInvite(_ invite: InviteData) -> Bool
```

**Parameters:**
- `invite`: The invite data to store

**Returns:** `true` if storage succeeded

**Example:**
```swift
if let invite = CN1InviteKit.parseInviteURL(url) {
    CN1InviteKit.storeInvite(invite)
}
```

---

#### `getStoredInvite()`

Retrieves stored invite data.

```swift
public static func getStoredInvite() -> InviteData?
```

**Returns:** Stored `InviteData` or `nil`

---

#### `handleInvite(url:in:)`

Convenience method that parses, stores, and presents overlay.

```swift
@available(iOS 14.0, *)
@discardableResult
public static func handleInvite(
    url: URL,
    in windowScene: UIWindowScene
) -> InviteData?
```

**Parameters:**
- `url`: The invite URL
- `windowScene`: Window scene for overlay presentation

**Returns:** Parsed `InviteData` or `nil`

**Example:**
```swift
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
    if let url = activity.webpageURL,
       let scene = UIApplication.shared.connectedScenes
           .compactMap({ $0 as? UIWindowScene }).first {
        CN1InviteKit.handleInvite(url: url, in: scene)
    }
}
```

---

### StoreKit Overlay

#### `presentFullAppOverlay(in:)`

Presents the App Store overlay for full app installation.

```swift
@available(iOS 14.0, *)
public static func presentFullAppOverlay(in windowScene: UIWindowScene)
```

**Example:**
```swift
if let scene = UIApplication.shared.connectedScenes
    .compactMap({ $0 as? UIWindowScene }).first {
    CN1InviteKit.presentFullAppOverlay(in: scene)
}
```

---

#### `dismissFullAppOverlay(in:)`

Dismisses the App Store overlay.

```swift
@available(iOS 14.0, *)
public static func dismissFullAppOverlay(in windowScene: UIWindowScene)
```

---

## Data Types

### InviteResult

Result of creating an invite or checking attribution.

```swift
public struct InviteResult: Codable, Equatable {
    public let referrerId: String
    public let shortCode: String
    public let metadata: [String: String]?
    public let createdAt: Date
    public var inviteURL: URL?
}
```

---

### InviteData

Invite data parsed from a URL (App Clip).

```swift
public struct InviteData: Codable, Equatable {
    public let referrerId: String
    public let shortCode: String
    public let metadata: [String: String]?
    public let createdAt: Date
}
```

---

### InviteError

Error types that can occur.

```swift
public enum InviteError: Error {
    case notConfigured
    case invalidAPIKey
    case networkError(Error)
    case rateLimited
    case serverError(statusCode: Int, message: String?)
    case inviteNotFound
    case invalidParameters(String)
    case unknown(String)
}
```

---

### InviteEventType

Types of events that can be recorded.

```swift
public enum InviteEventType: String, Codable {
    case accepted    // Link was opened
    case installed   // App was installed
    case attributed  // Attribution was processed
}
```

---

### InviteConfig

Configuration data from the server.

```swift
public struct InviteConfig: Codable, Equatable {
    public let projectId: String
    public let projectSlug: String
    public let appName: String
    public let isActive: Bool
}
```

---

### ObservationToken

Token for managing observations.

```swift
public final class ObservationToken {
    public func cancel()
}
```

---

## Protocols

### InviteStorageProtocol

Protocol for custom storage implementations.

```swift
public protocol InviteStorageProtocol {
    func saveInvite(_ invite: InviteResult)
    func getInvite() -> InviteResult?
    func clearInvite()
    func hasInvite() -> Bool
}
```

---

### InviteAPIClientProtocol

Protocol for custom API client implementations.

```swift
public protocol InviteAPIClientProtocol {
    func createInvite(referrerId: String, metadata: [String: String]?) async throws -> InviteResult
    func getInvite(shortCode: String) async throws -> InviteResult
    func recordEvent(shortCode: String, eventType: InviteEventType) async throws
    func getConfig() async throws -> InviteConfig
    func ping() async -> Bool
}
```

Use these protocols to create mock implementations for testing.
