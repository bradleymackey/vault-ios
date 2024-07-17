import Combine
import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class FeedViewModelTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    @MainActor
    func test_reloadData_populatesEmptyCodesFromStore() async throws {
        let sut = makeSUT(store: VaultStoreStub.empty)

        await expectSingleMutation(observable: sut, keyPath: \.codes) {
            await sut.reloadData()
        }
        XCTAssertEqual(sut.codes, [])
    }

    @MainActor
    func test_reloadData_doesNotShowErrorOnPopulatingFromEmpty() async throws {
        let sut = makeSUT(store: VaultStoreStub.empty)

        await expectNoMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNil(sut.retrievalError)
    }

    @MainActor
    func test_reloadData_populatesCodesFromStore() async throws {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        let sut = makeSUT(store: store)

        let exp = expectation(description: "Wait for reload data")
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.codes, store.retrieveQueryResult.items)
    }

    @MainActor
    func test_reloadData_populatesCodesIfQueryIsNotPresent() async throws {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        let sut = makeSUT(store: store)
        sut.searchQuery = "  " // whitespace only

        let exp = expectation(description: "Wait for reload data from normal store, not search")
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.codes, store.retrieveQueryResult.items)
    }

    @MainActor
    func test_reloadData_populatesCodesFromQueryIfQueryIsPresent() async throws {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        let sut = makeSUT(store: store)
        sut.searchQuery = " \tSOME QUERY 123\n "

        let exp = expectation(description: "Wait for reload data")
        store.retrieveQueryCalled = { query in
            XCTAssertEqual(query.searchText, "SOME QUERY 123")
            XCTAssertEqual(query.tags, [])
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.codes, store.retrieveQueryResult.items)
    }

    @MainActor
    func test_reloadData_doesNotShowErrorOnPopulatingFromNonEmpty() async throws {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        let sut = makeSUT(store: store)

        await expectNoMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNil(sut.retrievalError)
    }

    @MainActor
    func test_reloadData_presentsErrorOnFeedReloadError() async throws {
        let store = VaultStoreErroring(error: anyNSError())
        let sut = makeSUT(store: store)

        await expectSingleMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNotNil(sut.retrievalError)
    }

    @MainActor
    func test_createItem_updatesStore() async throws {
        let store = VaultStoreStub()
        let exp = expectation(description: "Wait for store update")
        store.insertStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.create(item: uniqueVaultItem().makeWritable())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createItem_reloadsAfterUpdate() async throws {
        let store = VaultStoreStub()
        let exp = expectation(description: "Wait for store update")
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.create(item: uniqueVaultItem().makeWritable())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createItem_doesNotReloadOnFailure() async throws {
        let store = VaultStoreErroring(error: anyNSError())
        let exp = expectation(description: "Wait for store update")
        exp.isInverted = true
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.create(item: uniqueVaultItem().makeWritable())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_createItem_doesNotInvalidateAnyCaches() async throws {
        let cache1 = VaultItemCacheMock()
        let cache2 = VaultItemCacheMock()
        let sut = makeSUT(store: VaultStoreStub(), caches: [cache1, cache2])

        try await sut.create(item: uniqueVaultItem().makeWritable())

        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheArgValues, [])
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheArgValues, [])
    }

    @MainActor
    func test_updateCode_updatesStore() async throws {
        let store = VaultStoreStub()
        let exp = expectation(description: "Wait for store update")
        store.updateStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.update(id: UUID(), item: uniqueVaultItem().makeWritable())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateCode_reloadsAfterUpdate() async throws {
        let store = VaultStoreStub()
        let exp = expectation(description: "Wait for store retrieve")
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.update(id: UUID(), item: uniqueVaultItem().makeWritable())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateCode_doesNotReloadOnFailure() async throws {
        let store = VaultStoreErroring(error: anyNSError())
        let exp = expectation(description: "Wait for store not retrieve")
        exp.isInverted = true
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.update(id: UUID(), item: uniqueVaultItem().makeWritable())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_updateCode_invalidatesCaches() async throws {
        let cache1 = VaultItemCacheMock()
        let cache2 = VaultItemCacheMock()
        let sut = makeSUT(store: VaultStoreStub(), caches: [cache1, cache2])

        let invalidateId = UUID()
        try await sut.update(id: invalidateId, item: uniqueVaultItem().makeWritable())

        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheArgValues, [invalidateId])
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheArgValues, [invalidateId])
    }

    @MainActor
    func test_deleteCode_removesFromStore() async throws {
        let store = VaultStoreStub()
        let exp = expectation(description: "Wait for store delete")
        store.deleteStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.delete(id: UUID())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteCode_reloadsAfterDelete() async throws {
        let store = VaultStoreStub()
        let exp = expectation(description: "Wait for store retrieve")
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.delete(id: UUID())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteCode_doesNotReloadOnFailure() async throws {
        let store = VaultStoreErroring(error: anyNSError())
        let exp = expectation(description: "Wait for store not retrieve")
        exp.isInverted = true
        store.retrieveQueryCalled = { _ in
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.delete(id: UUID())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_deleteCode_invalidatesCaches() async throws {
        let cache1 = VaultItemCacheMock()
        let cache2 = VaultItemCacheMock()
        let sut = makeSUT(store: VaultStoreStub(), caches: [cache1, cache2])

        let invalidateId = UUID()
        try await sut.delete(id: invalidateId)

        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheArgValues, [invalidateId])
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheArgValues, [invalidateId])
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT<T: VaultStoreReader>(
        store: T,
        caches: [any VaultItemCache] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedViewModel<T> {
        let sut = FeedViewModel(store: store, caches: caches)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
