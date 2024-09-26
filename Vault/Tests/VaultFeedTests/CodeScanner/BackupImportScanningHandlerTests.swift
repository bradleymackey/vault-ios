import Foundation
import Testing
import VaultBackup
@testable import VaultFeed

struct BackupImportScanningHandlerTests {
    let sut = BackupImportScanningHandler()

    @Test
    func decode_emptyStringThrowsError() {
        #expect(throws: (any Error).self) {
            try sut.decode(data: "")
        }
    }

    @Test(arguments: ["", "invalid", "{}"])
    func decode_invalidDataThrowsError(string: String) {
        #expect(throws: (any Error).self) {
            try sut.decode(data: string)
        }
    }

    @Test
    func decode_partialShardContinuesScanning() throws {
        let result = try sut.decode(data: """
        {
            "G":{"ID":10,"N":4,"I":0},
            "D": "AA=="
        }
        """)

        #expect(result == .continueScanning)
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
            let result = try sut.decode(data: String(decoding: encodedShard, as: UTF8.self))
            #expect(result == .continueScanning)
        }

        // The last shard triggers the completion.
        let lastShard = try #require(encodedShards.last)
        let result = try sut.decode(data: String(decoding: lastShard, as: UTF8.self))
        #expect(result == .completedScanning(expectedVault))
    }
}
