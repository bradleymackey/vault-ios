import FoundationExtensions
import XCTest

final class WeakBoxTests: XCTestCase {
    func test_value_isRetainedWeakly() {
        var source: Person? = Person()
        let box = WeakBox(source)

        XCTAssertNotNil(box.value)

        source = nil

        XCTAssertNil(box.value)
    }
}

// MARK: - Helpers

extension WeakBoxTests {
    class Person {
        var name: String = "tom"
    }
}
