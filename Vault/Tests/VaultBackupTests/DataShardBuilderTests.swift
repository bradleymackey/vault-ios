import Foundation
import TestHelpers
import Testing
@testable import VaultBackup

struct DataShardBuilderTests {
    @Test
    func makeShards_makesOneChunkForEmptyData() {
        let id: UInt16 = 123
        let sut = DataShardBuilder(groupIDGenerator: { id })

        let shards = sut.makeShards(from: Data())

        let expected = DataShard(group: .init(id: id, number: 0, totalNumber: 1), data: Data())
        #expect(shards == [expected])
    }

    @Test
    func makeShards_makesOneChunk() {
        let inputData = Array(repeating: UInt8(33), count: 356)
        let id: UInt16 = 123
        let sut = DataShardBuilder(groupIDGenerator: { id })

        let shards = sut.makeShards(from: Data(inputData))

        let expected = DataShard(group: .init(id: id, number: 0, totalNumber: 1), data: Data(inputData))
        #expect(shards == [expected])
    }

    @Test
    func makeShards_maxChunkSizeIs500Bytes() {
        let inputData = Array(repeating: UInt8(33), count: 4000)
        let sut = DataShardBuilder()

        let shards = sut.makeShards(from: Data(inputData))

        #expect(shards.count == 8)
        #expect(shards.map(\.data.count) == Array(repeating: 500, count: 8))
        #expect(shards.map(\.group.totalNumber) == Array(repeating: 8, count: 8))
        #expect(shards.map(\.group.number) == Array(0 ... 7))
    }

    @Test
    func makeShards_doesNotMakeExtraShardsIfDividesExactly() {
        let inputData = Array(repeating: UInt8(33), count: 4600)
        let sut = DataShardBuilder()

        let shards = sut.makeShards(from: Data(inputData))

        #expect(shards.count == 10)
        #expect(shards.map(\.data.count) == Array(repeating: 500, count: 9) + [100])
        #expect(shards.map(\.group.totalNumber) == Array(repeating: 10, count: 10))
        #expect(shards.map(\.group.number) == Array(0 ... 9))
    }
}
