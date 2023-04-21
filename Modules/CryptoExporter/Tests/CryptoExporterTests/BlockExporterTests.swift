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

        return payload.subdata(in: blockRange)
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
        let payload: Data
        let maxBlockSize: Int
    }
}

final class BlockExporterTests: XCTestCase {
    func test_blocks_returnsSingleBlockUnderBlockSizeLimit() {
        let payload = anyData(bytes: 4)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        let sut = BlockExporter(config: config)

        let allBlocks = sut.map { $0 }
        XCTAssertEqual(allBlocks, [payload])
    }

    func test_blocks_returnsSingleBlockMatchingBlockSizeLimit() {
        let payload = anyData(bytes: 8)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        let sut = BlockExporter(config: config)

        let allBlocks = sut.map { $0 }
        XCTAssertEqual(allBlocks, [payload])
    }

    func test_blocks_returnsMultipleBlocksOverBlockSizeLimit() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        let sut = BlockExporter(config: config)

        let allBlocks = sut.map { $0 }
        XCTAssertEqual(allBlocks, [block1, block2, block3])
    }

    func test_blocks_returnsMultipleBlocksOverBlockSizeLimitWithPartialLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize / 2)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        let sut = BlockExporter(config: config)

        let allBlocks = sut.map { $0 }
        XCTAssertEqual(allBlocks, [block1, block2, block3])
    }

    func test_blocks_returnsMultipleBlocksOverBlockSizeLimitWithOneByteLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: 1)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        let sut = BlockExporter(config: config)

        let allBlocks = sut.map { $0 }
        XCTAssertEqual(allBlocks, [block1, block2, block3])
    }

    // MARK: - Helpers

    private func repeatingData(byte: UInt8, bytes: Int) -> Data {
        Data(repeating: byte, count: bytes)
    }

    private func anyData(bytes: Int = 8) -> Data {
        Data(repeating: 0xFF, count: bytes)
    }
}
