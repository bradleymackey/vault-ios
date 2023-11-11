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

    func test_update_translatesCodeDataForCall() async throws {
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

    func test_update_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.update(id: UUID(), item: uniqueCode(), edits: .init()))
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

        try await sut.deleteCode(id: id)

        await fulfillment(of: [exp])
    }

    func test_delete_propagatesFailureOnError() async {
        let feed = FailingVaultFeed()
        let sut = makeSUT(feed: feed)

        await XCTAssertThrowsError(try await sut.deleteCode(id: UUID()))
    }
}

extension VaultFeedDetailEditorAdapterTests {
    private func makeSUT(feed: any VaultFeed) -> VaultFeedDetailEditorAdapter {
        VaultFeedDetailEditorAdapter(vaultFeed: feed)
    }
}
