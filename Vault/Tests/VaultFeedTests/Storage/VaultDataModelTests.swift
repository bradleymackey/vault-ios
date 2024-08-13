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
    func test_isSearching_whenQueryingItems() {
        let sut = makeSUT()
        sut.itemsSearchQuery = " \tSOME QUERY 123\n "

        XCTAssertTrue(sut.isSearching)
    }

    @MainActor
    func test_isSearching_whenNotQueryingItems() {
        let sut = makeSUT()
        sut.itemsSearchQuery = ""
        // filtering tags does not count as searching
        sut.itemsFilteringByTags = [.init(id: UUID())]

        XCTAssertFalse(sut.isSearching)
    }

    @MainActor
    func test_toggleFiltering_addsTagToFiltering() {
        let sut = makeSUT()
        let tagID = Identifier<VaultItemTag>.new()

        sut.toggleFiltering(tag: tagID)

        XCTAssertEqual(sut.itemsFilteringByTags, [tagID])
    }

    @MainActor
    func test_toggleFiltering_removesTagFromFiltering() {
        let sut = makeSUT()
        let tagID = Identifier<VaultItemTag>.new()
        sut.itemsFilteringByTags = [tagID]

        sut.toggleFiltering(tag: tagID)

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

    @MainActor
    func test_insert_createsItemInStoreAndReloads() async throws {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)
        let item = uniqueVaultItem().makeWritable()

        try await sut.insert(item: item)

        XCTAssertEqual(store.calledMethods, [.insert, .retrieve])
    }

    @MainActor
    func test_update_updatesItemInvalidatesAndReloads() async throws {
        let store = VaultStoreStub()
        let cache1 = VaultItemCacheMock()
        let cache2 = VaultItemCacheMock()
        let sut = makeSUT(vaultStore: store, itemCaches: [cache1, cache2])
        let item = uniqueVaultItem().makeWritable()

        try await sut.update(itemID: .new(), data: item)

        XCTAssertEqual(store.calledMethods, [.update, .retrieve])
        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheCallCount, 1)
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheCallCount, 1)
    }

    @MainActor
    func test_delete_deletesItemInvalidatesAndReloads() async throws {
        let store = VaultStoreStub()
        let cache1 = VaultItemCacheMock()
        let cache2 = VaultItemCacheMock()
        let sut = makeSUT(vaultStore: store, itemCaches: [cache1, cache2])

        try await sut.delete(itemID: .new())

        XCTAssertEqual(store.calledMethods, [.delete, .retrieve])
        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheCallCount, 1)
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheCallCount, 1)
    }

    @MainActor
    func test_reorder_reordersItemsInStore() async throws {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)
        let items = [uniqueVaultItem(), uniqueVaultItem()].map(\.id)

        try await sut.reorder(items: Set(items), to: .start)

        XCTAssertEqual(store.calledMethods, [.reorder])
    }

    @MainActor
    func test_insertTag_createsTagInStoreAndReloads() async throws {
        let store = VaultTagStoreStub()
        let sut = makeSUT(vaultTagStore: store)
        let tag = anyVaultItemTag().makeWritable()

        try await sut.insert(tag: tag)

        XCTAssertEqual(store.calledMethods, [.insertTag, .retrieveTags])
    }

    @MainActor
    func test_updateTag_updatesTagInStoreAndReloads() async throws {
        let store = VaultTagStoreStub()
        let sut = makeSUT(vaultTagStore: store)
        let tag = anyVaultItemTag().makeWritable()

        try await sut.update(tagID: .new(), data: tag)

        XCTAssertEqual(store.calledMethods, [.updateTag, .retrieveTags])
    }

    @MainActor
    func test_deleteTag_deletesTagInStoreAndReloads() async throws {
        let tagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultTagStore: tagStore)

        try await sut.delete(tagID: .new())

        XCTAssertEqual(tagStore.calledMethods, [.deleteTag, .retrieveTags])
    }

    @MainActor
    func test_deleteTag_removesFromCurrentFilteringAndReloads() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultStore: store, vaultTagStore: tagStore)
        let tagID = Identifier<VaultItemTag>.new()
        sut.itemsFilteringByTags = [tagID]

        try await sut.delete(tagID: tagID)

        XCTAssertEqual(store.calledMethods, [.retrieve])
        XCTAssertEqual(sut.itemsFilteringByTags, [])
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
