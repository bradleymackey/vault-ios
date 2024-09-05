import CryptoDocumentExporter
import Foundation

public actor BackupPasswordExporter {
    private let backupPassword: DerivedEncryptionKey

    public init(backupPassword: DerivedEncryptionKey) {
        self.backupPassword = backupPassword
    }

    public func makeExport() throws -> Data {
        let backupExport = BackupPasswordExport.createV1Export(
            key: backupPassword.key,
            salt: backupPassword.salt,
            keyDeriver: backupPassword.keyDervier
        )
        return try makeExportEncoder().encode(backupExport)
    }

    private func makeExportEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.dataEncodingStrategy = .base64
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
