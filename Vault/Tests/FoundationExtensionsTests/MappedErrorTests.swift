import Foundation
import FoundationExtensions
import XCTest

final class MappedErrorTests: XCTestCase {
    func test_withMappedError_noErrorReturnsValue() throws {
        var callCount = 0
        let result = try withMappedError {
            100
        } error: {
            callCount += 1
            return $0
        }

        XCTAssertEqual(result, 100)
        XCTAssertEqual(callCount, 0)
    }

    func test_withMappedError_throwCallsErrorMap() throws {
        var callCount = 0
        XCTAssertThrowsError(try withMappedError {
            throw TestError()
        } error: {
            callCount += 1
            return $0
        })
        XCTAssertEqual(callCount, 1)
    }

    func test_withCatchingError_returnsNilIfNoError() throws {
        let result = withCatchingError {
            100
        }

        XCTAssertNil(result)
    }

    func test_withCatchingError_returnsErrorIfError() throws {
        let result = withCatchingError {
            throw TestError()
        }

        XCTAssertEqual(result as? TestError, TestError())
    }

    struct TestError: Error, Equatable {}
}
