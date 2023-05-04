import Combine
import Foundation
import OTPFeed
import XCTest

final class FeedViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!
    override func setUp() {
        super.setUp()
        cancellables = Set()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    func test_reloadData_populatesEmptyCodesFromStore() async throws {
        let sut = FeedViewModel(store: StubStore.empty)
        let getCodes = sut.$codes.collectNext(1)

        let codes = try await awaitPublisher(getCodes, when: {
            await sut.reloadData()
        })
        XCTAssertEqual(codes, [[]])
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromEmpty() async throws {
        let sut = FeedViewModel(store: StubStore.empty)

        await awaitNoPublish(publisher: sut.$retrievalError.nextElements(), when: {
            await sut.reloadData()
        })
    }

    func test_reloadData_populatesCodesFromStore() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = FeedViewModel(store: store)
        let publisher = sut.$codes.collectNext(1)

        let codes = try await awaitPublisher(publisher, when: {
            await sut.reloadData()
        })
        XCTAssertEqual(codes, [store.codes])
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromNonEmpty() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = FeedViewModel(store: store)

        await awaitNoPublish(publisher: sut.$retrievalError.nextElements(), when: {
            await sut.reloadData()
        })
    }

    func test_reloadData_presentsErrorOnFeedReloadError() async throws {
        let sut = FeedViewModel(store: ErrorStubStore(error: anyNSError()))
        let publisher = sut.$retrievalError.collectNext(1)

        let values = try await awaitPublisher(publisher, when: {
            await sut.reloadData()
        })
        XCTAssertEqual(values.count, 1)
    }

    // MARK: - Helpers

    private struct StubStore: OTPCodeStoreReader {
        var codes = [StoredOTPCode]()
        func retrieve() async throws -> [StoredOTPCode] {
            codes
        }

        static var empty: StubStore {
            .init(codes: [])
        }
    }

    private struct ErrorStubStore: OTPCodeStoreReader {
        var error: Error
        func retrieve() async throws -> [StoredOTPCode] {
            throw error
        }
    }
}
