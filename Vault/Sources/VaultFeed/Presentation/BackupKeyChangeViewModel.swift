import CryptoEngine
import Foundation
import VaultBackup

@MainActor
@Observable
public final class BackupKeyChangeViewModel {
    public enum ExistingPasswordState: Equatable, Hashable {
        case loading
        case hasExistingPassword(BackupPassword)
        case noExistingPassword
        case errorFetching
    }

    public enum NewPasswordState: Equatable, Hashable {
        case neutral
        case creating
        case error
        case success

        public var isLoading: Bool {
            switch self {
            case .neutral, .error, .success: false
            case .creating: true
            }
        }
    }

    public var newlyEnteredPassword = ""
    public private(set) var existingPassword: ExistingPasswordState = .loading
    public private(set) var newPassword: NewPasswordState = .neutral
    private let encryptionKeyDeriver: any KeyDeriver
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
        encryptionKeyDeriver = BackupPassword.makeAppropriateEncryptionKeyDeriver()
    }

    public var encryptionKeyDeriverDescription: String {
        encryptionKeyDeriver.userVisibleDescription
    }

    public func loadInitialData() {
        do {
            if let password = try store.fetchPassword() {
                existingPassword = .hasExistingPassword(password)
            } else {
                existingPassword = .noExistingPassword
            }
        } catch {
            existingPassword = .errorFetching
        }
    }

    public func saveEnteredPassword() async {
        do {
            newPassword = .creating
            let createdBackupPassword = try await computeNewKey(text: newlyEnteredPassword)
            try store.set(password: createdBackupPassword)
            newPassword = .success
            existingPassword = .hasExistingPassword(createdBackupPassword)
        } catch {
            newPassword = .error
        }
    }

    private nonisolated func computeNewKey(text: String) async throws -> BackupPassword {
        let deriver = encryptionKeyDeriver
        return try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .utility).async {
                cont.resume(with: Result {
                    try BackupPassword.createEncryptionKey(deriver: deriver, text: text)
                })
            }
        }
    }
}
