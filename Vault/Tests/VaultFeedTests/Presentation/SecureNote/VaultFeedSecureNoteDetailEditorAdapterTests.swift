import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class VaultFeedSecureNoteDetailEditorAdapterTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let feed = MockVaultFeed()
        _ = makeSUT(feed: feed)

        XCTAssertTrue(feed.calls.isEmpty)
    }

    func test_update_translatesCodeDataForCall() async throws {
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
            XCTAssertEqual(data.userDescription, "new description")
            switch data.item {
            case let .secureNote(note):
                XCTAssertEqual(note.title, "new title")
                XCTAssertEqual(note.contents, "new contents")
            default:
                XCTFail("invalid kind")
            }
            exp.fulfill()
        }

        try await sut.update(id: item.metadata.id, item: note, edits: edits)

        await fulfillment(of: [exp])
    }

    func test_update_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.update(id: UUID(), item: anyStoredNote(), edits: .init()))
    }

    func test_delete_deletesFromFeed() async throws {
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

    func test_delete_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.deleteNote(id: UUID()))
    }
}

extension VaultFeedSecureNoteDetailEditorAdapterTests {
    private func makeSUT(feed: any VaultFeed) -> VaultFeedSecureNoteDetailEditorAdapter {
        VaultFeedSecureNoteDetailEditorAdapter(vaultFeed: feed)
    }
}
