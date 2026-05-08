---
bootstrap: true
generated_at: 2026-05-08T12:00:00-07:00
---

# REASONS Canvas: Invite Link Creation

## R · Requirements

- A configured main-app caller can create a new invite by supplying
  a `referrerId: String` and optional `metadata: [String: String]?`
  via `InviteKit.createInviteLink(referrerId:metadata:)`.
- The SDK exposes both an `async throws` variant
  (`Sources/InviteKit/InviteKit.swift:83`) and a completion-handler
  variant (`Sources/InviteKit/InviteKit.swift:102`) for callers on
  pre-async/await codebases.
- The completion-handler variant returns `Result<InviteResult,
  InviteError>` and maps any non-`InviteError` into
  `.networkError(error)`
  (`Sources/InviteKit/InviteKit.swift:111–115`).
- The returned `InviteResult` contains `referrerId`, `shortCode`,
  `metadata`, and `createdAt`; the SDK preserves the caller-supplied
  `referrerId` and `metadata` in the result rather than echoing
  what the server returned (`Sources/InviteKit/API/InviteAPIClient.
  swift:52–57`).
- Wire format: `POST {baseURL}/api/v1/sdk/invites` with JSON body
  `{ referrerId, metadata }`
  (`Sources/InviteKit/API/InviteAPIClient.swift:37,41–42`).
- Server response is `CreateInviteResponse` —
  `{ inviteUrl, shortCode, createdAt, warning }`
  (`Sources/InviteKit/API/InviteAPIClient.swift:165–170`).
- Definition of Done — covered by tests:
  - `Tests/InviteKitTests/InviteKitTests.swift:72` —
    `testCreateInviteLinkThrowsWhenNotConfigured`.
  - `Tests/InviteKitTests/InviteKitTests.swift:83` —
    `testCreateInviteLinkSuccess`.
  - `Tests/InviteKitTests/InviteKitTests.swift:101` —
    `testCreateInviteLinkWithMetadata`.
- Callers: a referring user's main app, after they tap "invite a
  friend".

## E · Entities

- `InviteResult` (struct, `Sources/InviteKit/Models/InviteResult.
  swift:4`) — `Codable, Equatable`. Fields:
  - `referrerId: String?` (line 8) — optional because some
    invites can be stored without a referrer (see Canvas
    `006-Cross-Target-Attribution-Storage` for context).
  - `shortCode: String` (line 11) — server-issued.
  - `metadata: [String: String]?` (line 14) — caller-supplied.
  - `createdAt: Date` (line 17) — server-issued, parsed from
    ISO-8601 with fractional seconds.
  - `inviteURL: URL?` (lines 20–25) — derived; embeds
    `referrerId` as `?ref=<id>` when non-nil.
- `CreateInviteRequest` (struct, `Sources/InviteKit/API/
  InviteAPIClient.swift:160`) — `Encodable` with
  `{ referrerId, metadata }`.
- `CreateInviteResponse` (struct, `Sources/InviteKit/API/
  InviteAPIClient.swift:165`) — `Decodable` with
  `{ inviteUrl, shortCode, createdAt, warning }`. The `warning`
  field is currently parsed but not surfaced to callers.
- `InviteError` (enum, `Sources/InviteKit/Models/InviteError.
  swift:4`) — terminal failure type for this feature.

## A · Approach

- Async-first network layer: the canonical implementation is
  `async throws` (`Sources/InviteKit/API/InviteAPIClient.swift:36`);
  the completion variant wraps it in a `Task` and bridges the
  result (`Sources/InviteKit/InviteKit.swift:107–116`).
- `referrerId` and `metadata` are echoed back from the request into
  the returned `InviteResult` rather than deserialized from the
  server payload (`Sources/InviteKit/API/InviteAPIClient.swift:
  52–57`). Trade-off: avoids depending on the server returning these
  fields, but means a server-side change to either is invisible to
  the caller.
- Date parsing is tolerant: tries `withFractionalSeconds`, then
  plain ISO-8601, then falls back to `Date()` rather than throwing
  (`Sources/InviteKit/API/InviteAPIClient.swift:46–50`). Trade-off:
  a malformed `createdAt` becomes "now" instead of an error.
- Authentication: API key header (`X-API-Key`) on every request
  (`Sources/InviteKit/API/InviteAPIClient.swift:120`) — no token
  refresh, no signing.

## S · Structure

- `Sources/InviteKit/InviteKit.swift` — public static facade,
  ensures configuration and dispatches to the API client.
- `Sources/InviteKit/API/InviteAPIClientProtocol.swift` — protocol
  the facade depends on.
- `Sources/InviteKit/API/InviteAPIClient.swift` — `URLSession`-based
  default implementation; declares request/response models.
- `Sources/InviteKit/Models/InviteResult.swift` — return type.
- `Sources/InviteKit/Models/InviteError.swift` — failure type.

## O · Operations

### 1. Define Entity — InviteResult
File: `Sources/InviteKit/Models/InviteResult.swift`

1. Responsibility: caller-facing record of a created or fetched
   invite.
2. Fields / Attributes:
   - `referrerId: String?` — optional (line 8).
   - `shortCode: String` — non-optional (line 11).
   - `metadata: [String: String]?` (line 14).
   - `createdAt: Date` — defaults to `Date()` in `init`
     (line 38).
   - `inviteURL: URL?` (computed, lines 20–25).
3. Methods:
   - `init(referrerId:shortCode:metadata:createdAt:)` (line 34):
     - Logic: assigns all four fields verbatim
       (`Sources/InviteKit/Models/InviteResult.swift:40–43`).
   - `var inviteURL: URL?` (computed, line 20):
     - Logic: returns
       `https://cn1invite.com/i/<shortCode>?ref=<referrerId>` when
       `referrerId` is non-nil, else
       `https://cn1invite.com/i/<shortCode>`
       (`Sources/InviteKit/Models/InviteResult.swift:21–25`).
4. Constraints / Invariants: `Codable` and `Equatable` are
   synthesized — any field reorder must keep them synthesizable.
   Host in `inviteURL` is hard-coded; see
   `001-…-SDK-Configuration` for the [DRIFT] note.

### 2. Define Protocol — InviteAPIClientProtocol
File: `Sources/InviteKit/API/InviteAPIClientProtocol.swift`

1. Responsibility: dependency-injectable abstraction over the
   HTTP API client; lets tests substitute a mock.
2. Methods:
   - `func createInvite(referrerId: String, metadata:
     [String: String]?) async throws -> InviteResult` (line 16):
     - Logic: contractual — implementations must call
       `POST /api/v1/sdk/invites` and return an `InviteResult`
       on success.
3. Constraints / Invariants: `public protocol` so consumers (and
   tests) can implement it. All five protocol methods are async
   except `ping()`.

### 3. Implement Service — InviteAPIClient.createInvite
File: `Sources/InviteKit/API/InviteAPIClient.swift`

1. Responsibility: perform the `POST /api/v1/sdk/invites` HTTP
   exchange, decode the response, and assemble the `InviteResult`.
2. Fields / Attributes (shared by all client methods):
   - `apiKey: String` (line 8) — sent as `X-API-Key` header.
   - `baseURL: URL` (line 9).
   - `session: URLSession` (line 10) — defaults to `.shared`.
   - `decoder: JSONDecoder` (line 11) — `.iso8601`.
   - `encoder: JSONEncoder` (line 12) — `.iso8601`.
3. Methods:
   - `func createInvite(referrerId:metadata:) async throws ->
     InviteResult` (line 36):
     - Logic:
       1. `endpoint =
          baseURL.appendingPathComponent("/api/v1/sdk/invites")`
          (line 37).
       2. `request = makeRequest(url: endpoint, method: "POST")`
          (line 39).
       3. Encode `CreateInviteRequest(referrerId, metadata)` as
          the body (lines 41–42).
       4. `response: CreateInviteResponse = try await
          performRequest(request)` (line 44).
       5. Parse `createdAt` with a fractional-seconds-aware
          `ISO8601DateFormatter`, falling back to a plain
          `ISO8601DateFormatter`, falling back to `Date()`
          (lines 46–50).
       6. Return `InviteResult(referrerId: <input>, shortCode:
          response.shortCode, metadata: <input>, createdAt:
          <parsed>)` (lines 52–57). Note: caller-supplied
          `referrerId` and `metadata` are echoed; server-side
          edits to those fields are not visible.
   - `private func makeRequest(url:method:) -> URLRequest`
     (line 117):
     - Logic: sets method, `X-API-Key` header from `apiKey`,
       `Content-Type: application/json`, and
       `User-Agent: InviteKit/1.0.0`
       (`Sources/InviteKit/API/InviteAPIClient.swift:118–123`).
   - `private func performRequest<T: Decodable>(_:) async throws
     -> T` (line 126):
     - Logic: dispatches `URLSession.data(for:)`, casts to
       `HTTPURLResponse`, switches on status:
       - 200–299 → decode `T`; on decode error log `.error` and
         throw `InviteError.unknown("Failed to decode response")`
         (`Sources/InviteKit/API/InviteAPIClient.swift:134–140`).
       - 401 → `throw InviteError.invalidAPIKey` (line 143).
       - 404 → `throw InviteError.inviteNotFound` (line 146).
       - 429 → `throw InviteError.rateLimited` (line 149).
       - else → decode `ErrorResponse.message` if possible and
         throw `InviteError.serverError(statusCode:message:)`
         (lines 151–153).
4. Constraints / Invariants: `User-Agent` string is hard-coded as
   `InviteKit/1.0.0` (line 122) — must move in lockstep with any
   public version bump.

### 4. Implement Static Facade — InviteKit.createInviteLink
File: `Sources/InviteKit/InviteKit.swift`

1. Responsibility: public entry points that callers use; gate
   on configuration and forward to `apiClient.createInvite`.
2. Methods:
   - `static func createInviteLink(referrerId: String, metadata:
     [String: String]? = nil) async throws -> InviteResult`
     (line 83):
     - Logic:
       1. `try ensureConfigured()` (line 87).
       2. Force-unwrap `shared.apiClient` via `guard let`,
          throwing `InviteError.notConfigured` on failure
          (lines 89–91).
       3. `return try await apiClient.createInvite(referrerId:
          metadata:)` (line 93).
   - `static func createInviteLink(referrerId:metadata:
     completion:)` (line 102):
     - Logic: spawns a `Task`, awaits the async overload,
       converts thrown `InviteError` to
       `.failure(error)` and other errors to
       `.failure(.networkError(error))`
       (`Sources/InviteKit/InviteKit.swift:107–116`).
3. Constraints / Invariants: facade is `static`; call sites must
   not retain `InviteKit.shared`.

## N · Norms

- Public-API surface uses `async throws` as the canonical signature
  with a Result-typed completion overload for compatibility.
- Errors thrown to callers are always `InviteError` cases — never
  raw `URLError` — even in the completion bridge
  (`Sources/InviteKit/InviteKit.swift:111–115`).
- HTTP layer routes status-code → typed error in
  `performRequest(_:)` (`Sources/InviteKit/API/InviteAPIClient.
  swift:133–154`); add new server status codes there, not at call
  sites.
- All requests carry `X-API-Key`, `Content-Type: application/json`,
  and `User-Agent: InviteKit/1.0.0` via `makeRequest(...)`
  (`Sources/InviteKit/API/InviteAPIClient.swift:117–124`).

## S · Safeguards

- `ensureConfigured()` is invoked first; throws `.notConfigured`
  when the SDK has not been configured
  (`Sources/InviteKit/InviteKit.swift:87`,
  `:238–242`).
- `apiClient` is null-checked after `ensureConfigured()` returns
  (`Sources/InviteKit/InviteKit.swift:89–91`); double-guard prevents
  force-unwrap crashes if the singleton is mutated concurrently.
- 401 responses are mapped to `InviteError.invalidAPIKey`
  (`Sources/InviteKit/API/InviteAPIClient.swift:143`).
- 429 responses are mapped to `InviteError.rateLimited`
  (`Sources/InviteKit/API/InviteAPIClient.swift:149`).
- Decode failures are logged at `.error` and surfaced as
  `InviteError.unknown("Failed to decode response")` rather than
  the raw `DecodingError`
  (`Sources/InviteKit/API/InviteAPIClient.swift:138–140`).
- The completion-handler bridge fully insulates non-`InviteError`
  failures behind `.networkError(error)`
  (`Sources/InviteKit/InviteKit.swift:113–114`).
