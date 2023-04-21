import CryptoEngine
import CryptoExporter
import XCTest

struct BlockIterator: IteratorProtocol {
    let payload: Data
    let maxBlockSize: Int

    func next() -> Data? {
        if payload.count > maxBlockSize {
            return payload.subdata(in: 0 ..< maxBlockSize)
        } else {
            return payload
        }
    }
}

struct BlockExporter: Sequence {
    /// The data payload to export
    let payload: Data
    let maxBlockSize: Int

    func makeIterator() -> some IteratorProtocol<Data> {
        BlockIterator(payload: payload, maxBlockSize: maxBlockSize)
    }
}

final class BlockExporterTests: XCTestCase {
    func test_iterate_iteratesOverDataUnderBlockSizeLimit() {
        let payload = anyData(bytes: 4)
        let sut = BlockExporter(payload: payload, maxBlockSize: 8)
        var iter = sut.makeIterator()

        XCTAssertEqual(iter.next(), payload)
    }

    func test_iterate_returnsDataAtPacketSizeLimit() {
        let payload = anyData(bytes: 8)
        let sut = BlockExporter(payload: payload, maxBlockSize: 8)
        var iter = sut.makeIterator()

        XCTAssertEqual(iter.next(), payload)
    }

    func test_iterate_truncatesDataOverLimit() {
        let payload = anyData(bytes: 16)
        let sut = BlockExporter(payload: payload, maxBlockSize: 8)
        var iter = sut.makeIterator()

        XCTAssertEqual(iter.next(), payload[0 ..< 8])
    }

    // MARK: - Helpers

    private func anyData(bytes: Int = 8) -> Data {
        Data(repeating: 0xFF, count: bytes)
    }
}
