import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class VaultFeedDetailEditorAdapterTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let feed = MockVaultFeed()
        _ = makeSUT(feed: feed)

        XCTAssertTrue(feed.calls.isEmpty)
    }

    @MainActor
    func test_createCode_createsOTPCodeInFeed_createsCodeInFeed() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)
        let initialCode = OTPAuthCode(
            type: .totp(period: 40),
            data: .init(secret: .empty(), algorithm: .sha256, digits: .default, accountName: "myacc", issuer: "myiss")
        )
        let initialEdits = OTPCodeDetailEdits(
            hydratedFromCode: initialCode,
            userDescription: "mydesc",
            color: nil
        )

        let exp = expectation(description: "Wait for creation")
        feed.createCalled = { data in
            defer { exp.fulfill() }
            switch data.item {
            case let .otpCode(code):
                XCTAssertEqual(
                    code,
                    initialCode,
                    "The code that is saved should be the same as the state from the edits"
                )
            default:
                XCTFail("invalid kind")
            }
        }

        try await sut.createCode(initialEdits: initialEdits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createCode_propagatesFailureOnError() async throws {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.createCode(initialEdits: anyOTPCodeDetailEdits()))
    }

    @MainActor
    func test_updateCode_translatesCodeDataForCall() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)

        var code = uniqueCode()
        code.data.accountName = "old account name"
        code.data.issuer = "old issuer name"
        var item = uniqueVaultItem(item: .otpCode(code))
        item.metadata.userDescription = "old description"
        let color = VaultItemColor(red: 0.0, green: 0.0, blue: 0.0)
        item.metadata.color = color

        var edits = OTPCodeDetailEdits(
            hydratedFromCode: code,
            userDescription: "mydesc",
            color: VaultItemColor(red: 0.5, green: 0.5, blue: 0.5)
        )
        edits.issuerTitle = "new issuer name"
        edits.accountNameTitle = "new account name"
        edits.description = "new description"

        let exp = expectation(description: "Wait for update")
        feed.updateCalled = { _, data in
            XCTAssertEqual(data.userDescription, "new description")
            switch data.item {
            case let .otpCode(otpCode):
                XCTAssertEqual(otpCode.data.accountName, "new account name")
                XCTAssertEqual(otpCode.data.issuer, "new issuer name")
            case .secureNote:
                XCTFail("invalid kind")
            }
            exp.fulfill()
        }

        try await sut.updateCode(id: item.metadata.id, item: code, edits: edits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateCode_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.updateCode(
            id: UUID(),
            item: uniqueCode(),
            edits: anyOTPCodeDetailEdits()
        ))
    }

    @MainActor
    func test_deleteCode_deletesFromFeed() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)

        let id = UUID()

        let exp = expectation(description: "Wait for delete")
        feed.deleteCalled = { actualID in
            XCTAssertEqual(id, actualID)
            exp.fulfill()
        }

        try await sut.deleteCode(id: id)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteCode_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.deleteCode(id: UUID()))
    }

    @MainActor
    func test_createNote_createsNoteInFeed() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)
        let initialEdits = SecureNoteDetailEdits(
            title: "new title",
            description: "new description",
            contents: "new contents"
        )

        let exp = expectation(description: "Wait for creation")
        feed.createCalled = { data in
            defer { exp.fulfill() }
            XCTAssertEqual(data.userDescription, "new description")
            switch data.item {
            case let .secureNote(note):
                XCTAssertEqual(note.title, "new title")
                XCTAssertEqual(note.contents, "new contents")
            default:
                XCTFail("invalid kind")
            }
        }

        try await sut.createNote(initialEdits: initialEdits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createNote_propagatesFailureOnError() async throws {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.createNote(initialEdits: .init()))
    }

    @MainActor
    func test_updateNote_updatesNoteInFeed() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)

        var note = anyStoredNote()
        note.title = "old title"
        note.contents = "old contents"
        var item = uniqueVaultItem(item: .secureNote(note))
        item.metadata.userDescription = "old description"

        let edits = SecureNoteDetailEdits(title: "new title", description: "new description", contents: "new contents")

        let exp = expectation(description: "Wait for update")
        feed.updateCalled = { _, data in
            defer { exp.fulfill() }
            XCTAssertEqual(data.userDescription, "new description")
            switch data.item {
            case let .secureNote(note):
                XCTAssertEqual(note.title, "new title")
                XCTAssertEqual(note.contents, "new contents")
            default:
                XCTFail("invalid kind")
            }
        }

        try await sut.updateNote(id: item.metadata.id, item: note, edits: edits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateNote_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.updateNote(id: UUID(), item: anyStoredNote(), edits: .init()))
    }

    @MainActor
    func test_deleteNote_deletesFromFeed() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)

        let id = UUID()

        let exp = expectation(description: "Wait for delete")
        feed.deleteCalled = { actualID in
            XCTAssertEqual(id, actualID)
            exp.fulfill()
        }

        try await sut.deleteNote(id: id)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteNote_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.deleteNote(id: UUID()))
    }
}

extension VaultFeedDetailEditorAdapterTests {
    @MainActor
    private func makeSUT(feed: any VaultFeed) -> VaultFeedDetailEditorAdapter {
        VaultFeedDetailEditorAdapter(vaultFeed: feed)
    }

    private func anyOTPCodeDetailEdits() -> OTPCodeDetailEdits {
        .init(
            codeType: .totp,
            totpPeriodLength: 30,
            hotpCounterValue: 0,
            secretBase32String: "",
            algorithm: .sha1,
            numberOfDigits: 6,
            issuerTitle: "iss",
            accountNameTitle: "acc",
            description: "desc",
            color: nil
        )
    }
}
