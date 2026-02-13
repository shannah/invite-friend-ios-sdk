# Troubleshooting Guide

Common issues and solutions when using InviteKit.

## Configuration Issues

### "InviteKit has not been configured"

**Error:** `InviteError.notConfigured`

**Cause:** SDK methods called before `configure(apiKey:)`

**Solution:**
```swift
// Ensure configure is called early, e.g., in App init
@main
struct YourApp: App {
    init() {
        InviteKit.configure(apiKey: "your-api-key")
    }
    // ...
}
```

---

### "Invalid API key"

**Error:** `InviteError.invalidAPIKey`

**Cause:** The API key is incorrect or expired

**Solution:**
1. Verify your API key in the dashboard
2. Check for typos or extra whitespace
3. Ensure you're using the correct environment key (live vs. test)

---

## Network Issues

### "Network error"

**Error:** `InviteError.networkError`

**Causes:**
- No internet connection
- Server unreachable
- SSL/TLS issues

**Solutions:**
1. Check device network connectivity
2. Verify the base URL is correct
3. Test with `ping()` method:
   ```swift
   let isReachable = await InviteKit.ping()
   ```

---

### "Rate limited"

**Error:** `InviteError.rateLimited`

**Cause:** Too many requests in a short period

**Solution:**
1. Implement exponential backoff
2. Cache invite links locally
3. Reduce request frequency

```swift
// Example retry with backoff
func createInviteWithRetry(referrerId: String, attempt: Int = 0) async throws -> InviteResult {
    do {
        return try await InviteKit.createInviteLink(referrerId: referrerId)
    } catch InviteError.rateLimited where attempt < 3 {
        try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
        return try await createInviteWithRetry(referrerId: referrerId, attempt: attempt + 1)
    }
}
```

---

## App Clip Issues

### App Clip Not Launching from URL

**Symptoms:** Tapping invite link doesn't open App Clip

**Checklist:**
1. **Associated Domains configured:**
   ```
   appclips:yourdomain.cn1invite.com
   ```

2. **AASA file accessible:**
   ```bash
   curl https://yourdomain.cn1invite.com/.well-known/apple-app-site-association
   ```

3. **AASA content correct:**
   ```json
   {
     "appclips": {
       "apps": ["TEAMID.com.yourcompany.app.Clip"]
     }
   }
   ```

4. **Team ID matches:** Check your Apple Developer account

5. **Bundle ID correct:** Must be `{main-app-bundle-id}.Clip`

---

### URL Not Being Parsed

**Symptoms:** `parseInviteURL` returns `nil`

**Debugging:**
```swift
let url = URL(string: "https://test.cn1invite.com/i/abc?ref=user123")!

// Check host
print("Host: \(url.host ?? "nil")")
// Must contain "cn1invite.com"

// Check path
print("Path: \(url.path)")
// Must start with "/i/"

// Check query
print("Query: \(url.query ?? "nil")")
// Must include "ref" parameter
```

**Common issues:**
- URL host doesn't contain `cn1invite.com`
- Path doesn't follow `/i/{shortCode}` format
- Missing required `ref` query parameter

---

### Attribution Data Not Found in Main App

**Symptoms:** `checkForInvite()` returns `nil` even after App Clip ran

**Checklist:**

1. **Same App Group in both targets:**
   - Main app: `group.com.yourcompany.app.invite`
   - App Clip: `group.com.yourcompany.app.invite`

2. **App Groups capability enabled:**
   - Check Signing & Capabilities for both targets

3. **App Group exists in Apple Developer portal:**
   - Certificates, Identifiers & Profiles → Identifiers → App Groups

4. **Verify data is being written:**
   ```swift
   // In App Clip after storeInvite
   let defaults = UserDefaults(suiteName: "group.com.yourcompany.app.invite")
   print("Stored: \(defaults?.string(forKey: "invite.referrerId") ?? "nil")")
   ```

5. **Verify data is readable:**
   ```swift
   // In main app
   let defaults = UserDefaults(suiteName: "group.com.yourcompany.app.invite")
   print("Found: \(defaults?.string(forKey: "invite.referrerId") ?? "nil")")
   ```

---

### StoreKit Overlay Not Appearing

**Symptoms:** `presentFullAppOverlay` called but nothing shows

**Causes and solutions:**

1. **Running in Simulator:**
   - StoreKit overlays don't work in simulator
   - Test on a real device

2. **App Store ID not configured:**
   ```swift
   CN1InviteKit.configure(appStoreId: "123456789")
   ```

3. **App not published:**
   - The app must be on the App Store or TestFlight
   - Use TestFlight for pre-release testing

4. **Window scene not available:**
   ```swift
   // Ensure you have a valid window scene
   guard let scene = UIApplication.shared.connectedScenes
       .compactMap({ $0 as? UIWindowScene })
       .first else {
       print("No window scene available")
       return
   }
   ```

---

## Storage Issues

### Data Persistence Problems

**Symptoms:** Attribution data disappears

**Causes:**
1. `clearInvite()` called unintentionally
2. App reinstalled (clears UserDefaults)
3. Different App Group identifiers

**Solution:** Add logging to track storage operations:
```swift
// Enable debug logging
Logger.isEnabled = true
Logger.minimumLevel = .debug
```

---

### Storage Keys Reference

If implementing custom storage, use these keys:

| Key | Type | Description |
|-----|------|-------------|
| `invite.referrerId` | String | Referrer's user ID |
| `invite.shortCode` | String | Invite short code |
| `invite.metadata` | Data | JSON-encoded metadata |
| `invite.createdAt` | String | ISO8601 timestamp |
| `invite.version` | Int | Storage schema version |

---

## Build Issues

### Module Not Found

**Error:** `No such module 'InviteKit'`

**Solutions:**
1. Clean build folder: `Cmd+Shift+K`
2. Reset package caches: File → Packages → Reset Package Caches
3. Verify package is added to the correct target
4. Check minimum deployment target (iOS 14+)

---

### Duplicate Symbols

**Error:** Duplicate symbols for architecture

**Cause:** Both `InviteKit` and `CN1InviteKit` added to same target

**Solution:**
- Main app: Use only `InviteKit`
- App Clip: Use only `CN1InviteKit`

---

## Testing Tips

### Unit Testing with Mocks

```swift
import XCTest
@testable import InviteKit

class MockStorage: InviteStorageProtocol {
    var storedInvite: InviteResult?

    func saveInvite(_ invite: InviteResult) { storedInvite = invite }
    func getInvite() -> InviteResult? { storedInvite }
    func clearInvite() { storedInvite = nil }
    func hasInvite() -> Bool { storedInvite != nil }
}

class MockAPIClient: InviteAPIClientProtocol {
    var result: Result<InviteResult, InviteError> = .failure(.notConfigured)

    func createInvite(referrerId: String, metadata: [String: String]?) async throws -> InviteResult {
        try result.get()
    }
    // ... implement other methods
}

class YourTests: XCTestCase {
    func testAttribution() {
        let mockStorage = MockStorage()
        let mockAPI = MockAPIClient()

        InviteKit.configure(apiKey: "test", apiClient: mockAPI, storage: mockStorage)

        // Test your logic
    }
}
```

### Testing App Clip URLs

Create test URLs for different scenarios:

```swift
// Valid URL
let validURL = URL(string: "https://test.cn1invite.com/i/abc123?ref=user456")!

// With metadata
let metadata = ["campaign": "test"].json.base64
let withMetadata = URL(string: "https://test.cn1invite.com/i/abc123?ref=user456&meta=\(metadata)")!

// Invalid: wrong host
let wrongHost = URL(string: "https://example.com/i/abc123?ref=user456")!

// Invalid: missing ref
let missingRef = URL(string: "https://test.cn1invite.com/i/abc123")!
```

---

## Getting Help

If you're still experiencing issues:

1. **Check the RFC:** `rfc/ios-sdk-specification.md`
2. **Review the demo app:** `Examples/InviteKitDemo/`
3. **Enable debug logging** to capture detailed information
4. **Open an issue** on GitHub with:
   - iOS version
   - Xcode version
   - Error messages
   - Steps to reproduce
