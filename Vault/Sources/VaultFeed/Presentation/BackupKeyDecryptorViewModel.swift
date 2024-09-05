import CryptoEngine
import Foundation
import FoundationExtensions
import VaultBackup

@MainActor
@Observable
public final class BackupKeyDecryptorViewModel {
    public enum GenerationState: Equatable, Hashable {
        case none
        case error(PresentationError)
        case generated(DerivedEncryptionKey)

        public var generatedKey: DerivedEncryptionKey? {
            switch self {
            case let .generated(key): key
            default: nil
            }
        }

        public var isSuccess: Bool {
            switch self {
            case .generated: true
            case .none, .error: false
            }
        }

        public var isError: Bool {
            switch self {
            case .error: true
            case .none, .generated: false
            }
        }
    }

    public var enteredPassword = ""
    public private(set) var generated: GenerationState = .none

    private let keyDeriver: VaultKeyDeriver
    private let encryptedVaultDecoder: any EncryptedVaultDecoder

    public init(
        keyDeriver: VaultKeyDeriver,
        encryptedVaultDecoder: any EncryptedVaultDecoder
    ) {
        self.keyDeriver = keyDeriver
        self.encryptedVaultDecoder = encryptedVaultDecoder
    }

    private struct MissingPasswordError: Error, LocalizedError {
        var errorDescription: String? { "Password Required" }
        var failureReason: String? { "The password cannot be empty" }
    }

    public func attemptDecryption(encryptedVault: EncryptedVault) async {
        do {
            guard enteredPassword.isNotEmpty else { throw MissingPasswordError() }
            let generatedKey = try await computeKey(password: enteredPassword, salt: encryptedVault.keygenSalt)
            try encryptedVaultDecoder.verifyCanDecrypt(key: generatedKey.key, encryptedVault: encryptedVault)
            generated = .generated(generatedKey)
        } catch let error as LocalizedError {
            generated = .error(.init(localizedError: error))
        } catch {
            generated = .error(PresentationError(
                userTitle: "Password Generation Error",
                userDescription: "Please try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }

    private nonisolated func computeKey(password: String, salt: Data) async throws -> DerivedEncryptionKey {
        let deriver = keyDeriver
        return try await Task.continuation {
            try deriver.recreateEncryptionKey(password: password, salt: salt)
        }
    }
}
