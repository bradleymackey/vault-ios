import Foundation
import Testing
@testable import VaultBackup

struct DataShardDecoderTests {
    var sut = DataShardDecoder()

    @Test
    mutating func addShardData_emptyShardData() throws {
        let shard = try makeShardData(group: .init(id: 10, number: 4, totalNumber: 6), data: Data())
        #expect(throws: Never.self) {
            try sut.add(shardData: shard)
        }

        #expect(sut.state?.groupID == 10)
        #expect(sut.isReadyToDecode == false)
        #expect(sut.state?.total == 6)
        #expect(sut.state?.remaining == 5)
    }

    @Test(arguments: [0, 1, 2, 3, 4, 5])
    mutating func addShardData_decodesShardIntoState(number: Int) throws {
        let shard = try makeShardData(group: .init(id: 10, number: number, totalNumber: 6))
        try sut.add(shardData: shard)

        #expect(sut.state?.groupID == 10)
        #expect(sut.isReadyToDecode == false)
        #expect(sut.state?.total == 6)
        #expect(sut.state?.remaining == 5)
    }

    @Test
    mutating func addShardData_multipleShardsUpdateState() throws {
        for i in 0 ..< 5 {
            let shard = try makeShardData(group: .init(id: 10, number: i, totalNumber: 6))
            try sut.add(shardData: shard)
        }

        #expect(sut.state?.groupID == 10)
        #expect(sut.isReadyToDecode == false)
        #expect(sut.state?.total == 6)
        #expect(sut.state?.remaining == 1)
    }

    @Test
    mutating func addShardData_readyToDecodeAfterAllShards() throws {
        for i in 0 ..< 6 {
            let shard = try makeShardData(group: .init(id: 10, number: i, totalNumber: 6))
            try sut.add(shardData: shard)
        }

        #expect(sut.state?.groupID == 10)
        #expect(sut.isReadyToDecode == true)
        #expect(sut.state?.total == 6)
        #expect(sut.state?.remaining == 0)
    }

    @Test
    mutating func addShardData_throwsIfShardAlreadyExists() throws {
        let shard = try makeShardData(group: .init(id: 10, number: 4, totalNumber: 6))
        try sut.add(shardData: shard)

        #expect(throws: DataShardDecoder.AddShardError.shardAlreadyExists) {
            try sut.add(shardData: shard)
        }
    }

    @Test(arguments: [0, 99, 1000])
    mutating func addShardData_throwsIfShardGroupIDChanges(newGroupID: UInt16) throws {
        let shard1 = try makeShardData(group: .init(id: 10, number: 4, totalNumber: 6))
        try sut.add(shardData: shard1)

        #expect(throws: DataShardDecoder.AddShardError.inconsistentGroup) {
            let shard2 = try makeShardData(group: .init(id: newGroupID, number: 4, totalNumber: 6))
            try sut.add(shardData: shard2)
        }
    }

    @Test
    func decodeData_noInitialStateThrowsError() {
        #expect(throws: DataShardDecoder.DecoderError.missingShards) {
            try sut.decodeData()
        }
    }

    @Test
    mutating func decodeData_notEnoughShardsThrowsError() throws {
        for i in 0 ..< 5 {
            let shard = try makeShardData(group: .init(id: 10, number: i, totalNumber: 6))
            try sut.add(shardData: shard)
        }

        #expect(throws: DataShardDecoder.DecoderError.missingShards) {
            try sut.decodeData()
        }
    }

    @Test
    mutating func decodeData_concatsAllData() throws {
        for i in 0 ..< 6 {
            let shard = try makeShardData(
                group: .init(id: 10, number: i, totalNumber: 6),
                data: Data([UInt8(i + 20)])
            )
            try sut.add(shardData: shard)
        }

        let decoded = try sut.decodeData()
        #expect(decoded == Data([20, 21, 22, 23, 24, 25]))
    }

    @Test(arguments: [[4, 5, 1, 3, 2, 0], [5, 1, 4, 0, 2, 3]])
    mutating func decodeData_concatsAllDataOutOfOrderAdd(order: [Int]) throws {
        for i in order {
            let shard = try makeShardData(
                group: .init(id: 10, number: i, totalNumber: 6),
                data: Data([UInt8(i + 30)])
            )
            try sut.add(shardData: shard)
        }

        let decoded = try sut.decodeData()
        #expect(decoded == Data([30, 31, 32, 33, 34, 35]))
    }
}

extension DataShardDecoderTests {
    private func makeShardData(
        group: DataShard.GroupInfo = .init(id: 0, number: 0, totalNumber: 1),
        data: Data = Data([0xAA])
    ) throws -> Data {
        try EncryptedVaultCoder().encode(shard: .init(group: group, data: data))
    }
}
