---
bootstrap: true
generated_at: 2026-05-08T12:00:00-07:00
---

# REASONS Canvas: SDK Diagnostics & Logging

## R · Requirements

- Both SDK targets emit structured diagnostic messages so app
  developers can troubleshoot configuration and attribution
  problems via Console / `os_log`.
- Each target has its own internal `Logger` enum with the same
  shape but a distinct OSLog category:
  - `InviteKit` subsystem `"com.cn1invite.InviteKit"`, category
    `"InviteKit"` (`Sources/InviteKit/Utils/Logger.swift:45–46`).
  - `CN1InviteKit` subsystem `"com.cn1invite.CN1InviteKit"`,
    category `"CN1InviteKit"`
    (`Sources/CN1InviteKit/Utils/Logger.swift:39–40`).
- Default behaviour:
  - `Logger.isEnabled = true`
    (`Sources/InviteKit/Utils/Logger.swift:43`,
    `Sources/CN1InviteKit/Utils/Logger.swift:37`).
  - `Logger.minimumLevel = .warning`
    (`Sources/InviteKit/Utils/Logger.swift:40`,
    `Sources/CN1InviteKit/Utils/Logger.swift:36`) — info/debug
    messages are dropped unless tooling lowers the threshold.
- In `#if DEBUG` builds, every emitted message is also printed
  to stdout with the prefix `"[InviteKit]"` or `"[CN1InviteKit]"`
  (`Sources/InviteKit/Utils/Logger.swift:70–72`,
  `Sources/CN1InviteKit/Utils/Logger.swift:54–56`).
- Public-facing API methods produce specific, recognisable log
  lines that callers can search for; e.g. `"InviteKit configured
  with base URL: <url>"`
  (`Sources/InviteKit/InviteKit.swift:71`).
- Definition of Done — `[INFERRED]` test coverage gap. The
  Logger has no dedicated tests; behaviour is exercised
  indirectly through every other test.
- Callers: every other Canvas in the SDK calls into
  `Logger.log(...)`; consumers may also lower
  `Logger.minimumLevel` for verbose diagnosis.

## E · Entities

- `Logger` (enum, `Sources/InviteKit/Utils/Logger.swift:5` and
  `Sources/CN1InviteKit/Utils/Logger.swift:5`) — file-private
  module with static methods only. Identical structure across
  both targets.
- `Logger.Level` (nested enum, `Sources/InviteKit/Utils/Logger.
  swift:8`) — `Int, Comparable` with cases `.debug = 0`,
  `.info = 1`, `.warning = 2`, `.error = 3` (lines 9–12).
  Invariant: ordering is required for the `>= minimumLevel`
  filter (`Sources/InviteKit/Utils/Logger.swift:65`).
- `Logger.Level.osLogType` (computed, line 27) — maps `.debug →
  .debug`, `.info → .info`, `.warning → .default`, `.error →
  .error`. Note that `.warning` becomes `OSLogType.default`
  rather than a dedicated warning level (Apple's API has no
  warning).
- Static state on `Logger`:
  - `minimumLevel: Level = .warning` (line 40).
  - `isEnabled: Bool = true` (line 43).
  - `subsystem`, `osLog: OSLog` (lines 45–46).

## A · Approach

- Two parallel implementations — one per target — instead of a
  shared internal target, mirroring the duplicated storage
  approach (see `006-…-Cross-Target-Attribution-Storage`).
  Trade-off: each target stays dependency-free at the cost of
  drift risk between the two `Logger.swift` files.
- Routes through `os_log` so messages are visible in Console.app
  even in release builds; uses `%{public}@` so the formatted
  message is not redacted
  (`Sources/InviteKit/Utils/Logger.swift:74`,
  `Sources/CN1InviteKit/Utils/Logger.swift:58`).
- Adds a `#if DEBUG`-only `print` so developers see logs in the
  Xcode console without having to attach Console.app.
- Source-location enrichment: file name, line, and function are
  captured automatically via `#file`, `#function`, `#line`
  defaults (`Sources/InviteKit/Utils/Logger.swift:60–63`).

## S · Structure

- `Sources/InviteKit/Utils/Logger.swift` — main-target logger.
- `Sources/CN1InviteKit/Utils/Logger.swift` — App Clip logger.

## O · Operations

### 1. Define Entity — Logger.Level
File (per target): `Sources/InviteKit/Utils/Logger.swift`,
`Sources/CN1InviteKit/Utils/Logger.swift`

1. Responsibility: enumerate severity levels and provide a
   `Comparable` ordering for filtering.
2. Fields / Attributes:
   - `debug = 0` (line 9).
   - `info = 1` (line 10).
   - `warning = 2` (line 11).
   - `error = 3` (line 12).
3. Methods:
   - `static func < (lhs: Level, rhs: Level) -> Bool` (line 14):
     - Logic: `lhs.rawValue < rhs.rawValue` (line 15).
   - `var prefix: String` (line 18):
     - Logic: switch returning `"DEBUG" / "INFO" / "WARNING" /
       "ERROR"` (lines 19–24).
   - `var osLogType: OSLogType` (line 27):
     - Logic: switch returning `.debug / .info / .default /
       .error` (lines 28–33).
4. Constraints / Invariants: case ordering is wire-format-like
   — never reorder without auditing all `>= minimumLevel`
   comparisons.

### 2. Implement Service — Logger.log
File (per target): `Sources/InviteKit/Utils/Logger.swift`,
`Sources/CN1InviteKit/Utils/Logger.swift`

1. Responsibility: single entry point for emitting a log
   message at a given level.
2. Fields / Attributes:
   - `static var minimumLevel: Level = .warning` (line 40).
   - `static var isEnabled: Bool = true` (line 43).
   - `private static let subsystem` (line 45).
   - `private static let osLog: OSLog` (line 46).
3. Methods:
   - `static func log(_ message: String, level: Level, file:
     String = #file, function: String = #function, line: Int =
     #line)` (line 58):
     - Logic:
       1. Early-return if `!isEnabled || level < minimumLevel`
          (line 65).
       2. Build a fileName by `(file as NSString).
          lastPathComponent` (line 67).
       3. Format
          `"[<PREFIX>] [<file>:<line>] <function>: <message>"`
          (line 68).
       4. `#if DEBUG` block — `print("[InviteKit]
          <formatted>")` (lines 70–72).
       5. `os_log("%{public}@", log: osLog, type:
          level.osLogType, formattedMessage)` (line 74).
4. Constraints / Invariants: OSLog `.warning` does not exist —
   a `Logger.Level.warning` message becomes
   `OSLogType.default`. Search filters in Console.app must look
   for `"WARNING"` text rather than the OS level.

## N · Norms

- One `Logger` per target — never `import` across targets.
- Levels are used semantically:
  - `.debug` — entry/exit traces, parsing internals
    (e.g. `Sources/CN1InviteKit/CN1InviteKit.swift:72`).
  - `.info` — successful state changes and configuration
    (`Sources/InviteKit/InviteKit.swift:71`,
    `Sources/CN1InviteKit/CN1InviteKit.swift:57`).
  - `.warning` — recoverable problems
    (`Sources/CN1InviteKit/CN1InviteKit.swift:77`,
    `Sources/InviteKit/Storage/AppGroupStorage.swift:46`).
  - `.error` — programmer errors that prevent a code path
    (`Sources/InviteKit/API/InviteAPIClient.swift:138`,
    `Sources/CN1InviteKit/CN1InviteKit.swift:170`).
- Default `minimumLevel = .warning` — production callers see
  warnings/errors only; lower at runtime (e.g. for support
  cases) by setting `Logger.minimumLevel = .debug`.
- `[DRIFT]` — the two `Logger.swift` files duplicate code; any
  edit must be applied in both.
- `[DRIFT]` — `os_log` was deprecated in iOS 14 in favour of
  `Logger` (the Apple type) but the SDK still uses the older
  API; renaming the internal enum to a new name (e.g.
  `LogEmitter`) would unblock that migration without breaking
  callers.

## S · Safeguards

- The `isEnabled` flag (`Sources/InviteKit/Utils/Logger.swift:
  43`) lets a host app silence all SDK logging in production
  if needed.
- The `minimumLevel` filter
  (`Sources/InviteKit/Utils/Logger.swift:65`) prevents debug
  noise from reaching `os_log` even when downstream tools sample
  it.
- `%{public}@` is used intentionally
  (`Sources/InviteKit/Utils/Logger.swift:74`) — review every
  log site before adding user-supplied input to a log line so
  PII does not leak into Console.app. → `[INFERRED]` invariant
  not currently enforced by code; lives in this Norm only.
- The `#if DEBUG` print
  (`Sources/InviteKit/Utils/Logger.swift:70–72`) is compiled
  out of release builds; production users do not see stdout
  noise.
