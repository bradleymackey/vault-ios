import CryptoEngine
import CryptoExporter
import XCTest

struct BlockIterator: IteratorProtocol {
    let config: Configuration

    func next() -> Data? {
        if config.payload.count > config.maxBlockSize {
            return config.payload.subdata(in: 0 ..< config.maxBlockSize)
        } else {
            return config.payload
        }
    }
}

extension BlockIterator {
    struct Configuration {
        let payload: Data
        let maxBlockSize: Int
    }
}

struct BlockExporter: Sequence {
    typealias Configuration = BlockIterator.Configuration
    let config: Configuration

    func makeIterator() -> some IteratorProtocol<Data> {
        BlockIterator(config: config)
    }
}

final class BlockExporterTests: XCTestCase {
    func test_blocks_iteratesOverDataUnderBlockSizeLimit() {
        let payload = anyData(bytes: 4)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        let sut = BlockExporter(config: config)
        var iter = sut.makeIterator()

        XCTAssertEqual(iter.next(), payload)
    }

    func test_blocks_returnsDataAtPacketSizeLimit() {
        let payload = anyData(bytes: 8)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        let sut = BlockExporter(config: config)
        var iter = sut.makeIterator()

        XCTAssertEqual(iter.next(), payload)
    }

    func test_blocks_truncatesDataOverLimit() {
        let payload = anyData(bytes: 16)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        let sut = BlockExporter(config: config)
        var iter = sut.makeIterator()

        XCTAssertEqual(iter.next(), payload[0 ..< 8])
    }

    // MARK: - Helpers

    private func anyData(bytes: Int = 8) -> Data {
        Data(repeating: 0xFF, count: bytes)
    }
}
