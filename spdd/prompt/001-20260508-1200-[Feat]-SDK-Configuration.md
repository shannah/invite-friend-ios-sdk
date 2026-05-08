---
bootstrap: true
generated_at: 2026-05-08T12:00:00-07:00
---

# REASONS Canvas: SDK Configuration

## R · Requirements

- App developers must call `InviteKit.configure(apiKey:)` (or
  `InviteKit.configure(apiKey:baseURL:)`) before any other public
  method on `InviteKit` is used; otherwise calls that hit the API
  throw `InviteError.notConfigured`.
- App Clip developers must call `CN1InviteKit.configure(appStoreId:)`
  before invoking `presentFullAppOverlay(in:)` or the overlay call
  becomes a no-op with an error log.
- Configuration is process-wide (shared singleton) — re-configuring
  replaces the apiKey, baseURL, apiClient, and storage instance.
- The default API base URL is `https://api.cn1invite.com`, used when
  the single-arg `configure(apiKey:)` is called
  (`Sources/InviteKit/InviteKit.swift:55`).
- Definition of Done — covered by tests:
  - `Tests/InviteKitTests/InviteKitTests.swift:18` —
    `testConfigureWithAPIKey` (single-arg configure does not throw).
  - `Tests/InviteKitTests/InviteKitTests.swift:23` —
    `testConfigureWithAPIKeyAndBaseURL` (two-arg configure does not
    throw).
  - `Tests/InviteKitTests/InviteKitTests.swift:72` —
    `testCreateInviteLinkThrowsWhenNotConfigured`.
  - `Tests/InviteKitTests/InviteKitTests.swift:125` —
    `testRecordEventThrowsWhenNotConfigured`.
- Callers: any iOS host application linking `InviteKit` (typically
  in `AppDelegate` / `App.init`) and any App Clip target linking
  `CN1InviteKit`.

## E · Entities

- `InviteKit` (final class, Sources/InviteKit/InviteKit.swift:29) —
  process-wide singleton accessed via `InviteKit.shared`
  (Sources/InviteKit/InviteKit.swift:34). State:
  - `apiKey: String?` (Sources/InviteKit/InviteKit.swift:38).
  - `baseURL: URL?` (Sources/InviteKit/InviteKit.swift:39).
  - `apiClient: InviteAPIClientProtocol?`
    (Sources/InviteKit/InviteKit.swift:40).
  - `storage: InviteStorageProtocol?`
    (Sources/InviteKit/InviteKit.swift:41).
  - `isConfigured: Bool` (Sources/InviteKit/InviteKit.swift:42),
    flipped to `true` only inside `configure(...)` paths.
  - Invariant: `init` is private
    (Sources/InviteKit/InviteKit.swift:46) — no caller may create a
    second instance.
- `CN1InviteKit` (final class,
  Sources/CN1InviteKit/CN1InviteKit.swift:32) — App Clip singleton.
  State:
  - `storage: InviteStorageProtocol?`
    (Sources/CN1InviteKit/CN1InviteKit.swift:41), pre-populated to
    `AppGroupStorage()` in the private init
    (Sources/CN1InviteKit/CN1InviteKit.swift:47).
  - `appStoreId: String?`
    (Sources/CN1InviteKit/CN1InviteKit.swift:42).
  - Invariant: `init` is private
    (Sources/CN1InviteKit/CN1InviteKit.swift:46); no `isConfigured`
    flag — App Clip operations work without `appStoreId`, only the
    StoreKit overlay requires it.

## A · Approach

- Singleton + static-facade pattern for both SDK entry points: the
  facade methods on `InviteKit`/`CN1InviteKit` mutate `shared`
  state. Chosen for ergonomics — callers do not need to thread an
  instance through their app architecture.
- Eager dependency wiring in `configure(...)`: `InviteAPIClient` and
  `AppGroupStorage` are constructed once at configuration time
  (Sources/InviteKit/InviteKit.swift:67) so subsequent calls are
  cheap.
- Trade-off: process-wide singletons are not test-isolated — tests
  call `InviteKit.reset()` in `setUp`/`tearDown`
  (Tests/InviteKitTests/InviteKitTests.swift:8,12).
- Test seam: an internal `configure(apiKey:apiClient:storage:)`
  overload (Sources/InviteKit/InviteKit.swift:216) and
  `configure(storage:)` overload
  (Sources/CN1InviteKit/CN1InviteKit.swift:221) inject mocks without
  going through the public defaults.
- Trade-off accepted: the public single-arg `configure(apiKey:)`
  hard-codes a default base URL
  (Sources/InviteKit/InviteKit.swift:55) rather than reading from
  Info.plist or environment — simple but inflexible.

## S · Structure

- `Sources/InviteKit/InviteKit.swift` — main-app SDK static facade.
- `Sources/CN1InviteKit/CN1InviteKit.swift` — App Clip SDK static
  facade.
- Configuration also depends on:
  `Sources/InviteKit/API/InviteAPIClient.swift` (constructed during
  `InviteKit.configure`),
  `Sources/InviteKit/Storage/AppGroupStorage.swift` (constructed
  during both SDK configures),
  `Sources/CN1InviteKit/Storage/AppGroupStorage.swift` (App Clip
  copy of the App Group storage).

## O · Operations

### 1. Configure Class — InviteKit (main-app facade)
File: `Sources/InviteKit/InviteKit.swift`

1. Responsibility: process-wide configuration entry point and
   gateway for all main-app SDK calls.
2. Fields / Attributes:
   - `apiKey: String?` — current API key (line 38).
   - `baseURL: URL?` — resolved base URL (line 39).
   - `apiClient: InviteAPIClientProtocol?` — API client built
     during `configure` (line 40).
   - `storage: InviteStorageProtocol?` — App Group storage built
     during `configure` (line 41).
   - `isConfigured: Bool` — gates `ensureConfigured()` (line 42).
3. Methods:
   - `static func configure(apiKey: String)` (line 54): `Void`
     - Logic: forwards to two-arg overload with default
       `URL(string: "https://api.cn1invite.com")!`
       (Sources/InviteKit/InviteKit.swift:55).
   - `static func configure(apiKey: String, baseURL: URL)`
     (line 64): `Void`
     - Logic: assigns `shared.apiKey`, `shared.baseURL`,
       constructs `InviteAPIClient(apiKey:baseURL:)`, constructs
       `AppGroupStorage()`, sets `isConfigured = true`, logs
       success (Sources/InviteKit/InviteKit.swift:65–71).
   - `static func reset()` (line 228): `Void`
     - Logic: nils every field on `shared` and sets
       `isConfigured = false` (Sources/InviteKit/InviteKit.swift:
       229–233). `internal` — only callable from tests.
   - `static func configure(apiKey: String, apiClient:
     InviteAPIClientProtocol, storage: InviteStorageProtocol)`
     (line 216): `Void`
     - Logic: test seam — assigns mocks directly without
       constructing `InviteAPIClient`/`AppGroupStorage`
       (Sources/InviteKit/InviteKit.swift:217–224).
   - `private static func ensureConfigured()` (line 238): throws
     - Logic: throws `InviteError.notConfigured` if
       `shared.isConfigured == false`
       (Sources/InviteKit/InviteKit.swift:239–241). Called as the
       first line of every public API method that hits the network
       (Sources/InviteKit/InviteKit.swift:87, 130, 168).
4. Constraints / Invariants: only one instance exists
   (`shared`); init is private (line 46).

### 2. Configure Class — CN1InviteKit (App Clip facade)
File: `Sources/CN1InviteKit/CN1InviteKit.swift`

1. Responsibility: App Clip configuration entry point; primarily
   captures `appStoreId` for the StoreKit overlay.
2. Fields / Attributes:
   - `storage: InviteStorageProtocol?` — defaulted to
     `AppGroupStorage()` in `init` (line 47).
   - `appStoreId: String?` — required only for
     `presentFullAppOverlay(in:)` (line 42).
3. Methods:
   - `static func configure(appStoreId: String)` (line 55): `Void`
     - Logic: assigns `shared.appStoreId`, logs at `.info`
       (Sources/CN1InviteKit/CN1InviteKit.swift:56–57).
   - `static func reset()` (line 226): `Void`
     - Logic: re-creates a fresh `AppGroupStorage()` and nils
       `appStoreId` (Sources/CN1InviteKit/CN1InviteKit.swift:
       227–228). `internal` — only callable from tests.
   - `static func configure(storage: InviteStorageProtocol)`
     (line 221): `Void`
     - Logic: test seam — overrides `shared.storage` with a mock
       (Sources/CN1InviteKit/CN1InviteKit.swift:222).
4. Constraints / Invariants: there is no `isConfigured` flag —
   URL parsing and storage operate without `configure(...)`; only
   the overlay branch enforces `appStoreId`
   (Sources/CN1InviteKit/CN1InviteKit.swift:169).

## N · Norms

- Static-facade-over-singleton across both SDKs — consistent
  pattern (Sources/InviteKit/InviteKit.swift:29,
  Sources/CN1InviteKit/CN1InviteKit.swift:32).
- Internal test seams are exposed via `internal static func
  configure(...)` overloads, never via public DI.
- Configuration logs at `.info`
  (Sources/InviteKit/InviteKit.swift:71,
  Sources/CN1InviteKit/CN1InviteKit.swift:57); see
  `007-…-SDK-Diagnostics-And-Logging` for the logging policy.
- `[DRIFT]` — Default base URL in
  `Sources/InviteKit/InviteKit.swift:55` is
  `https://api.cn1invite.com`, but the README states the canonical
  API host is `https://invite.codenameone.com`
  (`README.md:62, README.md:67–73`). Either the README is stale or
  the default needs updating.
- `[DRIFT]` — `InviteResult.inviteURL`
  (`Sources/InviteKit/Models/InviteResult.swift:21–25`) builds URLs
  on `cn1invite.com` rather than the per-app
  `*.invite-friend.com` host described in `README.md:60–65`.

## S · Safeguards

- `ensureConfigured()` (Sources/InviteKit/InviteKit.swift:238–242)
  is the single guard for missing configuration; every network
  method invokes it first
  (Sources/InviteKit/InviteKit.swift:87, 130, 168).
- `apiClient` and `storage` are additionally null-checked after
  `ensureConfigured()` to satisfy the optional unwrap
  (Sources/InviteKit/InviteKit.swift:89–91, 132–134, 170–172).
- `presentFullAppOverlay(in:)` returns silently after logging an
  `.error` if `appStoreId` is unset
  (Sources/CN1InviteKit/CN1InviteKit.swift:169–172) — the App Clip
  is not allowed to crash on missing config.
- App Group fallback: `AppGroupStorage.init` falls back to
  `UserDefaults.standard` and logs `.warning` if the suite cannot
  be created
  (Sources/InviteKit/Storage/AppGroupStorage.swift:42–48,
  Sources/CN1InviteKit/Storage/AppGroupStorage.swift:27–33) — the
  SDK degrades rather than failing configuration.
