import CryptoEngine
import Foundation
import Testing

struct BlockExporterTests {
    @Test
    func noHeader_returnsNoBlocksForNoData() {
        var sut = BlockExporter(payload: Data(), maxBlockSize: 8)

        #expect(sut.allElements().isEmpty)
    }

    @Test(arguments: [1, 4, 7])
    func noHeader_returnsSingleBlockUnderSizeLimit(size: Int) {
        let payload = anyData(bytes: size)
        var sut = BlockExporter(payload: payload, maxBlockSize: 8)

        #expect(sut.allElements() == [payload])
    }

    @Test(arguments: [1, 8, 100])
    func noHeader_returnsSingleMatchingBlockSizeLimit(size: Int) {
        let payload = anyData(bytes: size)
        var sut = BlockExporter(payload: payload, maxBlockSize: size)

        #expect(sut.allElements() == [payload])
    }

    @Test(arguments: [8, 16])
    func noHeader_returnsMultipleBlocksDivisibleByMaxBlockSize(chunkSize: Int) {
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize)
        let payload = block1 + block2 + block3
        var sut = BlockExporter(payload: payload, maxBlockSize: chunkSize)

        #expect(sut.allElements() == [block1, block2, block3])
    }

    @Test(arguments: [8, 16])
    func noHeader_returnsMultipleBlocksWithPartialLastBlock(chunkSize: Int) {
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: chunkSize / 2)
        let payload = block1 + block2 + block3
        var sut = BlockExporter(payload: payload, maxBlockSize: chunkSize)

        #expect(sut.allElements() == [block1, block2, block3])
    }

    @Test(arguments: [8, 16])
    func noHeader_returnsMultipleBlocksWithOneByteLastBlock(chunkSize: Int) {
        let block1 = repeatingData(byte: 0xFF, bytes: chunkSize)
        let block2 = repeatingData(byte: 0xEE, bytes: chunkSize)
        let block3 = repeatingData(byte: 0xDD, bytes: 1)
        let payload = block1 + block2 + block3
        var sut = BlockExporter(payload: payload, maxBlockSize: chunkSize)

        #expect(sut.allElements() == [block1, block2, block3])
    }

    @Test
    func blockHeader_providesAccumulatingBlockNumbersInBlockHeader() {
        let payload = anyData(bytes: 50)
        var accumulatedNumbers = [Int]()
        var sut = BlockExporter(
            payload: payload,
            maxBlockSize: 10,
            blockHeader: { context in
                accumulatedNumbers.append(context.blockNumber)
                return Data()
            },
        )
        _ = sut.allElements()

        #expect(accumulatedNumbers == [0, 1, 2, 3, 4, 5], "Last header closure is called, but not used in output.")
    }

    @Test
    func header_throwsIfHeaderEqualToBlockSize() {
        let header = anyData(bytes: 50)
        var sut = BlockExporter(
            payload: anyData(),
            maxBlockSize: 50,
            blockHeader: { _ in header },
        )

        #expect(throws: (any Error).self) {
            try sut.next()
        }
    }

    @Test
    func header_throwsIfHeaderLargerThanBlockSize() {
        let header = anyData(bytes: 50)
        var sut = BlockExporter(
            payload: anyData(),
            maxBlockSize: 10,
            blockHeader: { _ in header },
        )

        #expect(throws: (any Error).self) {
            try sut.next()
        }
    }

    @Test
    func header_returnsSingleBlockWhereBlockSizePerfectlyMatchesDataSize() {
        let header = Data(hex: "01020304")
        let payload = Data(hex: "FFEEDDCC")
        var sut = BlockExporter(
            payload: payload,
            maxBlockSize: header.count + payload.count,
            blockHeader: { _ in header },
        )

        #expect(sut.allElements() == [header + payload])
    }

    @Test
    func header_blockSplittingDueToHeaderSizeIntoBlockDivisibleBySize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEEEEEEEEDDDDDDDD")
        var sut = BlockExporter(
            payload: block,
            maxBlockSize: header.count + 4,
            blockHeader: { _ in header },
        )

        #expect(sut.allElements() == [
            header + Data(hex: "FFFFFFFF"),
            header + Data(hex: "EEEEEEEE"),
            header + Data(hex: "DDDDDDDD"),
        ])
    }

    @Test
    func header_blockSplittingDueToHeaderSizeIntoNonDivisibleBlockSize() {
        let header = Data(hex: "01020304")
        let block = Data(hex: "FFFFFFFFEE")
        var sut = BlockExporter(
            payload: block,
            maxBlockSize: header.count + 4,
            blockHeader: { _ in header },
        )

        #expect(sut.allElements() == [
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

extension BlockExporter {
    fileprivate mutating func allElements() -> [Data] {
        var acc = [Data]()
        while let next = try? next() {
            acc.append(next)
        }
        return acc
    }
}
