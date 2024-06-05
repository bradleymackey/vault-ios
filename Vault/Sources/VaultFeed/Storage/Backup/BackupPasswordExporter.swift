import CryptoDocumentExporter
import Foundation

public final class BackupPasswordExporter {
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }

    public struct NoPasswordError: Error {}

    public func makeExport() throws -> BackupPasswordExport {
        guard let password = try store.fetchPassword() else {
            throw NoPasswordError()
        }
        return BackupPasswordExport.createV1Export(
            key: password.key,
            salt: password.salt
        )
    }
}
