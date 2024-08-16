import CryptoDocumentExporter
import Foundation

public actor BackupPasswordExporter {
    private let dataModel: VaultDataModel

    public init(dataModel: VaultDataModel) {
        self.dataModel = dataModel
    }

    public struct NoPasswordError: Error {}

    public func makeExport() async throws -> Data {
        await dataModel.loadBackupPassword()
        guard case let .fetched(password) = await dataModel.backupPassword else {
            throw NoPasswordError()
        }
        let backupExport = BackupPasswordExport.createV1Export(
            key: password.key,
            salt: password.salt,
            keyDeriver: password.keyDervier
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
