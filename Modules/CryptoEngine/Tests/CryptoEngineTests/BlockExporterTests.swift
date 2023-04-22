import CryptoEngine
import XCTest

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
