import FoundationExtensions
import Testing

struct CacheTests {
    typealias TestCache = Cache<String, String>
    var sut = TestCache()

    @Test
    func init_hasNoSideEffects() {
        #expect(sut.isEmpty)
    }

    @Test(arguments: ["k1", "k2", "k3"])
    mutating func count_isNumberOfElementsInCache(key: String) {
        _ = sut.getOrCreateValue(for: key) {
            "value1"
        }

        #expect(sut.count == 1)
    }

    @Test
    mutating func removeAll_clearsCache() {
        _ = sut.getOrCreateValue(for: "key1") {
            "value1"
        }
        sut.removeAll()

        #expect(sut.isEmpty)
    }

    @Test
    mutating func getOrCreate_createsObjectIfNotInCache() {
        let result = sut.getOrCreateValue(for: "key1") {
            "value1"
        }

        #expect(result == "value1")
    }

    @Test
    mutating func getOrCreate_returnsCachedIfAlreadyCached() {
        _ = sut.getOrCreateValue(for: "key1") {
            "value1"
        }
        let result = sut.getOrCreateValue(for: "key1") {
            "value2"
        }

        #expect(result == "value1")
    }

    @Test
    mutating func remove_hasNoEffectIfItemNotInCache() {
        sut.remove(key: "key1")

        #expect(sut.isEmpty)
    }

    @Test(arguments: ["", "k1", "k2"])
    mutating func remove_removesItemIfInCache(key: String) {
        _ = sut.getOrCreateValue(for: key) {
            "value1"
        }
        sut.remove(key: key)

        #expect(sut.isEmpty)
    }

    @Test(arguments: ["", " ", "k1", "k2"])
    func subscript_returnsNilIfItemNotPresent(key: String) {
        let result = sut[key]

        #expect(result == nil)
        #expect(sut.isEmpty)
    }

    @Test(arguments: ["", " ", "k1", "k2"])
    mutating func subscript_returnsItemIfItemPresent(key: String) {
        _ = sut.getOrCreateValue(for: key, otherwise: {
            "value1"
        })
        let result = sut[key]

        #expect(result == "value1")
    }

    @Test(arguments: [("k1", "v1")])
    mutating func values_returnsAllValuesInTheCache(key: String, value: String) {
        _ = sut.getOrCreateValue(for: key, otherwise: {
            value
        })
        _ = sut.getOrCreateValue(for: "key2", otherwise: {
            "value2"
        })
        let result = sut.values

        #expect(result.sorted() == [value, "value2"])
    }
}
