import Foundation
import VaultKeygen

/// Decodes `Data` or a `String` from a QR code into a `DerivedEncryptionKey`.
public final class BackupPasswordDecoder {
    public init() {}
    public enum ImportError: Error {
        case incompatibleVersion
        case badStringEncoding
    }

    public func decode(qrCode: String) throws -> DerivedEncryptionKey {
        guard let data = qrCode.data(using: .utf8) else { throw ImportError.badStringEncoding }
        return try decode(data: data)
    }

    public func decode(data: Data) throws -> DerivedEncryptionKey {
        let export = try makeImportDecoder().decode(BackupPasswordExport.self, from: data)
        guard export.version.isCompatible(with: "1.0.0") else {
            throw ImportError.incompatibleVersion
        }
        return DerivedEncryptionKey(key: export.key, salt: export.salt, keyDervier: export.keyDeriver)
    }

    private func makeImportDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        return decoder
    }
}
