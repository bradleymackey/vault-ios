import Foundation
import FoundationExtensions
import Testing

struct IdentifiableSelfTests {
    enum MockItem: IdentifiableSelf {
        case one
        case two
    }

    @Test
    func selfIsIdentifiedBySelf() {
        #expect(MockItem.one.id == MockItem.one.id)
        #expect(MockItem.one.id != MockItem.two.id)
    }
}
