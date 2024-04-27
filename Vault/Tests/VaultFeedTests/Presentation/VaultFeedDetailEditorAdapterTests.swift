import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class VaultFeedDetailEditorAdapterTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let feed = MockVaultFeed()
        _ = makeSUT(feed: feed)

        XCTAssertTrue(feed.calls.isEmpty)
    }

    func test_updateCode_translatesCodeDataForCall() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)

        var code = uniqueCode()
        code.data.accountName = "old account name"
        code.data.issuer = "old issuer name"
        var item = uniqueVaultItem(item: .otpCode(code))
        item.metadata.userDescription = "old description"

        let edits = OTPCodeDetailEdits(
            issuerTitle: "new issuer name",
            accountNameTitle: "new account name",
            description: "new description"
        )

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

        try await sut.update(id: item.metadata.id, item: code, edits: edits)

        await fulfillment(of: [exp])
    }

    func test_updateCode_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.update(id: UUID(), item: uniqueCode(), edits: .init()))
    }

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

    func test_deleteCode_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.deleteCode(id: UUID()))
    }

    func test_createNote_createsNoteInFeed() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)
        let initialEdits = SecureNoteDetailEdits(
            description: "new description",
            title: "new title",
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

        try await sut.create(initialEdits: initialEdits)

        await fulfillment(of: [exp])
    }

    func test_createNote_propagatesFailureOnError() async throws {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.create(initialEdits: .init()))
    }

    func test_updateNote_updatesNoteInFeed() async throws {
        let feed = MockVaultFeed()
        let sut = makeSUT(feed: feed)

        var note = anyStoredNote()
        note.title = "old title"
        note.contents = "old contents"
        var item = uniqueVaultItem(item: .secureNote(note))
        item.metadata.userDescription = "old description"

        let edits = SecureNoteDetailEdits(description: "new description", title: "new title", contents: "new contents")

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

        try await sut.update(id: item.metadata.id, item: note, edits: edits)

        await fulfillment(of: [exp])
    }

    func test_updateNote_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.update(id: UUID(), item: anyStoredNote(), edits: .init()))
    }

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

    func test_deleteNote_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.deleteNote(id: UUID()))
    }
}

extension VaultFeedDetailEditorAdapterTests {
    private func makeSUT(feed: any VaultFeed) -> VaultFeedDetailEditorAdapter {
        VaultFeedDetailEditorAdapter(vaultFeed: feed)
    }
}
