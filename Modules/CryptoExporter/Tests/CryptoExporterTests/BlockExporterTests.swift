import CryptoEngine
import CryptoExporter
import XCTest

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

struct BlockIterator: IteratorProtocol {
    typealias Configuration = BlockExporter.Configuration

    let config: Configuration
    var blockNumber = 0

    mutating func next() -> Data? {
        defer { blockNumber += 1 }

        let start = min(blockSize * blockNumber, payload.count)
        let end = min(start + blockSize, payload.count)
        let blockRange = start ..< end

        guard blockRange.isNotEmpty else { return nil }

        let header = config.blockHeader?(blockNumber) ?? Data()
        return header + payload.subdata(in: blockRange)
    }

    private var blockSize: Int {
        config.maxBlockSize
    }

    private var payload: Data {
        config.payload
    }
}

struct BlockExporter: Sequence {
    let config: Configuration

    func makeIterator() -> some IteratorProtocol<Data> {
        BlockIterator(config: config)
    }
}

extension BlockExporter {
    struct Configuration {
        var payload: Data
        /// Maximum size of the block, not including the header.
        var maxBlockSize: Int
        /// Header included in every block, parameterized by block number, starting at 0.
        var blockHeader: ((Int) -> Data)?
    }
}

final class BlockExporterTests: XCTestCase {
    func test_singleBlock_returnsUnderBlockSizeLimit() {
        let payload = anyData(bytes: 4)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [payload])
    }

    func test_singleBlock_returnsMatchingBlockSizeLimit() {
        let payload = anyData(bytes: 8)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [payload])
    }

    func test_multipleBlocks_returnsDivisibleByBlockSize() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_multipleBlocks_returnsWithPartialLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize / 2)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_multipleBlocks_returnsWithOneByteLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: 1)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_singleBlock_returnsWithHeader() {
        let baseHeader = Data(hex: "DEADBEEF")
        let payload = anyData(bytes: 4)
        let config = BlockExporter.Configuration(
            payload: payload,
            maxBlockSize: 8,
            blockHeader: { blockNumber in byte(int: blockNumber) + baseHeader }
        )
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [byte(int: 0) + baseHeader + payload])
    }

    func test_multipleBlocks_returnsWithHeader() {
        let baseHeader = Data(hex: "DEADBEEF")
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize / 2)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(
            payload: payload,
            maxBlockSize: chunkSize,
            blockHeader: { blockNumber in byte(int: blockNumber) + baseHeader }
        )
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [
            byte(int: 0) + baseHeader + block1,
            byte(int: 1) + baseHeader + block2,
            byte(int: 2) + baseHeader + block3,
        ])
    }
}

// MARK: - Helpers

private func repeatingData(byte: UInt8, bytes: Int) -> Data {
    Data(repeating: byte, count: bytes)
}

private func anyData(bytes: Int = 8) -> Data {
    Data(repeating: 0xFF, count: bytes)
}

private func byte(int: Int) -> Data {
    Data(repeating: UInt8(int), count: 1)
}

private extension Sequence {
    func allElements() -> [Element] {
        map { $0 }
    }
}
