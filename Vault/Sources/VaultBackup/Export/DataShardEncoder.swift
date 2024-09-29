import Foundation
import ImageTools
import VaultExport

struct DataShardEncoder {
    private let dataShardBuilder: DataShardBuilder

    init(dataShardBuilder: DataShardBuilder) {
        self.dataShardBuilder = dataShardBuilder
    }

    /// An error occured encoding some data into a QR code.
    struct ImageEncodingError: Error {}

    func makeEncodedShards(fromData data: Data) throws -> [Data] {
        let shards = dataShardBuilder.makeShards(from: data)
        let vaultCoder = EncryptedVaultCoder()
        return try shards.map { shard in
            try vaultCoder.encode(shard: shard)
        }
    }
}
