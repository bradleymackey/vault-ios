import Foundation

final class KeychainBackupPasswordStore: BackupPasswordStore {
    private let keychain: SimpleKeychain

    init(keychain: SimpleKeychain) {
        self.keychain = keychain
    }

    func fetchPassword() throws -> BackupPassword? {
        // TODO: implement
        nil
    }

    func set(password _: BackupPassword) throws {
        // TODO: implement
    }
}
