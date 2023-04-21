import CryptoEngine
import CryptoExporter
import XCTest

struct BlockIterator: IteratorProtocol {
    let config: Configuration
    var blockNumber = 0

    mutating func next() -> Data? {
        defer { blockNumber += 1 }

        let start = blockSize * blockNumber
        let end = start + blockSize
        if start > payload.count {
            return nil
        } else if payload.count > end {
            return payload.subdata(in: start ..< end)
        } else {
            let finalRange = start ..< payload.count
            if finalRange.isEmpty { return nil }
            return payload.subdata(in: finalRange)
        }
    }

    private var blockSize: Int {
        config.maxBlockSize
    }

    private var payload: Data {
        config.payload
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

    // MARK: - Helpers

    private func repeatingData(byte: UInt8, bytes: Int) -> Data {
        Data(repeating: byte, count: bytes)
    }

    private func anyData(bytes: Int = 8) -> Data {
        Data(repeating: 0xFF, count: bytes)
    }
}
