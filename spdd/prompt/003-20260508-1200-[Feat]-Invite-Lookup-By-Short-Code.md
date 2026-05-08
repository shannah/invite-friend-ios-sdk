---
bootstrap: true
generated_at: 2026-05-08T12:00:00-07:00
---

# REASONS Canvas: Invite Lookup By Short Code

## R · Requirements

- A configured main-app caller can look up an existing invite from
  the server by its `shortCode` via
  `InviteKit.getInvite(shortCode:) async throws -> InviteResult`
  (`Sources/InviteKit/InviteKit.swift:129`).
- Primary use-case: when the App Clip stored an invite without a
  `referrerId` (no `?ref=` in the URL), the main app can resolve
  the full referrer record by short code
  (see `Sources/InviteKit/InviteKit.swift:121–128` doc-comment).
- Wire format: `GET {baseURL}/api/v1/sdk/invites/{shortCode}`
  (`Sources/InviteKit/API/InviteAPIClient.swift:61`).
- Response type: `InviteDetailsResponse` —
  `{ shortCode, referrerId, metadata, createdAt }`
  (`Sources/InviteKit/API/InviteAPIClient.swift:172–177`).
- Definition of Done — the protocol method is exercised by
  `MockAPIClient.getInvite` in
  `Tests/InviteKitTests/InviteKitTests.swift:190–197`. There is no
  dedicated success-path test for `InviteKit.getInvite(shortCode:)`
  itself yet → `[INFERRED]` test coverage gap.
- Callers: the main app, after `checkForInvite()` returns an
  `InviteResult` whose `referrerId` is `nil`.

## E · Entities

- `InviteResult` — see `002-…-Invite-Link-Creation` Canvas. Same
  return type for create and lookup.
- `InviteDetailsResponse` (`Sources/InviteKit/API/InviteAPIClient.
  swift:172`) — wire-format type private to the API client.
  Fields:
  - `shortCode: String` (line 173).
  - `referrerId: String` (line 174) — non-optional in the wire
    type; if the server stored a referrer-less invite this would
    fail to decode.
  - `metadata: [String: String]?` (line 175).
  - `createdAt: Date` (line 176) — decoded via the client's
    `JSONDecoder` with `.iso8601` strategy
    (`Sources/InviteKit/API/InviteAPIClient.swift:28`).

## A · Approach

- Server is the source of truth for invite data; the main app only
  hits this endpoint when the locally stored `InviteResult`
  (populated by the App Clip) is incomplete.
- Lookup uses the same shared `URLSession`-based `InviteAPIClient`
  and the same `performRequest` error mapping as
  `createInvite`/`recordEvent` — see `002-…-Invite-Link-Creation`
  for the protocol.
- Wire-format `referrerId` is non-optional
  (`Sources/InviteKit/API/InviteAPIClient.swift:174`) — server
  contract assumes every fetched invite has a referrer; mismatch
  with `InviteResult.referrerId: String?` is intentional but
  fragile.
- Trade-off: lookup by short code is uncached — every call hits
  the server. Acceptable because lookup runs at most once per
  install on the post-attribution flow.

## S · Structure

- `Sources/InviteKit/InviteKit.swift` — facade method
  `getInvite(shortCode:)`.
- `Sources/InviteKit/API/InviteAPIClientProtocol.swift` —
  `getInvite(shortCode:)` protocol method.
- `Sources/InviteKit/API/InviteAPIClient.swift` — `URLSession`
  implementation and the `InviteDetailsResponse` wire model.

## O · Operations

### 1. Define Protocol Method — InviteAPIClientProtocol.getInvite
File: `Sources/InviteKit/API/InviteAPIClientProtocol.swift`

1. Responsibility: contract for fetching an invite by short code.
2. Methods:
   - `func getInvite(shortCode: String) async throws ->
     InviteResult` (line 23):
     - Logic: contractual — implementations must call
       `GET /api/v1/sdk/invites/{shortCode}` and return an
       `InviteResult` populated from the server response.
3. Constraints / Invariants: must throw `InviteError.inviteNotFound`
   for a 404 — see `performRequest` in
   `002-…-Invite-Link-Creation`.

### 2. Implement Service — InviteAPIClient.getInvite
File: `Sources/InviteKit/API/InviteAPIClient.swift`

1. Responsibility: perform the GET, decode
   `InviteDetailsResponse`, and project it onto `InviteResult`.
2. Methods:
   - `func getInvite(shortCode: String) async throws ->
     InviteResult` (line 60):
     - Logic:
       1. `endpoint = baseURL.appendingPathComponent(
          "/api/v1/sdk/invites/\(shortCode)")` (line 61).
       2. `request = makeRequest(url: endpoint, method: "GET")`
          (line 63).
       3. `response: InviteDetailsResponse = try await
          performRequest(request)` (line 64).
       4. Return `InviteResult(referrerId: response.referrerId,
          shortCode: response.shortCode, metadata:
          response.metadata, createdAt: response.createdAt)`
          (lines 66–71). Note: unlike `createInvite`, this path
          uses the server's `referrerId`, `metadata`, and
          `createdAt` directly.
3. Constraints / Invariants: `shortCode` is interpolated into the
   path without escaping
   (`Sources/InviteKit/API/InviteAPIClient.swift:61`). Server is
   trusted to issue URL-safe short codes; if a non-URL-safe code
   reached this method the underlying URL build could silently
   drop characters → `[INFERRED]` invariant.

### 3. Implement Static Facade — InviteKit.getInvite
File: `Sources/InviteKit/InviteKit.swift`

1. Responsibility: public entry point gated on configuration.
2. Methods:
   - `static func getInvite(shortCode: String) async throws ->
     InviteResult` (line 129):
     - Logic:
       1. `try ensureConfigured()` (line 130).
       2. `guard let apiClient = shared.apiClient else { throw
          InviteError.notConfigured }` (lines 132–134).
       3. `return try await apiClient.getInvite(shortCode:)`
          (line 136).
3. Constraints / Invariants: no completion-handler overload exists
   for this method (only `createInviteLink` and `recordEvent` have
   one) → `[INFERRED]` API asymmetry.

## N · Norms

- Same HTTP conventions as `002-…-Invite-Link-Creation`: shared
  `makeRequest`/`performRequest` plumbing
  (`Sources/InviteKit/API/InviteAPIClient.swift:117, 126`).
- Status-code → `InviteError` mapping is centralised in
  `performRequest`; lookup-specific failure (404) flows through
  `InviteError.inviteNotFound`
  (`Sources/InviteKit/API/InviteAPIClient.swift:146`).
- Wire model `InviteDetailsResponse` is internal to
  `InviteAPIClient.swift`; only `InviteResult` is part of the
  public surface.

## S · Safeguards

- `ensureConfigured()` is the first call in
  `InviteKit.getInvite(shortCode:)`
  (`Sources/InviteKit/InviteKit.swift:130`).
- `apiClient` is null-checked after configuration is verified
  (`Sources/InviteKit/InviteKit.swift:132–134`).
- 404 → `InviteError.inviteNotFound`
  (`Sources/InviteKit/API/InviteAPIClient.swift:146`); 401 →
  `.invalidAPIKey` (line 143); 429 → `.rateLimited` (line 149); all
  other non-2xx → `.serverError(statusCode:message:)` (line 153).
- A decode failure (e.g. server omits `referrerId`) is mapped to
  `InviteError.unknown("Failed to decode response")` rather than
  the raw `DecodingError`
  (`Sources/InviteKit/API/InviteAPIClient.swift:138–140`).
- `[INFERRED]` — there is no validation of the supplied
  `shortCode` (length, charset) before it is interpolated into the
  URL. Defence-in-depth would happen server-side.
