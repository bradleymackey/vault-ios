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

        public var title: String {
            switch self {
            case .generated: "Decrypted"
            case let .error(error): error.userTitle
            case .none: "Encrypted"
            }
        }

        public var description: String? {
            switch self {
            case .generated: nil
            case let .error(error): error.userDescription
            case .none: "Your password is needed to decrypt the encrypted vault"
            }
        }
    }

    public var enteredPassword = ""
    public private(set) var generated: GenerationState = .none
    public private(set) var isDecrypting = false

    private let encryptedVault: EncryptedVault
    private let keyDeriverFactory: any VaultKeyDeriverFactory
    private let encryptedVaultDecoder: any EncryptedVaultDecoder

    public init(
        encryptedVault: EncryptedVault,
        keyDeriverFactory: any VaultKeyDeriverFactory,
        encryptedVaultDecoder: any EncryptedVaultDecoder
    ) {
        self.encryptedVault = encryptedVault
        self.keyDeriverFactory = keyDeriverFactory
        self.encryptedVaultDecoder = encryptedVaultDecoder
    }

    private struct MissingPasswordError: Error, LocalizedError {
        var errorDescription: String? { "Password Required" }
        var failureReason: String? { "The password cannot be empty" }
    }

    public var canAttemptDecryption: Bool {
        enteredPassword.isNotEmpty
    }

    public func attemptDecryption() async {
        do {
            guard enteredPassword.isNotEmpty else { throw MissingPasswordError() }
            isDecrypting = true
            defer { isDecrypting = false }
            let signature = try VaultKeyDeriver.Signature(tryFromString: encryptedVault.keygenSignature)
            let keyDeriver = keyDeriverFactory.lookupVaultKeyDeriver(signature: signature)
            let password = enteredPassword
            let salt = encryptedVault.keygenSalt
            let generatedKey = try await Task.continuation {
                try keyDeriver.recreateEncryptionKey(password: password, salt: salt)
            }
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
}
