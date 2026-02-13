import XCTest
@testable import CN1InviteKit

final class CN1InviteKitTests: XCTestCase {

    override func setUp() {
        super.setUp()
        CN1InviteKit.reset()
    }

    override func tearDown() {
        CN1InviteKit.reset()
        super.tearDown()
    }

    // MARK: - URL Parsing Tests

    func testParseValidInviteURL() {
        let url = URL(string: "https://myapp.cn1invite.com/i/abc123?ref=user456")!
        let result = CN1InviteKit.parseInviteURL(url)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.shortCode, "abc123")
        XCTAssertEqual(result?.referrerId, "user456")
    }

    func testParseInviteURLWithMetadata() {
        // Base64 encoded {"campaign":"summer"}
        let metadata = Data("{\"campaign\":\"summer\"}".utf8).base64EncodedString()
        let url = URL(string: "https://myapp.cn1invite.com/i/abc123?ref=user456&meta=\(metadata)")!

        let result = CN1InviteKit.parseInviteURL(url)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.metadata?["campaign"], "summer")
    }

    func testParseInviteURLWithInvalidHost() {
        let url = URL(string: "https://example.com/i/abc123?ref=user456")!
        let result = CN1InviteKit.parseInviteURL(url)

        XCTAssertNil(result)
    }

    func testParseInviteURLWithMissingRef() {
        let url = URL(string: "https://myapp.cn1invite.com/i/abc123")!
        let result = CN1InviteKit.parseInviteURL(url)

        XCTAssertNil(result)
    }

    func testParseInviteURLWithInvalidPath() {
        let url = URL(string: "https://myapp.cn1invite.com/other/abc123?ref=user456")!
        let result = CN1InviteKit.parseInviteURL(url)

        XCTAssertNil(result)
    }

    func testParseInviteURLWithSubdomain() {
        let url = URL(string: "https://app.cn1invite.com/i/xyz789?ref=userABC")!
        let result = CN1InviteKit.parseInviteURL(url)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.shortCode, "xyz789")
        XCTAssertEqual(result?.referrerId, "userABC")
    }

    // MARK: - Storage Tests

    func testStoreAndRetrieveInvite() {
        let mockStorage = MockStorage()
        CN1InviteKit.configure(storage: mockStorage)

        let inviteData = InviteData(
            referrerId: "user123",
            shortCode: "abc123",
            metadata: ["key": "value"],
            createdAt: Date()
        )

        let stored = CN1InviteKit.storeInvite(inviteData)
        XCTAssertTrue(stored)

        let retrieved = CN1InviteKit.getStoredInvite()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.referrerId, "user123")
        XCTAssertEqual(retrieved?.shortCode, "abc123")
    }

    // MARK: - InviteData Model Tests

    func testInviteDataEquatable() {
        let date = Date()
        let invite1 = InviteData(
            referrerId: "user1",
            shortCode: "code1",
            metadata: ["key": "value"],
            createdAt: date
        )

        let invite2 = InviteData(
            referrerId: "user1",
            shortCode: "code1",
            metadata: ["key": "value"],
            createdAt: date
        )

        XCTAssertEqual(invite1, invite2)
    }

    func testInviteDataCodable() throws {
        let invite = InviteData(
            referrerId: "user123",
            shortCode: "abc123",
            metadata: ["campaign": "test"],
            createdAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(invite)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(InviteData.self, from: data)

        XCTAssertEqual(invite.referrerId, decoded.referrerId)
        XCTAssertEqual(invite.shortCode, decoded.shortCode)
        XCTAssertEqual(invite.metadata, decoded.metadata)
    }
}

// MARK: - Mock Objects

final class MockStorage: InviteStorageProtocol {
    private var storedInvite: InviteResult?

    func saveInvite(_ invite: InviteResult) {
        storedInvite = invite
    }

    func getInvite() -> InviteResult? {
        return storedInvite
    }

    func clearInvite() {
        storedInvite = nil
    }

    func hasInvite() -> Bool {
        return storedInvite != nil
    }
}
