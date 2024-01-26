import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class DataShardBuilderTests: XCTestCase {
    func test_makeShards_makesOneChunkForEmptyData() {
        let id = UUID()
        let sut = DataShardBuilder(groupIDGenerator: { id })

        let shards = sut.makeShards(from: Data())

        let expected = DataShard(group: .init(id: id, number: 0, totalNumber: 1), data: Data())
        XCTAssertEqual(shards, [expected])
    }

    func test_makeShards_makesOneChunk() {
        let inputData = Array(repeating: UInt8(33), count: 356)
        let id = UUID()
        let sut = DataShardBuilder(groupIDGenerator: { id })

        let shards = sut.makeShards(from: Data(inputData))

        let expected = DataShard(group: .init(id: id, number: 0, totalNumber: 1), data: Data(inputData))
        XCTAssertEqual(shards, [expected])
    }

    func test_makeShards_maxChunkSizeIs1500Bytes() {
        let inputData = Array(repeating: UInt8(33), count: 4000)
        let sut = DataShardBuilder()

        let shards = sut.makeShards(from: Data(inputData))

        XCTAssertEqual(shards.count, 3)
        XCTAssertEqual(shards.map(\.data.count), [1500, 1500, 1000])
        XCTAssertEqual(shards.map(\.group.totalNumber), [3, 3, 3])
        XCTAssertEqual(shards.map(\.group.number), [0, 1, 2])
    }

    func test_makeShards_doesNotMakeExtraShardsIfDividesExactly() {
        let inputData = Array(repeating: UInt8(33), count: 4500)
        let sut = DataShardBuilder()

        let shards = sut.makeShards(from: Data(inputData))

        XCTAssertEqual(shards.count, 3)
        XCTAssertEqual(shards.map(\.data.count), [1500, 1500, 1500])
        XCTAssertEqual(shards.map(\.group.totalNumber), [3, 3, 3])
        XCTAssertEqual(shards.map(\.group.number), [0, 1, 2])
    }
}
