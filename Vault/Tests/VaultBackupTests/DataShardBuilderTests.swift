import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class DataShardBuilderTests: XCTestCase {
    func test_makeShards_makesOneChunkForEmptyData() {
        let id: UInt16 = 123
        let sut = DataShardBuilder(groupIDGenerator: { id })

        let shards = sut.makeShards(from: Data())

        let expected = DataShard(group: .init(id: id, number: 0, totalNumber: 1), data: Data())
        XCTAssertEqual(shards, [expected])
    }

    func test_makeShards_makesOneChunk() {
        let inputData = Array(repeating: UInt8(33), count: 356)
        let id: UInt16 = 123
        let sut = DataShardBuilder(groupIDGenerator: { id })

        let shards = sut.makeShards(from: Data(inputData))

        let expected = DataShard(group: .init(id: id, number: 0, totalNumber: 1), data: Data(inputData))
        XCTAssertEqual(shards, [expected])
    }

    func test_makeShards_maxChunkSizeIs400Bytes() {
        let inputData = Array(repeating: UInt8(33), count: 4000)
        let sut = DataShardBuilder()

        let shards = sut.makeShards(from: Data(inputData))

        XCTAssertEqual(shards.count, 10)
        XCTAssertEqual(shards.map(\.data.count), Array(repeating: 400, count: 10))
        XCTAssertEqual(shards.map(\.group.totalNumber), Array(repeating: 10, count: 10))
        XCTAssertEqual(shards.map(\.group.number), Array(0 ... 9))
    }

    func test_makeShards_doesNotMakeExtraShardsIfDividesExactly() {
        let inputData = Array(repeating: UInt8(33), count: 4500)
        let sut = DataShardBuilder()

        let shards = sut.makeShards(from: Data(inputData))

        XCTAssertEqual(shards.count, 12)
        XCTAssertEqual(shards.map(\.data.count), Array(repeating: 400, count: 11) + [100])
        XCTAssertEqual(shards.map(\.group.totalNumber), Array(repeating: 12, count: 12))
        XCTAssertEqual(shards.map(\.group.number), Array(0 ... 11))
    }
}
