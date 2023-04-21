import CryptoEngine
import CryptoExporter
import XCTest

struct BlockIterator: IteratorProtocol {
    let payload: Data
    func next() -> Data? {
        payload
    }
}

struct BlockExporter: Sequence {
    /// The data payload to export
    let payload: Data

    func makeIterator() -> some IteratorProtocol<Data> {
        BlockIterator(payload: payload)
    }
}

final class BlockExporterTests: XCTestCase {
    func test_iterate_iteratesOverData() {
        let payload = anyData()
        let sut = BlockExporter(payload: payload)
        var iter = sut.makeIterator()

        XCTAssertEqual(iter.next(), payload)
    }

    // MARK: - Helpers

    private func anyData() -> Data {
        Data(hex: "FFFFFFEE")
    }
}
