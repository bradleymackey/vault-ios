import Foundation
import FoundationExtensions
import Testing

struct DataRandomTests {
    @Test
    func random_producesZeroBytes() {
        let sut = Data.random(count: 0)

        #expect(sut.isEmpty)
    }

    @Test(arguments: [1, 100, 1024])
    func random_producesGivenNumberOfBytes(bytes: Int) {
        let sut = Data.random(count: bytes)

        #expect(sut.count == bytes)
    }
}
