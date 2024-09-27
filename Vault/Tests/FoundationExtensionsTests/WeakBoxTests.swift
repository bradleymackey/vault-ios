import FoundationExtensions
import Testing

struct WeakBoxTests {
    @Test
    func value_isRetainedWeakly() throws {
        var source: Person? = Person()
        let box = WeakBox(source)

        try #require(box.value != nil)

        source = nil

        #expect(box.value == nil)
    }
}

// MARK: - Helpers

extension WeakBoxTests {
    class Person {
        var name: String = "tom"
    }
}
