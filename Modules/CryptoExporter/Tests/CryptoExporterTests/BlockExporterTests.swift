import CryptoEngine
import CryptoExporter
import XCTest

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

struct BlockExporter {
    let config: Configuration
    /// The current number of block we are iterating on.
    var blockNumber = 0
    /// The current number of accumulated bytes the header has caused an offset of.
    var offsetHeaderBytes = 0

    struct HeaderTooLargeError: Error {
        let maxSize: Int
        let actualSize: Int
    }

    mutating func next() throws -> Data? {
        defer { blockNumber += 1 }

        let header = try makeHeader()
        let nextHeaderSize = header.count

        defer { offsetHeaderBytes += nextHeaderSize }

        let start = min(blockSize * blockNumber - offsetHeaderBytes, payload.count)
        let end = min(start + blockSize - nextHeaderSize, payload.count)
        let blockRange = start ..< end

        guard blockRange.isNotEmpty else { return nil }

        return header + payload.subdata(in: blockRange)
    }

    private func makeHeader() throws -> Data {
        let context = BlockContext(blockNumber: blockNumber)
        let header = config.blockHeader?(context) ?? Data()
        guard header.count < blockSize else {
            throw HeaderTooLargeError(maxSize: blockSize, actualSize: header.count)
        }
        return header
    }

    private var blockSize: Int {
        config.maxBlockSize
    }

    private var payload: Data {
        config.payload
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
    func test_noHeader_returnsSingleBlockUnderSizeLimit() {
        let payload = anyData(bytes: 4)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        var sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [payload])
    }

    func test_noHeader_returnsSingleMatchingBlockSizeLimit() {
        let payload = anyData(bytes: 8)
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: 8)
        var sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [payload])
    }

    func test_noHeader_returnsMultipleBlocksDivisibleByMaxBlockSize() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        var sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_noHeader_returnsMultipleBlocksWithPartialLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize / 2)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        var sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_noHeader_returnsMultipleBlocksWithOneByteLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: 1)
        let payload = block1 + block2 + block3
        let config = BlockExporter.Configuration(payload: payload, maxBlockSize: chunkSize)
        var sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_blockHeader_providesAccumulatingBlockNumbersInBlockHeader() {
        let payload = anyData(bytes: 50)
        var accumulatedNumbers = [Int]()
        let config = BlockExporter.Configuration(
            payload: payload,
            maxBlockSize: 10,
            blockHeader: { context in
                accumulatedNumbers.append(context.blockNumber)
                return Data()
            }
        )
        var sut = BlockExporter(config: config)
        _ = sut.allElements()

        XCTAssertEqual(accumulatedNumbers, [0, 1, 2, 3, 4, 5], "Last header closure is called, but not used in output.")
    }

    func test_header_throwsIfHeaderEqualToBlockSize() {
        let header = anyData(bytes: 50)
        let config = BlockExporter.Configuration(
            payload: anyData(),
            maxBlockSize: 50,
            blockHeader: { _ in header }
        )
        var sut = BlockExporter(config: config)

        XCTAssertThrowsError(try sut.next())
    }

    func test_header_throwsIfHeaderLargerThanBlockSize() {
        let header = anyData(bytes: 50)
        let config = BlockExporter.Configuration(
            payload: anyData(),
            maxBlockSize: 10,
            blockHeader: { _ in header }
        )
        var sut = BlockExporter(config: config)

        XCTAssertThrowsError(try sut.next())
    }

    func test_header_returnsSingleBlockWhereBlockSizePerfectlyMatchesDataSize() {
        let header = Data(hex: "01020304")
        let payload = Data(hex: "FFEEDDCC")
        let config = BlockExporter.Configuration(
            payload: payload,
            maxBlockSize: header.count + payload.count,
            blockHeader: { _ in header }
        )
        var sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [header + payload])
    }

    func test_header_blockSplittingDueToHeaderSizeIntoBlockDivisibleBySize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEEEEEEEEDDDDDDDD")
        let config = BlockExporter.Configuration(
            payload: block,
            maxBlockSize: header.count + 4,
            blockHeader: { _ in header }
        )
        var sut = BlockExporter(config: config)

        XCTAssertEqual(sut.allElements(), [
            header + Data(hex: "FFFFFFFF"),
            header + Data(hex: "EEEEEEEE"),
            header + Data(hex: "DDDDDDDD"),
        ])
    }

    func test_header_blockSplittingDueToHeaderSizeIntoNonDivisibleBlockSize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEE")
        let config = BlockExporter.Configuration(
            payload: block,
            maxBlockSize: header.count + 4,
            blockHeader: { _ in header }
        )
        var sut = BlockExporter(config: config)

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

private extension BlockExporter {
    mutating func allElements() -> [Data] {
        var acc = [Data]()
        while let next = try? next() {
            acc.append(next)
        }
        return acc
    }
}
