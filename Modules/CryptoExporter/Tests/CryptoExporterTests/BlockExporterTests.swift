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
    typealias BlockContext = BlockExporter.BlockContext

    let config: Configuration
    /// The current number of block we are iterating on.
    var blockNumber = 0
    /// The current number of accumulated bytes the header has caused an offset of.
    var offsetHeaderBytes = 0

    mutating func next() -> Data? {
        defer { blockNumber += 1 }

        let context = BlockContext(blockNumber: blockNumber)
        let header = config.blockHeader?(context) ?? Data()
        let nextHeaderSize = header.count

        defer { offsetHeaderBytes += nextHeaderSize }

        let start = min(blockSize * blockNumber - offsetHeaderBytes, payload.count)
        let end = min(start + blockSize - nextHeaderSize, payload.count)
        let blockRange = start ..< end

        guard blockRange.isNotEmpty else { return nil }

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
        /// Maximum size of the block, **including** the header.
        var maxBlockSize: Int
        /// Header included in every block, given the current block context.
        var blockHeader: ((BlockContext) -> Data)?
    }

    struct BlockContext {
        /// The number block that this will become, starting from 0.
        var blockNumber: Int
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

    func test_singleBlock_returnsWithHeaderMatchingBlockSize() {
        let baseHeader = Data(hex: "DEADBEEF") // 4 bytes
        let payload = anyData(bytes: 4)
        let config = BlockExporter.Configuration(
            payload: payload,
            maxBlockSize: baseHeader.count + payload.count + 1, // single extra counter byte in the header
            blockHeader: { context in byte(int: context.blockNumber) + baseHeader }
        )
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [byte(int: 0) + baseHeader + payload])
    }

    func test_multipleBlocks_returnsWithHeaderMatchingBlockSize() {
        let baseHeader = Data(hex: "DEADBEEF")
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize / 2)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(
            payload: payload,
            maxBlockSize: chunkSize + baseHeader.count + 1, // single extra counter byte in the header
            blockHeader: { context in byte(int: context.blockNumber) + baseHeader }
        )
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [
            byte(int: 0) + baseHeader + block1,
            byte(int: 1) + baseHeader + block2,
            byte(int: 2) + baseHeader + block3,
        ])
    }

    func test_multipleBlocks_blockSplittingDueToHeaderSizeIntoBlockDivisibleBySize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEEEEEEEEDDDDDDDD")
        let config = BlockExporter.Configuration(
            payload: block,
            maxBlockSize: 8,
            blockHeader: { _ in header }
        )
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [
            header + Data(hex: "FFFFFFFF"),
            header + Data(hex: "EEEEEEEE"),
            header + Data(hex: "DDDDDDDD"),
        ])
    }

    func test_multipleBlocks_blockSplittingDueToHeaderSizeIntoNonDivisibleBlockSize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEE")
        let config = BlockExporter.Configuration(
            payload: block,
            maxBlockSize: 8,
            blockHeader: { _ in header }
        )
        let sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [
            header + Data(hex: "FFFFFFFF"),
            header + Data(hex: "EE"),
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
