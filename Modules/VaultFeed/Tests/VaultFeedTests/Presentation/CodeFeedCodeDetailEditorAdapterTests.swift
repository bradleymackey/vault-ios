import Foundation
import VaultFeed
import XCTest

final class CodeFeedCodeDetailEditorAdapterTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let feed = StubCodeFeed()
        _ = makeSUT(feed: feed)

        XCTAssertTrue(feed.calls.isEmpty)
    }

    func test_update_translatesCodeDataForCall() async throws {
        let feed = StubCodeFeed()
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

        try await sut.update(item: item, edits: edits)

        await fulfillment(of: [exp])
    }

    func test_delete_deletesFromFeed() async throws {
        let feed = StubCodeFeed()
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
}

extension CodeFeedCodeDetailEditorAdapterTests {
    private func makeSUT(feed: any VaultFeed) -> VaultFeedOTPCodeDetailEditorAdapter {
        VaultFeedOTPCodeDetailEditorAdapter(vaultFeed: feed)
    }

    private class StubCodeFeed: VaultFeed {
        var calls = [String]()

        func reloadData() async {
            calls.append("\(#function)")
        }

        var updateCalled: (UUID, StoredVaultItem.Write) -> Void = { _, _ in }
        func update(id: UUID, item: StoredVaultItem.Write) async throws {
            calls.append("\(#function)")
            updateCalled(id, item)
        }

        var deleteCalled: (UUID) -> Void = { _ in }
        func delete(id: UUID) async throws {
            calls.append(#function)
            deleteCalled(id)
        }
    }
}
