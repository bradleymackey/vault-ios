import CryptoDocumentExporter
import Foundation

struct DataShardPNGEncoder {
    /// An error occured encoding some data into a QR code.
    struct ImageEncodingError: Error {}

    func makeQRCodePNGs(fromData data: Data) throws -> [Data] {
        let shards = DataShardBuilder().makeShards(from: data)
        let generator = QRCodeGenerator()
        let vaultCoder = EncryptedVaultCoder()
        return try shards.map { shard in
            let encodedShared = try vaultCoder.encode(shard: shard)
            if let png = generator.generatePNG(data: encodedShared) {
                return png
            } else {
                throw ImageEncodingError()
            }
        }
    }
}
