import CombineTestExtensions
import Foundation
import OTPFeed
import XCTest

final class FeedViewModelTests: XCTestCase {
    func test_reloadData_populatesEmptyCodesFromStore() async throws {
        let sut = FeedViewModel(store: StubStore.empty)
        let getCodes = sut.$codes.record(numberOfRecords: 1)

        await sut.reloadData()

        let codes = getCodes.waitAndCollectRecords()
        XCTAssertEqual(codes, [.value([]), .value([])])
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromEmpty() async throws {
        let sut = FeedViewModel(store: StubStore.empty)
        let getErrors = sut.$retrievalError.record(numberOfRecords: 1)

        await sut.reloadData()

        let errors = getErrors.waitAndCollectRecords()
        XCTAssertEqual(errors, [.value(nil)])
    }

    func test_reloadData_populatesCodesFromStore() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = FeedViewModel(store: store)
        let getCodes = sut.$codes.record(numberOfRecords: 2)

        await sut.reloadData()

        let codes = getCodes.waitAndCollectRecords()
        XCTAssertEqual(codes, [.value([]), .value(store.codes)])
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromNonEmpty() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = FeedViewModel(store: store)
        let getErrors = sut.$retrievalError.record(numberOfRecords: 1)

        await sut.reloadData()

        let errors = getErrors.waitAndCollectRecords()
        XCTAssertEqual(errors, [.value(nil)])
    }

    func test_reloadData_presentsErrorOnFeedReloadError() async throws {
        let sut = FeedViewModel(store: ErrorStubStore(error: anyNSError()))
        let getErrors = sut.$retrievalError.record(numberOfRecords: 1)

        await sut.reloadData()

        let errors = getErrors.waitAndCollectRecords()
        XCTAssertEqual(errors.count, 2)
    }

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
