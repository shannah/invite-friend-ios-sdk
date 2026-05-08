---
bootstrap: true
generated_at: 2026-05-08T12:00:00-07:00
---

# REASONS Canvas: Cross-Target Attribution Storage

## R · Requirements

- Invite attribution must survive the App Clip → main-app
  hand-off: an invite stored by the App Clip needs to be
  readable by the main app after the user installs from the
  StoreKit overlay.
- Both targets share data via an App Group `UserDefaults` suite
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:13`,
  `Sources/CN1InviteKit/Storage/AppGroupStorage.swift:4`).
- Public main-app surface:
  - `InviteKit.checkForInvite() -> InviteResult?`
    (`Sources/InviteKit/InviteKit.swift:144`).
  - `InviteKit.clearInvite()`
    (`Sources/InviteKit/InviteKit.swift:154`).
- Public App Clip surface:
  - `CN1InviteKit.storeInvite(_:) -> Bool`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:126`).
  - `CN1InviteKit.getStoredInvite() -> InviteData?`
    (`Sources/CN1InviteKit/CN1InviteKit.swift:147`).
- Both `AppGroupStorage` implementations write the same five keys
  under the same suite, with the same encoding format, so either
  target can read what the other wrote.
- Default suite name: `"group.<bundleId>.invite"` where
  `<bundleId>` is `Bundle.main.bundleIdentifier` with any
  trailing `".Clip"` removed (`Sources/InviteKit/Storage/
  AppGroupStorage.swift:123–128`).
- Definition of Done — covered by tests:
  - `Tests/InviteKitTests/InviteKitTests.swift:31` —
    `testCheckForInviteWithNoData`.
  - `Tests/InviteKitTests/InviteKitTests.swift:37` —
    `testCheckForInviteWithStoredData`.
  - `Tests/InviteKitTests/InviteKitTests.swift:57` —
    `testClearInvite`.
  - `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:72` —
    `testStoreAndRetrieveInvite`.
- Callers: the App Clip writes after URL parsing
  (`CN1InviteKit.handleInvite(url:in:)`); the main app reads on
  app launch (`InviteKit.checkForInvite()`) and clears once
  attribution has been recorded.

## E · Entities

- `InviteStorageProtocol` (protocol, `Sources/InviteKit/Storage/
  InviteStorageProtocol.swift:7` and
  `Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift:7`)
  — duplicated across both targets to avoid an `InviteKit`
  dependency from the App Clip
  (`Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift:29`).
  Methods:
  - `func saveInvite(_ invite: InviteResult)`.
  - `func getInvite() -> InviteResult?`.
  - `func clearInvite()`.
  - `func hasInvite() -> Bool`.
- `InviteResult` — public type in `InviteKit`
  (`Sources/InviteKit/Models/InviteResult.swift:4`); duplicated
  inside `CN1InviteKit` for the same reason
  (`Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift:30`).
  Both copies are field-compatible.
- `AppGroupStorage` (final class) implements the protocol on each
  target. Both versions share:
  - Storage keys (private `enum Keys`):
    `"invite.referrerId"`, `"invite.shortCode"`,
    `"invite.metadata"`, `"invite.createdAt"`, `"invite.version"`
    (`Sources/InviteKit/Storage/AppGroupStorage.swift:17–23`,
    `Sources/CN1InviteKit/Storage/AppGroupStorage.swift:8–14`).
  - `currentVersion = 1`
    (`Sources/InviteKit/Storage/AppGroupStorage.swift:31`,
    `Sources/CN1InviteKit/Storage/AppGroupStorage.swift:20`).
  - `dateFormatter: ISO8601DateFormatter` with options
    `[.withInternetDateTime, .withFractionalSeconds]`
    (`Sources/InviteKit/Storage/AppGroupStorage.swift:50–51`,
    `Sources/CN1InviteKit/Storage/AppGroupStorage.swift:35–36`).
- Invariant: storage encoding is the public ABI between the App
  Clip and the main app. Field renames must be coordinated with
  a `currentVersion` bump and a migration path (none exists
  today → `[INFERRED]`).

## A · Approach

- `UserDefaults`-backed App Group suite chosen over the keychain
  or a file-shared container — invite attribution is non-secret
  and key-value-shaped.
- Two separate `AppGroupStorage` files (one per target) instead
  of a third shared module. Trade-off: minimises App Clip binary
  size at the cost of mechanical duplication; both files must
  stay byte-compatible.
- `UserDefaults.synchronize()` is called explicitly after every
  write/clear (`Sources/InviteKit/Storage/AppGroupStorage.swift:
  81, 112`,
  `Sources/CN1InviteKit/Storage/AppGroupStorage.swift:65, 96`)
  even though Apple has deprecated it as a no-op in the main
  app — kept defensively because the App Clip → main-app
  hand-off historically benefited from a forced flush.
- A storage version key (`invite.version`) is written but never
  read or branched on
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:71`) —
  intentional forward-compatibility hook.
- Suite-name fallback: if `UserDefaults(suiteName:)` returns
  `nil`, the storage degrades to `UserDefaults.standard` and
  logs at `.warning`
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:42–48`,
  `Sources/CN1InviteKit/Storage/AppGroupStorage.swift:27–33`).
  Trade-off: in mis-configured projects the App Clip and main
  app each silently use private `UserDefaults`, breaking the
  hand-off — observable only via the warning log.

## S · Structure

- `Sources/InviteKit/Storage/InviteStorageProtocol.swift` —
  protocol used by `InviteKit`.
- `Sources/InviteKit/Storage/AppGroupStorage.swift` — main-app
  default implementation.
- `Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift` —
  duplicated protocol + duplicated `InviteResult`.
- `Sources/CN1InviteKit/Storage/AppGroupStorage.swift` — App Clip
  implementation.
- `Sources/InviteKit/InviteKit.swift` — facade methods
  `checkForInvite()` and `clearInvite()`.
- `Sources/CN1InviteKit/CN1InviteKit.swift` — facade methods
  `storeInvite(_:)` / `getStoredInvite()`; see Canvas
  `005-…-App-Clip-Invite-URL-Handling`.

## O · Operations

### 1. Define Protocol — InviteStorageProtocol (both targets)
Files:
- `Sources/InviteKit/Storage/InviteStorageProtocol.swift`
- `Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift`

1. Responsibility: dependency-injectable contract for invite
   persistence; covers App Group, in-memory mock, etc.
2. Methods:
   - `func saveInvite(_ invite: InviteResult)`.
   - `func getInvite() -> InviteResult?`.
   - `func clearInvite()`.
   - `func hasInvite() -> Bool`.
3. Constraints / Invariants: the two protocol declarations must
   stay byte-identical so the duplicated `AppGroupStorage`
   implementations can also stay aligned.

### 2. Implement Repository — AppGroupStorage (main app)
File: `Sources/InviteKit/Storage/AppGroupStorage.swift`

1. Responsibility: persist `InviteResult` to a shared App Group
   `UserDefaults` suite for the main-app target.
2. Fields / Attributes:
   - `userDefaults: UserDefaults` (line 27).
   - `dateFormatter: ISO8601DateFormatter` (line 28) — options
     `[.withInternetDateTime, .withFractionalSeconds]`.
   - Static `currentVersion: Int = 1` (line 31).
   - Private `enum Keys` for the five storage keys (lines 17–23).
3. Methods:
   - `init(suiteName: String? = nil)` (line 39):
     - Logic: resolves suite via `defaultSuiteName()` if `nil`;
       creates `UserDefaults(suiteName:)`; falls back to
       `.standard` with a `.warning` log on failure (lines
       40–48).
   - `init(userDefaults: UserDefaults)` (internal, line 55):
     - Logic: test seam — assigns the supplied `UserDefaults`
       instance directly (lines 56–58).
   - `func saveInvite(_ invite: InviteResult)` (line 63):
     - Logic:
       1. If `invite.referrerId` is non-nil, write to
          `Keys.referrerId`; else `removeObject` for that key
          (lines 64–68).
       2. Write `invite.shortCode` (line 69).
       3. Write ISO-8601-formatted `createdAt` (line 70).
       4. Write `currentVersion` (line 71).
       5. If `metadata` is non-nil, JSON-encode it and write to
          `Keys.metadata`; else `removeObject` (lines 73–79).
       6. `userDefaults.synchronize()` (line 81); log at `.debug`.
   - `func getInvite() -> InviteResult?` (line 85):
     - Logic:
       1. Read optional `referrerId` (line 86).
       2. Guard `shortCode` and a parseable `createdAt` ISO-8601
          string (lines 87–90); return `nil` on failure.
       3. Decode optional metadata (lines 93–95).
       4. Return constructed `InviteResult` (lines 98–103).
   - `func clearInvite()` (line 106):
     - Logic: `removeObject` for all five keys, then
       `synchronize()` (lines 107–112); log at `.debug`.
   - `func hasInvite() -> Bool` (line 117):
     - Logic: returns `userDefaults.string(forKey:
       Keys.shortCode) != nil` (line 118).
   - `private static func defaultSuiteName() -> String`
     (line 123):
     - Logic: derives from `Bundle.main.bundleIdentifier`
       (defaults to `"com.unknown"` if `nil`); strips `.Clip`
       suffix; prefixes `"group."` and suffixes `".invite"`
       (lines 124–127).
4. Constraints / Invariants: any change to the key set or
   encoding format is a wire-protocol break with the App Clip
   `AppGroupStorage` — keep both files in lockstep.

### 3. Implement Repository — AppGroupStorage (App Clip)
File: `Sources/CN1InviteKit/Storage/AppGroupStorage.swift`

1. Responsibility: identical persistence on the App Clip side.
2. Fields / Attributes: same set as the main-app
   `AppGroupStorage`
   (`Sources/CN1InviteKit/Storage/AppGroupStorage.swift:18–20`).
3. Methods: same as the main-app file. Specifically:
   - `init(suiteName:)` (line 24); `init(userDefaults:)` (line
     39); `saveInvite(_:)` (line 47); `getInvite()` (line 69);
     `clearInvite()` (line 90); `hasInvite()` (line 101);
     `defaultSuiteName()` (line 107).
4. Constraints / Invariants: byte-compatible with the main-app
   file. `[DRIFT]` risk — there is no automated test enforcing
   that both files agree, so future edits can drift silently.

### 4. Implement Static Method — InviteKit.checkForInvite
File: `Sources/InviteKit/InviteKit.swift`

1. Responsibility: surface the most recently stored
   `InviteResult` to the main app.
2. Methods:
   - `static func checkForInvite() -> InviteResult?`
     (line 144):
     - Logic:
       1. Guard `shared.storage`; if missing log `.warning`
          and return `nil` (lines 145–148).
       2. Return `storage.getInvite()` (line 150).
3. Constraints / Invariants: does **not** call
   `ensureConfigured()` — read-only access is allowed before the
   API key has been wired (`Sources/InviteKit/InviteKit.swift:
  144–151`). [INFERRED] design choice supported by the
  `testCheckForInviteWithNoData` test.

### 5. Implement Static Method — InviteKit.clearInvite
File: `Sources/InviteKit/InviteKit.swift`

1. Responsibility: erase any stored attribution (typically after
   recording an event).
2. Methods:
   - `static func clearInvite()` (line 154):
     - Logic: `shared.storage?.clearInvite()`; log at `.info`
       (lines 155–156).
3. Constraints / Invariants: silent no-op when storage is `nil`.

### 6. Wire Test Mock — MockStorage (test targets)
Files:
- `Tests/InviteKitTests/InviteKitTests.swift:151`
- `Tests/CN1InviteKitTests/CN1InviteKitTests.swift:137`

1. Responsibility: in-memory `InviteStorageProtocol`
   implementation used to drive tests without touching
   `UserDefaults`.
2. Fields / Attributes:
   - `storedInvite: InviteResult?`
     (`Tests/InviteKitTests/InviteKitTests.swift:152`).
3. Methods:
   - `saveInvite`, `getInvite`, `clearInvite`, `hasInvite` —
     trivial assignments / reads on `storedInvite`
     (`Tests/InviteKitTests/InviteKitTests.swift:154–168`).
4. Constraints / Invariants: kept in lockstep with the protocol
   shape — every protocol method must have a mock implementation
   in both test files.

## N · Norms

- App Group suite naming convention is
  `"group.<bundleId-without-.Clip>.invite"`
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:123–127`) —
  do not deviate per-feature.
- Storage keys are namespaced with `"invite."`
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:17–22`) and
  must match exactly across both targets.
- Storage version is written but never read; bump
  `currentVersion` and add a migration before changing the key
  set or encoding shape
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:31, 71`).
- `[DRIFT]` — `InviteResult` and `InviteStorageProtocol` are
  duplicated across the two targets
  (`Sources/CN1InviteKit/Storage/InviteStorageProtocol.swift:
  29–57`); future divergence is an open risk and should be
  reconciled via a shared internal target if it grows.
- `UserDefaults.synchronize()` is intentionally retained on every
  write/clear despite Apple's deprecation
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:81, 112`).

## S · Safeguards

- Suite resolution failure falls back to `UserDefaults.standard`
  with a `.warning` log
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:42–48`,
  `Sources/CN1InviteKit/Storage/AppGroupStorage.swift:27–33`) —
  attribution is silently broken in this case; log line is the
  only signal.
- `getInvite()` requires both `shortCode` and a parseable
  `createdAt`; missing/garbled values cause a `nil` return
  rather than a partial result
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:87–90`).
- `clearInvite()` removes every key including the version key
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:107–111`) so
  a subsequent read returns `nil` cleanly.
- `metadata` decode failure leaves `metadata = nil` rather than
  failing the whole read
  (`Sources/InviteKit/Storage/AppGroupStorage.swift:93–96`).
- `checkForInvite()` returns `nil` and logs `.warning` if storage
  is unavailable, rather than crashing
  (`Sources/InviteKit/InviteKit.swift:145–148`).
