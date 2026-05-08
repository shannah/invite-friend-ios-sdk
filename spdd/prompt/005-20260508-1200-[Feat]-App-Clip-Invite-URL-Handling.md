---
bootstrap: true
generated_at: 2026-05-08T12:00:00-07:00
---

# REASONS Canvas: App Clip Invite URL Handling

## R · Requirements

- The App Clip target (`CN1InviteKit`) accepts a Universal Link
  invite URL handed in from
  `.onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` and
  reduces it to an `InviteData` record + a StoreKit "download
  full app" overlay (`Sources/CN1InviteKit/CN1InviteKit.swift:
  9–25` doc-comment, `:205`).
- Public surface:
  - `parseInviteURL(_ url: URL) -> InviteData?`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:71`).
  - `storeInvite(_ invite: InviteData) -> Bool`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:126`).
  - `getStoredInvite() -> InviteData?`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:147`).
  - `presentFullAppOverlay(in: UIWindowScene)`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:168`, iOS 14+).
  - `dismissFullAppOverlay(in: UIWindowScene)`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:185`).
  - `handleInvite(url:in:) -> InviteData?`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:205`) — convenience
    that runs parse → store → present overlay.
- Recognised hosts: any host containing `cn1invite.com` **or**
  `invite-friend.com`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:75–79`). Subdomains
  like `myapp.cn1invite.com` or `myapp.invite-friend.com` are
  accepted.
- Recognised path: `/i/{shortCode}` — the first non-`/` path
  component must be `"i"` and the second is taken as
  `shortCode` (`Sources/CN1InviteKit/CN1InviteKit.swift:82–89`).
- Query parameters:
  - `ref` — referrer id; **optional**
    (`Sources/CN1InviteKit/CN1InviteKit.swift:98`).
  - `meta` — base64-encoded JSON `[String:String]`; silently
    ignored when malformed
    (`Sources/CN1InviteKit/CN1InviteKit.swift:101–106`).
- Definition of Done — covered by tests:
  - `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:18` —
    `testParseValidInviteURL`.
  - `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:27` —
    `testParseInviteURLWithMetadata`.
  - `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:38` —
    `testParseInviteURLWithInvalidHost`.
  - `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:45` —
    `testParseInviteURLWithMissingRef` (asserts referrerId is
    `nil` rather than treating the URL as invalid).
  - `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:54` —
    `testParseInviteURLWithInvalidPath`.
  - `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:61` —
    `testParseInviteURLWithSubdomain`.
- Callers: the App Clip's `App` / scene delegate, typically inside
  `.onContinueUserActivity` handlers
  (`README.md:117–127`,
  `Sources/CN1InviteKit/CN1InviteKit.swift:18–25`).

## E · Entities

- `InviteData` (struct, `Sources/CN1InviteKit/Models/InviteData.
  swift:4`) — `Codable, Equatable`. Fields:
  - `referrerId: String?` (line 9) — `nil` when the URL had no
    `ref` query parameter; the main app is expected to look the
    referrer up by `shortCode` (see Canvas
    `003-…-Invite-Lookup-By-Short-Code`).
  - `shortCode: String` (line 12) — extracted from the path.
  - `metadata: [String: String]?` (line 15).
  - `createdAt: Date` (line 18) — captured as `Date()` when the
    URL was parsed (the App Clip's view of "now").
  - Invariant: `init` defaults `metadata = nil` and `createdAt =
    Date()` (lines 27–32).
- `InviteResult` — duplicated inside the CN1InviteKit module to
  avoid a dependency edge to `InviteKit`
  (`Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift:30`,
  see comment at `:29`). Used only as the storage payload shape.
- StoreKit overlay configuration: `SKOverlay.AppClipConfiguration`
  with `position = .bottom`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:174`).

## A · Approach

- Parsing is a pure, side-effect-free transformation
  (`URL -> InviteData?`) so it is easy to test without app-group
  storage or StoreKit being available
  (`Sources/CN1InviteKit/CN1InviteKit.swift:71`).
- Host matching uses `String.contains` rather than equality
  (`:76`), allowing per-app subdomains
  (`myapp.cn1invite.com`, `myapp.invite-friend.com`) without the
  SDK knowing the app's slug. Trade-off: `evilcn1invite.com`
  would also match — host validation is loose.
- `meta` parameter parsing is best-effort: a malformed
  base64/JSON value drops `metadata` to `nil` rather than
  failing the whole parse
  (`Sources/CN1InviteKit/CN1InviteKit.swift:101–106`).
- The convenience method `handleInvite(url:in:)` is gated behind
  `#if canImport(UIKit) && canImport(StoreKit)`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:193`) so the same
  package can build on platforms (e.g. macOS) without StoreKit.
- The App Clip references `SKOverlay` with explicit `@available(iOS
  14.0, *)` (`:167, :184, :203`) — the SDK supports iOS 14+ at
  build time but the overlay is also gated at runtime.

## S · Structure

- `Sources/CN1InviteKit/CN1InviteKit.swift` — the static facade
  (parse / store / overlay / convenience handler).
- `Sources/CN1InviteKit/Models/InviteData.swift` — the parsed
  payload type.
- `Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift`
  (and its `InviteResult` duplicate) — the persistence shape used
  by `storeInvite` (delegated to `AppGroupStorage`; see
  `006-…-Cross-Target-Attribution-Storage`).

## O · Operations

### 1. Define Entity — InviteData
File: `Sources/CN1InviteKit/Models/InviteData.swift`

1. Responsibility: structured representation of a parsed invite
   URL inside the App Clip.
2. Fields / Attributes:
   - `referrerId: String?` (line 9).
   - `shortCode: String` (line 12).
   - `metadata: [String: String]?` (line 15).
   - `createdAt: Date` (line 18).
3. Methods:
   - `init(referrerId:shortCode:metadata:createdAt:)` (line 27):
     - Logic: assigns all four fields; defaults `metadata = nil`
       and `createdAt = Date()` (lines 33–37).
4. Constraints / Invariants: `Codable` and `Equatable` are
   synthesised — preserve them under any future field
   reordering.

### 2. Implement Static Method — parseInviteURL
File: `Sources/CN1InviteKit/CN1InviteKit.swift`

1. Responsibility: convert a `URL` into an `InviteData?` purely
   client-side (no I/O).
2. Methods:
   - `static func parseInviteURL(_ url: URL) -> InviteData?`
     (line 71):
     - Logic:
       1. Log at `.debug` `"Parsing invite URL: \(url)"` (line
          72).
       2. Guard `url.host` contains `"cn1invite.com"` or
          `"invite-friend.com"`; otherwise log `.warning` and
          return `nil`
          (`Sources/CN1InviteKit/CN1InviteKit.swift:75–79`).
       3. Strip `/` from `url.pathComponents`; require at least
          two components and the first to be `"i"`; otherwise
          return `nil` (lines 82–87).
       4. `shortCode = pathComponents[1]` (line 89).
       5. Build `URLComponents(url:resolvingAgainstBaseURL:
          false)` and read `queryItems` (lines 92–97).
       6. Optional `referrerId =
          queryItems.first(where: { $0.name == "ref" })?.value`
          (line 98).
       7. Optional `metadata`: take the `meta` query value,
          base64-decode it, JSON-decode as
          `[String:String]`; on any failure leave `metadata =
          nil` (lines 101–106).
       8. Construct `InviteData(referrerId:, shortCode:,
          metadata:, createdAt: Date())` (lines 108–113) and
          return it.
3. Constraints / Invariants: returns `nil` for any host /
   path-shape failure; returns a non-nil `InviteData` even when
   `ref` and `meta` are both absent (matches the
   "missing-ref" test).

### 3. Implement Static Method — storeInvite
File: `Sources/CN1InviteKit/CN1InviteKit.swift`

1. Responsibility: persist an `InviteData` into App Group
   storage as an `InviteResult` so the main app can read it.
2. Methods:
   - `static func storeInvite(_ invite: InviteData) -> Bool`
     (line 126):
     - Logic:
       1. Guard `shared.storage`; log `.error` and return
          `false` if missing (lines 127–130).
       2. Project the `InviteData` onto a `InviteResult` of the
          same field shape (lines 132–137).
       3. Call `storage.saveInvite(result)` (line 139).
       4. Log `.info` and return `true` (lines 140–141).
3. Constraints / Invariants: storage details (App Group suite
   name, key naming, fallback) live in
   `006-…-Cross-Target-Attribution-Storage`.

### 4. Implement Static Method — getStoredInvite
File: `Sources/CN1InviteKit/CN1InviteKit.swift`

1. Responsibility: retrieve the most recently stored
   `InviteResult` and project it back to `InviteData`.
2. Methods:
   - `static func getStoredInvite() -> InviteData?`
     (line 147):
     - Logic:
       1. Guard `shared.storage` and `storage.getInvite()`;
          return `nil` if either missing (lines 148–151).
       2. Convert `InviteResult` → `InviteData` field-by-field
          (lines 153–158).
3. Constraints / Invariants: read-only — no mutation of the App
   Group payload.

### 5. Implement Static Method — presentFullAppOverlay
File: `Sources/CN1InviteKit/CN1InviteKit.swift`

1. Responsibility: present the StoreKit App-Clip "download full
   app" overlay.
2. Methods:
   - `@available(iOS 14.0, *) static func
     presentFullAppOverlay(in windowScene: UIWindowScene)`
     (line 168):
     - Logic:
       1. Guard `shared.appStoreId`; log `.error` and return if
          missing (lines 169–172).
       2. Build
          `SKOverlay.AppClipConfiguration(position: .bottom)`
          (line 174).
       3. `SKOverlay(configuration: config).present(in:
          windowScene)` (lines 175–177).
       4. Log `.info` (line 178).
3. Constraints / Invariants: runs only when the SDK is compiled
   with both `UIKit` and `StoreKit`
   (`Sources/CN1InviteKit/CN1InviteKit.swift:163`); availability
   check at runtime guards iOS < 14.

### 6. Implement Static Method — dismissFullAppOverlay
File: `Sources/CN1InviteKit/CN1InviteKit.swift`

1. Responsibility: programmatically dismiss the overlay.
2. Methods:
   - `@available(iOS 14.0, *) static func
     dismissFullAppOverlay(in windowScene: UIWindowScene)`
     (line 185):
     - Logic: `SKOverlay.dismiss(in: windowScene)` then log at
       `.info` (lines 186–187).
3. Constraints / Invariants: idempotent — safe to call when no
   overlay is showing (StoreKit handles that case).

### 7. Implement Static Method — handleInvite (convenience)
File: `Sources/CN1InviteKit/CN1InviteKit.swift`

1. Responsibility: end-to-end pipeline glue: parse → store →
   present overlay.
2. Methods:
   - `@available(iOS 14.0, *) static func handleInvite(url:
     URL, in windowScene: UIWindowScene) -> InviteData?`
     (line 205):
     - Logic:
       1. `guard let inviteData = parseInviteURL(url) else {
          log .warning; return nil }` (lines 206–209).
       2. `storeInvite(inviteData)` (line 211).
       3. `presentFullAppOverlay(in: windowScene)` (line 212).
       4. Return `inviteData` (line 214).
3. Constraints / Invariants: the discardable result lets call
   sites in `onContinueUserActivity` fire-and-forget.

## N · Norms

- Pure parsing is exposed independently from storage/UI side
  effects so unit tests (no UIKit required) can cover URL
  recognition.
- Logging at parse time uses `.debug` for entry, `.info` for
  success, `.warning` for known invalid inputs — see
  `007-…-SDK-Diagnostics-And-Logging`.
- StoreKit / UIKit code paths are wrapped in
  `#if canImport(UIKit) && canImport(StoreKit)`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:163, :193`) — keep new
  StoreKit work inside that guard.
- `[DRIFT]` — the `parseInviteURL` doc-comment claims URL form
  `https://{project-slug}.cn1invite.com/i/{shortCode}` but the
  implementation also accepts `*invite-friend.com` hosts and any
  apex domain that contains `cn1invite.com`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:67–69, 75–79`).
- `InviteResult` is duplicated inside the CN1 module instead of
  being shared via a third "common" target
  (`Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift:
  29–57`) — accepted to keep the App Clip binary tiny.

## S · Safeguards

- Host validation: anything other than `*cn1invite.com*` or
  `*invite-friend.com*` returns `nil`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:75–79`); test
  `testParseInviteURLWithInvalidHost`
  (`Tests/CN1InviteKitTests/CN1InviteKitTests.swift:38`).
- Path validation: the first path component must be `"i"`;
  otherwise `nil` (`Sources/CN1InviteKit/CN1InviteKit.swift:
  82–87`); test `testParseInviteURLWithInvalidPath`
  (`Tests/CN1InviteKitTests/CN1InviteKitTests.swift:54`).
- `URLComponents` failure is logged at `.warning` and returns
  `nil` (`Sources/CN1InviteKit/CN1InviteKit.swift:92–95`).
- Malformed `meta` parameter is silently dropped to `nil` rather
  than failing parsing
  (`Sources/CN1InviteKit/CN1InviteKit.swift:101–106`) — bias
  toward attribution survival.
- StoreKit overlay refuses to present without an `appStoreId`
  and logs `.error`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:169–172`); never
  crashes.
- Storage failure (`shared.storage == nil`) on
  `storeInvite(_:)` returns `false` and logs `.error`
  (`Sources/CN1InviteKit/CN1InviteKit.swift:127–131`).
