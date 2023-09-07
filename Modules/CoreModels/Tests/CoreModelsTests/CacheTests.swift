import CoreModels
import XCTest

final class CacheTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let sut = makeSUT()

        XCTAssertEqual(sut.count, 0)
    }

    func test_count_isNumberOfElementsInCache() {
        var sut = makeSUT()

        _ = sut.get(key: "key1") {
            "value1"
        }

        XCTAssertEqual(sut.count, 1)
    }

    func test_removeAll_clearsCache() {
        var sut = makeSUT()

        _ = sut.get(key: "key1") {
            "value1"
        }
        sut.removeAll()

        XCTAssertEqual(sut.count, 0)
    }

    func test_get_createsObjectIfNotInCache() {
        var sut = makeSUT()

        let result = sut.get(key: "key1") {
            "value1"
        }

        XCTAssertEqual(result, "value1")
    }

    func test_get_returnsCachedIfAlreadyCached() {
        var sut = makeSUT()

        _ = sut.get(key: "key1") {
            "value1"
        }
        let result = sut.get(key: "key1") {
            "value2"
        }

        XCTAssertEqual(result, "value1")
    }

    func test_remove_hasNoEffectIfItemNotInCache() {
        var sut = makeSUT()

        sut.remove(key: "key1")

        XCTAssertEqual(sut.count, 0)
    }

    func test_remove_removesItemIfInCache() {
        var sut = makeSUT()

        _ = sut.get(key: "key1") {
            "value1"
        }
        sut.remove(key: "key1")

        XCTAssertEqual(sut.count, 0)
    }

    func test_subscript_returnsNilIfItemNotPresent() {
        let sut = makeSUT()

        let result = sut["key1"]

        XCTAssertNil(result)
    }

    func test_subscript_returnsItemIfItemPresent() {
        var sut = makeSUT()

        _ = sut.get(key: "key1", otherwise: {
            "value1"
        })
        let result = sut["key1"]

        XCTAssertEqual(result, "value1")
    }
}

extension CacheTests {
    typealias TestCache = Cache<String, String>
    private func makeSUT() -> TestCache {
        TestCache()
    }
}
