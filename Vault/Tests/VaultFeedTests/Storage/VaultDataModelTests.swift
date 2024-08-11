import Foundation
import FoundationExtensions
import TestHelpers
import XCTest
@testable import VaultFeed

final class VaultDataModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let vaultStore = VaultStoreStub()
        let vaultTagStore = VaultTagStoreStub()
        _ = makeSUT(vaultStore: vaultStore, vaultTagStore: vaultTagStore)

        XCTAssertEqual(vaultStore.calledMethods, [])
        XCTAssertEqual(vaultTagStore.calledMethods, [])
    }

    @MainActor
    func test_init_initiallyEmptyData() {
        let sut = makeSUT()

        XCTAssertEqual(sut.items, [])
        XCTAssertEqual(sut.itemErrors, [])
        XCTAssertEqual(sut.itemsState, .base)
        XCTAssertNil(sut.itemsRetrievalError)
        XCTAssertEqual(sut.allTags, [])
        XCTAssertEqual(sut.allTagsState, .base)
        XCTAssertNil(sut.allTagsRetrievalError)
    }

    @MainActor
    func test_init_initiallyNotQueryingItems() {
        let sut = makeSUT()

        XCTAssertEqual(sut.itemsSearchQuery, "")
        XCTAssertEqual(sut.itemsFilteringByTags, [])
    }

    @MainActor
    func test_reloadItems_populatesNoItemsFromEmptyStore() async {
        let sut = makeSUT(vaultStore: VaultStoreStub.empty)

        await sut.reloadItems()

        XCTAssertEqual(sut.items, [])
    }

    @MainActor
    func test_reloadItems_populatesItemsFromStore() async {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        let sut = makeSUT(vaultStore: store)

        let exp = expectation(description: "Wait for reload data")
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.items, store.retrieveQueryResult.items)
    }

    @MainActor
    func test_reloadItems_populatesItemsFromStoreQueryingText() async {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        let sut = makeSUT(vaultStore: store)
        sut.itemsSearchQuery = " \tSOME QUERY 123\n "

        let exp = expectation(description: "Wait for reload data")
        store.retrieveQueryCalled = { query in
            XCTAssertEqual(query.filterText, "SOME QUERY 123")
            XCTAssertEqual(query.filterTags, [])
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.items, store.retrieveQueryResult.items)
    }

    @MainActor
    func test_reloadItems_loadsItemsQueryingTextAndFiltering() async {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        let sut = makeSUT(vaultStore: store)
        sut.itemsSearchQuery = " \tSOME QUERY 123\n "
        let filterTags: Set<Identifier<VaultItemTag>> = [.init(id: UUID())]
        sut.itemsFilteringByTags = filterTags

        let exp = expectation(description: "Wait for reload data")
        store.retrieveQueryCalled = { query in
            XCTAssertEqual(query.filterText, "SOME QUERY 123")
            XCTAssertEqual(query.filterTags, filterTags)
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.items, store.retrieveQueryResult.items)
    }

    @MainActor
    func test_reloadItems_presentsErrorOnFailure() async {
        let store = VaultStoreErroring(error: anyNSError())
        let sut = makeSUT(vaultStore: store)

        await sut.reloadData()

        XCTAssertNotNil(sut.itemsRetrievalError)
    }

    @MainActor
    func test_reloadItems_clearsExistingError() async {
        let store = VaultStoreStub()
        store.retrieveQueryCalled = { _ in
            throw anyNSError()
        }
        let sut = makeSUT(vaultStore: store)

        await sut.reloadData()

        store.retrieveQueryCalled = { _ in }

        await sut.reloadData()

        XCTAssertNil(sut.itemsRetrievalError)
    }
}

// MARK: - Helpers

extension VaultDataModelTests {
    @MainActor
    private func makeSUT(
        vaultStore: any VaultStore = VaultStoreStub(),
        vaultTagStore: any VaultTagStore = VaultTagStoreStub(),
        itemCaches: [any VaultItemCache] = []
    ) -> VaultDataModel {
        VaultDataModel(vaultStore: vaultStore, vaultTagStore: vaultTagStore, itemCaches: itemCaches)
    }
}
