import Combine
import CombineTestExtensions
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
        let getCodes = sut.$codes.recordPublished(numberOfRecords: 1)

        await sut.reloadData()

        let codes = getCodes.waitAndCollectRecords()
        XCTAssertEqual(codes, [.value([])])
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromEmpty() async throws {
        let sut = FeedViewModel(store: StubStore.empty)
        let exp = expectationNoPublish(publisher: sut.$retrievalError.dropFirst(), bag: &cancellables)

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 0.5)
    }

    func test_reloadData_populatesCodesFromStore() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = FeedViewModel(store: store)
        let getCodes = sut.$codes.recordPublished(numberOfRecords: 1)

        await sut.reloadData()

        let codes = getCodes.waitAndCollectRecords()
        XCTAssertEqual(codes, [.value(store.codes)])
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromNonEmpty() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = FeedViewModel(store: store)
        let exp = expectationNoPublish(publisher: sut.$retrievalError.dropFirst(), bag: &cancellables)

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 0.5)
    }

    func test_reloadData_presentsErrorOnFeedReloadError() async throws {
        let sut = FeedViewModel(store: ErrorStubStore(error: anyNSError()))
        let getErrors = sut.$retrievalError.recordPublished(numberOfRecords: 1)

        await sut.reloadData()

        let errors = getErrors.waitAndCollectRecords()
        XCTAssertEqual(errors.count, 1)
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
