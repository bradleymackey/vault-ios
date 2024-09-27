import Foundation
import FoundationExtensions
import Testing

@Test
func sequence_reducedToSet() {
    #expect(Set([1, 2, 3]).reducedToSet() == [1, 2, 3])
    #expect([Int]().reducedToSet() == [])
    #expect([1, 1, 1, 1].reducedToSet() == [1])
}
