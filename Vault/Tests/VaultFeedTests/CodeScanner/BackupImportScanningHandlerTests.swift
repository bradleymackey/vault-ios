import Foundation
import Testing
import VaultBackup
@testable import VaultFeed

struct BackupImportScanningHandlerTests {
    let sut = BackupImportScanningHandler()

    @Test(arguments: ["", "invalid", "{}"])
    func decode_invalidDataReportsInvalidCode(string: String) {
        let result = sut.decode(data: string)
        #expect(result == .continueScanning(.invalidCode))
    }

    @Test(arguments: ["", "invalid", "{}"])
    func decode_addShardErrorIgnoresError(string _: String) throws {
        let result1 = sut.decode(data: """
        {
            "G":{"ID":10,"N":4,"I":0},
            "D": "AA=="
        }
        """)
        try #require(result1 == .continueScanning(.success))

        let result2 = sut.decode(data: """
        {
            "G":{"ID":11,"N":4,"I":0},
            "D": "AA=="
        }
        """)
        #expect(result2 == .continueScanning(.ignore), "Different group number is an ignorable error")
    }

    @Test(arguments: [0, 1, 2, 3])
    func decode_partialShardContinuesScanning(shardNumber: Int) throws {
        let result = sut.decode(data: """
        {
            "G":{"ID":10,"N":4,"I":\(shardNumber)},
            "D": "AA=="
        }
        """)
        #expect(result == .continueScanning(.success))
    }

    @Test
    func decode_fullShardSequenceCompletes() throws {
        let expectedVault = EncryptedVault(
            data: Data(repeating: 0x34, count: 1000),
            authentication: Data(),
            encryptionIV: Data(repeating: 0x46, count: 500),
            keygenSalt: Data(repeating: 0x21, count: 100),
            keygenSignature: "34"
        )
        let expectedVaultData = try EncryptedVaultCoder().encode(vault: expectedVault)
        let builder = DataShardBuilder()
        let shards = builder.makeShards(from: expectedVaultData)
        let encodedShards = try shards.map {
            try EncryptedVaultCoder().encode(shard: $0)
        }

        // Intermediate shards should continue scanning.
        for encodedShard in encodedShards[0 ..< encodedShards.count - 1] {
            let result = sut.decode(data: String(decoding: encodedShard, as: UTF8.self))
            try #require(result == .continueScanning(.success))
        }

        // The last shard triggers the completion.
        let lastShard = try #require(encodedShards.last)
        let result = sut.decode(data: String(decoding: lastShard, as: UTF8.self))
        #expect(result == .endScanning(.dataRetrieved(expectedVault)))
    }

    @Test
    func test_decodeInvalidFullDataEndsWithUnrecoverableError() throws {
        let result1 = sut.decode(data: """
        {
            "G":{"ID":10,"N":2,"I":0},
            "D": "AA=="
        }
        """)
        try #require(result1 == .continueScanning(.success))

        let result2 = sut.decode(data: """
        {
            "G":{"ID":10,"N":2,"I":1},
            "D": "AA=="
        }
        """)
        #expect(result2 == .endScanning(.unrecoverableError), "Because AA== twice is not a valid vault.")
    }
}
