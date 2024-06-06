import CryptoDocumentExporter
import Foundation
import ImageTools

struct DataShardPNGEncoder {
    private let dataShardBuilder: DataShardBuilder

    init(dataShardBuilder: DataShardBuilder) {
        self.dataShardBuilder = dataShardBuilder
    }

    /// An error occured encoding some data into a QR code.
    struct ImageEncodingError: Error {}

    func makeQRCodePNGs(fromData data: Data) throws -> [Data] {
        let shards = dataShardBuilder.makeShards(from: data)
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
