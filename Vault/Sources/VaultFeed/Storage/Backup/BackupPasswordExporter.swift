import CryptoDocumentExporter
import Foundation

public final class BackupPasswordExporter {
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }

    public struct NoPasswordError: Error {}

    public func makeExport() throws -> Data {
        guard let password = try store.fetchPassword() else {
            throw NoPasswordError()
        }
        let backupExport = BackupPasswordExport.createV1Export(
            key: password.key,
            salt: password.salt
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
