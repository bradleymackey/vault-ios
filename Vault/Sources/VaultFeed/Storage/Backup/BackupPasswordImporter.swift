import Foundation

/// @mockable
public protocol BackupPasswordImporter {
    func importAndOverridePassword(from data: Data) throws
}

public final class BackupPasswordImporterImpl: BackupPasswordImporter {
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }

    public enum ImportError: Error {
        case incompatibleVersion
    }

    public func importAndOverridePassword(from data: Data) throws {
        let export = try makeImportDecoder().decode(BackupPasswordExport.self, from: data)
        guard export.version.isCompatible(with: "1.0.0") else {
            throw ImportError.incompatibleVersion
        }
        let newPassword = BackupPassword(key: export.key, salt: export.salt)
        try store.set(password: newPassword)
    }

    private func makeImportDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        return decoder
    }
}
