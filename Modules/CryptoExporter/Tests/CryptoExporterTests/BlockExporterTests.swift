import CryptoEngine
import CryptoExporter
import XCTest

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

struct BlockExporter {
    let payload: Data
    /// Maximum size of the block, **including** the header.
    let maxBlockSize: Int
    /// Header included in every block, given the current block context.
    let blockHeader: ((BlockContext) -> Data)?
    /// The current number of block we are iterating on.
    private var blockNumber = 0
    /// The current number of accumulated bytes the header has caused an offset of.
    private var offsetHeaderBytes = 0

    init(payload: Data, maxBlockSize: Int, blockHeader: ((BlockContext) -> Data)? = nil) {
        self.payload = payload
        self.maxBlockSize = maxBlockSize
        self.blockHeader = blockHeader
    }

    struct HeaderTooLargeError: Error {
        let maxSize: Int
        let actualSize: Int
    }

    mutating func next() throws -> Data? {
        defer { blockNumber += 1 }

        let header = try makeHeader()
        let nextHeaderSize = header.count

        defer { offsetHeaderBytes += nextHeaderSize }

        let start = min(maxBlockSize * blockNumber - offsetHeaderBytes, payload.count)
        let end = min(start + maxBlockSize - nextHeaderSize, payload.count)
        let blockRange = start ..< end

        guard blockRange.isNotEmpty else { return nil }

        return header + payload.subdata(in: blockRange)
    }

    private func makeHeader() throws -> Data {
        let context = BlockContext(blockNumber: blockNumber)
        let header = blockHeader?(context) ?? Data()
        guard header.count < maxBlockSize else {
            throw HeaderTooLargeError(maxSize: maxBlockSize, actualSize: header.count)
        }
        return header
    }
}

extension BlockExporter {
    struct BlockContext {
        /// The number block that this will become, starting from 0.
        var blockNumber: Int
    }
}

final class BlockExporterTests: XCTestCase {
    func test_noHeader_returnsSingleBlockUnderSizeLimit() {
        let payload = anyData(bytes: 4)
        var sut = BlockExporter(payload: payload, maxBlockSize: 8)

        XCTAssertEqual(sut.allElements(), [payload])
    }

    func test_noHeader_returnsSingleMatchingBlockSizeLimit() {
        let payload = anyData(bytes: 8)
        var sut = BlockExporter(payload: payload, maxBlockSize: 8)

        XCTAssertEqual(sut.allElements(), [payload])
    }

    func test_noHeader_returnsMultipleBlocksDivisibleByMaxBlockSize() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize)
        let payload = block1 + block2 + block3
        var sut = BlockExporter(payload: payload, maxBlockSize: chunkSize)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_noHeader_returnsMultipleBlocksWithPartialLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize / 2)
        let payload = block1 + block2 + block3
        var sut = BlockExporter(payload: payload, maxBlockSize: chunkSize)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_noHeader_returnsMultipleBlocksWithOneByteLastBlock() {
        let chunkSize = 8
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: 1)
        let payload = block1 + block2 + block3
        var sut = BlockExporter(payload: payload, maxBlockSize: chunkSize)

        XCTAssertEqual(sut.allElements(), [block1, block2, block3])
    }

    func test_blockHeader_providesAccumulatingBlockNumbersInBlockHeader() {
        let payload = anyData(bytes: 50)
        var accumulatedNumbers = [Int]()
        var sut = BlockExporter(
            payload: payload,
            maxBlockSize: 10,
            blockHeader: { context in
                accumulatedNumbers.append(context.blockNumber)
                return Data()
            }
        )
        _ = sut.allElements()

        XCTAssertEqual(accumulatedNumbers, [0, 1, 2, 3, 4, 5], "Last header closure is called, but not used in output.")
    }

    func test_header_throwsIfHeaderEqualToBlockSize() {
        let header = anyData(bytes: 50)
        var sut = BlockExporter(
            payload: anyData(),
            maxBlockSize: 50,
            blockHeader: { _ in header }
        )

        XCTAssertThrowsError(try sut.next())
    }

    func test_header_throwsIfHeaderLargerThanBlockSize() {
        let header = anyData(bytes: 50)
        var sut = BlockExporter(
            payload: anyData(),
            maxBlockSize: 10,
            blockHeader: { _ in header }
        )

        XCTAssertThrowsError(try sut.next())
    }

    func test_header_returnsSingleBlockWhereBlockSizePerfectlyMatchesDataSize() {
        let header = Data(hex: "01020304")
        let payload = Data(hex: "FFEEDDCC")
        var sut = BlockExporter(
            payload: payload,
            maxBlockSize: header.count + payload.count,
            blockHeader: { _ in header }
        )

        XCTAssertEqual(sut.allElements(), [header + payload])
    }

    func test_header_blockSplittingDueToHeaderSizeIntoBlockDivisibleBySize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEEEEEEEEDDDDDDDD")
        var sut = BlockExporter(
            payload: block,
            maxBlockSize: header.count + 4,
            blockHeader: { _ in header }
        )

        XCTAssertEqual(sut.allElements(), [
            header + Data(hex: "FFFFFFFF"),
            header + Data(hex: "EEEEEEEE"),
            header + Data(hex: "DDDDDDDD"),
        ])
    }

    func test_header_blockSplittingDueToHeaderSizeIntoNonDivisibleBlockSize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEE")
        var sut = BlockExporter(
            payload: block,
            maxBlockSize: header.count + 4,
            blockHeader: { _ in header }
        )

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
