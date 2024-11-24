import Foundation
import FoundationExtensions
import Testing

struct StringExtensionsTests {
    @Test
    func isBlank_true() {
        #expect("".isBlank)
        #expect(" ".isBlank)
        #expect(" \n ".isBlank)
    }

    @Test
    func isBlank_false() {
        #expect("a".isBlank == false)
        #expect("a ".isBlank == false)
        #expect(" a\n ".isBlank == false)
    }

    @Test
    func isNotBlank_true() {
        #expect("".isNotBlank == false)
        #expect(" ".isNotBlank == false)
        #expect(" \n ".isNotBlank == false)
    }

    @Test
    func isNotBlank_false() {
        #expect("a".isNotBlank)
        #expect("a ".isNotBlank)
        #expect(" a\n ".isNotBlank)
    }
}
