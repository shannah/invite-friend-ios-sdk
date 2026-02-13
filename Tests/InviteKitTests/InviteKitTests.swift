import XCTest
@testable import InviteKit

final class InviteKitTests: XCTestCase {

    override func setUp() {
        super.setUp()
        InviteKit.reset()
    }

    override func tearDown() {
        InviteKit.reset()
        super.tearDown()
    }

    // MARK: - Configuration Tests

    func testConfigureWithAPIKey() {
        InviteKit.configure(apiKey: "test-api-key")
        // Should not throw
    }

    func testConfigureWithAPIKeyAndBaseURL() {
        let baseURL = URL(string: "https://custom.api.com")!
        InviteKit.configure(apiKey: "test-api-key", baseURL: baseURL)
        // Should not throw
    }

    // MARK: - Attribution Tests

    func testCheckForInviteWithNoData() {
        InviteKit.configure(apiKey: "test-api-key")
        let result = InviteKit.checkForInvite()
        XCTAssertNil(result)
    }

    func testCheckForInviteWithStoredData() {
        let mockStorage = MockStorage()
        let mockAPIClient = MockAPIClient()

        let invite = InviteResult(
            referrerId: "user123",
            shortCode: "abc123",
            metadata: ["campaign": "summer"],
            createdAt: Date()
        )
        mockStorage.saveInvite(invite)

        InviteKit.configure(apiKey: "test-api-key", apiClient: mockAPIClient, storage: mockStorage)

        let result = InviteKit.checkForInvite()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.referrerId, "user123")
        XCTAssertEqual(result?.shortCode, "abc123")
    }

    func testClearInvite() {
        let mockStorage = MockStorage()
        let mockAPIClient = MockAPIClient()

        let invite = InviteResult(referrerId: "user123", shortCode: "abc123")
        mockStorage.saveInvite(invite)

        InviteKit.configure(apiKey: "test-api-key", apiClient: mockAPIClient, storage: mockStorage)
        InviteKit.clearInvite()

        XCTAssertNil(mockStorage.getInvite())
    }

    // MARK: - Create Invite Tests

    func testCreateInviteLinkThrowsWhenNotConfigured() async {
        do {
            _ = try await InviteKit.createInviteLink(referrerId: "user123")
            XCTFail("Expected error to be thrown")
        } catch let error as InviteError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateInviteLinkSuccess() async throws {
        let mockStorage = MockStorage()
        let mockAPIClient = MockAPIClient()

        let expectedResult = InviteResult(
            referrerId: "user123",
            shortCode: "generated-code",
            createdAt: Date()
        )
        mockAPIClient.createInviteResult = .success(expectedResult)

        InviteKit.configure(apiKey: "test-api-key", apiClient: mockAPIClient, storage: mockStorage)

        let result = try await InviteKit.createInviteLink(referrerId: "user123")
        XCTAssertEqual(result.referrerId, "user123")
        XCTAssertEqual(result.shortCode, "generated-code")
    }

    func testCreateInviteLinkWithMetadata() async throws {
        let mockStorage = MockStorage()
        let mockAPIClient = MockAPIClient()

        let expectedResult = InviteResult(
            referrerId: "user123",
            shortCode: "generated-code",
            metadata: ["campaign": "test"],
            createdAt: Date()
        )
        mockAPIClient.createInviteResult = .success(expectedResult)

        InviteKit.configure(apiKey: "test-api-key", apiClient: mockAPIClient, storage: mockStorage)

        let result = try await InviteKit.createInviteLink(
            referrerId: "user123",
            metadata: ["campaign": "test"]
        )

        XCTAssertEqual(result.metadata?["campaign"], "test")
    }

    // MARK: - Record Event Tests

    func testRecordEventThrowsWhenNotConfigured() async {
        do {
            try await InviteKit.recordEvent(shortCode: "abc123", eventType: .accepted)
            XCTFail("Expected error to be thrown")
        } catch let error as InviteError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRecordEventSuccess() async throws {
        let mockStorage = MockStorage()
        let mockAPIClient = MockAPIClient()
        mockAPIClient.recordEventResult = .success(())

        InviteKit.configure(apiKey: "test-api-key", apiClient: mockAPIClient, storage: mockStorage)

        try await InviteKit.recordEvent(shortCode: "abc123", eventType: .installed)
        XCTAssertEqual(mockAPIClient.recordedEventType, .installed)
        XCTAssertEqual(mockAPIClient.recordedShortCode, "abc123")
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

final class MockAPIClient: InviteAPIClientProtocol {
    var createInviteResult: Result<InviteResult, InviteError> = .failure(.notConfigured)
    var getInviteResult: Result<InviteResult, InviteError> = .failure(.notConfigured)
    var recordEventResult: Result<Void, InviteError> = .failure(.notConfigured)
    var getConfigResult: Result<InviteConfig, InviteError> = .failure(.notConfigured)
    var pingResult: Bool = true

    var recordedEventType: InviteEventType?
    var recordedShortCode: String?

    func createInvite(referrerId: String, metadata: [String: String]?) async throws -> InviteResult {
        switch createInviteResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    func getInvite(shortCode: String) async throws -> InviteResult {
        switch getInviteResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    func recordEvent(shortCode: String, eventType: InviteEventType) async throws {
        recordedShortCode = shortCode
        recordedEventType = eventType

        switch recordEventResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func getConfig() async throws -> InviteConfig {
        switch getConfigResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    func ping() async -> Bool {
        return pingResult
    }
}
