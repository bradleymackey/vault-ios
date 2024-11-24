import Foundation
import FoundationExtensions
import Testing

enum CollectionExtensionsTests {
    struct IsNotEmpty {
        @Test
        func hasValues() {
            var a = Set<Int>()
            a.insert(1)
            #expect(a.isNotEmpty)

            let b = [1]
            #expect(b.isNotEmpty)
        }

        @Test
        func noValues() {
            let a = Set<Int>()
            #expect(!a.isNotEmpty)

            let b = [Int]()
            #expect(!b.isNotEmpty)
        }
    }

    struct SafeIndex {
        @Test
        func nil_whenOutOfBounds() {
            let a: [Int] = [1, 2, 3]
            #expect(a[safeIndex: 3] == nil)
            #expect(a[safeIndex: -1] == nil)
            #expect(a[safeIndex: 4] == nil)
            #expect(a[safeIndex: .max] == nil)
        }

        @Test
        func value_whenInBounds() {
            let a: [Int] = [1, 2, 3]
            #expect(a[safeIndex: 0] == 1)
            #expect(a[safeIndex: 1] == 2)
            #expect(a[safeIndex: 2] == 3)
        }
    }
}
