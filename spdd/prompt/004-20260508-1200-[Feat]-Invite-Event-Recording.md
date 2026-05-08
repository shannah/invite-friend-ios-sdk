---
bootstrap: true
generated_at: 2026-05-08T12:00:00-07:00
---

# REASONS Canvas: Invite Event Recording

## R · Requirements

- A configured main-app caller can record a lifecycle event for an
  invite via `InviteKit.recordEvent(shortCode:eventType:) async
  throws` (`Sources/InviteKit/InviteKit.swift:167`) or its
  completion-handler variant
  (`Sources/InviteKit/InviteKit.swift:184`).
- Three event types are supported (`Sources/InviteKit/Models/
  InviteEventType.swift:4–13`):
  - `.accepted` — the invite link was opened/accepted.
  - `.installed` — the app was installed via the invite.
  - `.attributed` — attribution was recorded against the invite.
- Wire format: `POST {baseURL}/api/v1/sdk/invites/{shortCode}/
  events` with body `{ eventType }` JSON-encoded; the response
  body is empty (`Sources/InviteKit/API/InviteAPIClient.swift:
  74–83`).
- Event recording is fire-and-forget from the caller's perspective:
  the success path returns `Void`; errors propagate as `InviteError`
  (`Sources/InviteKit/API/InviteAPIClient.swift:74`).
- After a successful POST, the SDK logs at `.info` —
  `"Event recorded: <eventType> for <shortCode>"`
  (`Sources/InviteKit/InviteKit.swift:175`).
- Definition of Done — covered by tests:
  - `Tests/InviteKitTests/InviteKitTests.swift:125` —
    `testRecordEventThrowsWhenNotConfigured`.
  - `Tests/InviteKitTests/InviteKitTests.swift:136` —
    `testRecordEventSuccess` (asserts the mock client received the
    expected `shortCode` and `eventType`).
- Callers: the main app, after `checkForInvite()` returns a stored
  invite (typical pattern: record `.attributed` on first launch
  post-install). See `README.md:96–101`.

## E · Entities

- `InviteEventType` (enum, `Sources/InviteKit/Models/
  InviteEventType.swift:4`) — `String, Codable`.
  - Raw values: `"accepted"`, `"installed"`, `"attributed"`
    (lines 6, 9, 12). Invariant: the raw-value strings are part
    of the wire protocol — renaming a case will break the server
    contract.
- `RecordEventRequest` (struct, `Sources/InviteKit/API/
  InviteAPIClient.swift:179`) — `Encodable` wrapper of the single
  field `{ eventType }`.
- `EmptyResponse` (struct, `Sources/InviteKit/API/InviteAPIClient.
  swift:194`) — placeholder `Decodable` used to satisfy
  `performRequest`'s generic signature when the body is empty.

## A · Approach

- Reuses the same `URLSession` request pipeline as create/lookup
  (`makeRequest` + `performRequest` in
  `Sources/InviteKit/API/InviteAPIClient.swift:117, 126`) — keeping
  one error-mapping path for all server interactions.
- An empty success body is decoded into `EmptyResponse` using a
  `let _: EmptyResponse = try await performRequest(request)`
  pattern (`Sources/InviteKit/API/InviteAPIClient.swift:82`).
  Trade-off: a non-empty 2xx response is silently ignored — server
  cannot piggyback data on event ACKs without a future
  contract change.
- Event delivery is single-attempt. There is no in-SDK retry,
  queueing, or offline buffering — failures bubble up to the
  caller.
- The completion-handler overload exists for the same reason as on
  `createInviteLink`: pre-async/await callers can still drive the
  feature. Same error-bridging logic
  (`Sources/InviteKit/InviteKit.swift:189–198`).

## S · Structure

- `Sources/InviteKit/InviteKit.swift` — public facade:
  `recordEvent` async + completion-handler overload.
- `Sources/InviteKit/Models/InviteEventType.swift` — the `enum`
  driving the wire payload.
- `Sources/InviteKit/API/InviteAPIClientProtocol.swift` — protocol
  contract.
- `Sources/InviteKit/API/InviteAPIClient.swift` — `URLSession`
  implementation; declares `RecordEventRequest` and
  `EmptyResponse`.

## O · Operations

### 1. Define Entity — InviteEventType
File: `Sources/InviteKit/Models/InviteEventType.swift`

1. Responsibility: enumerate the lifecycle events the server
   accepts on `POST /events`.
2. Fields / Attributes:
   - `accepted: String = "accepted"` (line 6).
   - `installed: String = "installed"` (line 9).
   - `attributed: String = "attributed"` (line 12).
3. Methods:
   - `enum case` only — `Codable` synthesised; encoding emits the
     raw string verbatim.
4. Constraints / Invariants: raw-value strings are wire-format
   identifiers — must not be renamed without a coordinated
   server change.

### 2. Define Protocol Method — InviteAPIClientProtocol.recordEvent
File: `Sources/InviteKit/API/InviteAPIClientProtocol.swift`

1. Responsibility: contract for recording a single event against
   an existing invite.
2. Methods:
   - `func recordEvent(shortCode: String, eventType:
     InviteEventType) async throws` (line 31):
     - Logic: contractual — implementations must call
       `POST /api/v1/sdk/invites/{shortCode}/events` with the
       `eventType` field.
3. Constraints / Invariants: returns `Void` on success; failures
   throw `InviteError`.

### 3. Implement Service — InviteAPIClient.recordEvent
File: `Sources/InviteKit/API/InviteAPIClient.swift`

1. Responsibility: perform the `POST .../events` HTTP exchange.
2. Methods:
   - `func recordEvent(shortCode: String, eventType:
     InviteEventType) async throws` (line 74):
     - Logic:
       1. `endpoint = baseURL.appendingPathComponent(
          "/api/v1/sdk/invites/\(shortCode)/events")` (line 75).
       2. `request = makeRequest(url: endpoint, method: "POST")`
          (line 77).
       3. Encode `RecordEventRequest(eventType:)` into
          `request.httpBody` (lines 79–80).
       4. Discard the body via `let _: EmptyResponse = try await
          performRequest(request)` (line 82).
3. Constraints / Invariants: any non-2xx response is mapped by
   `performRequest` to a typed `InviteError` (404 →
   `.inviteNotFound`, 401 → `.invalidAPIKey`, 429 → `.rateLimited`,
   else → `.serverError(...)`).

### 4. Implement Static Facade — InviteKit.recordEvent (async)
File: `Sources/InviteKit/InviteKit.swift`

1. Responsibility: public async entry point.
2. Methods:
   - `static func recordEvent(shortCode: String, eventType:
     InviteEventType) async throws` (line 167):
     - Logic:
       1. `try ensureConfigured()` (line 168).
       2. `guard let apiClient = shared.apiClient else { throw
          InviteError.notConfigured }` (lines 170–172).
       3. `try await apiClient.recordEvent(shortCode:eventType:)`
          (line 174).
       4. Log `"Event recorded: <eventType> for <shortCode>"` at
          `.info` (line 175).
3. Constraints / Invariants: log line is part of the observable
   side-effect surface (Troubleshooting docs may reference it).

### 5. Implement Static Facade — InviteKit.recordEvent (completion)
File: `Sources/InviteKit/InviteKit.swift`

1. Responsibility: completion-handler bridge for non-async
   callers.
2. Methods:
   - `static func recordEvent(shortCode: String, eventType:
     InviteEventType, completion: @escaping
     (Result<Void, InviteError>) -> Void)` (line 184):
     - Logic: spawns a `Task`, awaits the async overload,
       converts `InviteError` to `.failure(error)` and other
       errors to `.failure(.networkError(error))`
       (`Sources/InviteKit/InviteKit.swift:189–198`).
3. Constraints / Invariants: identical error-bridging shape to
   `createInviteLink(...,completion:)`; keep them aligned.

## N · Norms

- Public API offers both `async throws` and completion-handler
  variants for the two write-side methods (`createInviteLink`,
  `recordEvent`). Read-side methods (`getInvite`, `checkForInvite`)
  do not currently follow this pattern → `[INFERRED]` partial
  norm.
- Status-code → typed-error mapping lives only in
  `performRequest` — never duplicate it at call sites.
- All wire-format identifiers (`InviteEventType` raw strings) are
  treated as part of the public API surface for compatibility
  purposes.

## S · Safeguards

- `ensureConfigured()` is invoked first
  (`Sources/InviteKit/InviteKit.swift:168`).
- `apiClient` is null-checked again post-`ensureConfigured`
  (`Sources/InviteKit/InviteKit.swift:170–172`).
- 404 on a non-existent `shortCode` surfaces as
  `InviteError.inviteNotFound`
  (`Sources/InviteKit/API/InviteAPIClient.swift:146`) — caller can
  distinguish that from a generic server error.
- The completion-handler overload coerces unexpected non-`InviteError`
  failures to `.networkError(error)` so callers always see a typed
  error (`Sources/InviteKit/InviteKit.swift:195–197`).
- No retry / no buffering: a transient failure means the event is
  lost from the SDK's perspective — caller is responsible for any
  retry policy. → `[INFERRED]` deliberate scope decision.
