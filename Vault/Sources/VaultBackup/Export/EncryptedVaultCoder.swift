import Foundation

struct EncryptedVaultCoder {
    func encode(vault: EncryptedVault) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.dataEncodingStrategy = .base64
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(vault)
    }

    func decode(vaultData: Data) throws -> EncryptedVault {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        return try decoder.decode(EncryptedVault.self, from: vaultData)
    }

    func encode(shard: DataShard) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.dataEncodingStrategy = .base64
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(shard)
    }

    func decode(dataShard: Data) throws -> DataShard {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        return try decoder.decode(DataShard.self, from: dataShard)
    }
}
