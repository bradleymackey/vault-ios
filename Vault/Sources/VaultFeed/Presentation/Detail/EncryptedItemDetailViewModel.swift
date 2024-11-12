import Foundation
import VaultCore
import VaultKeygen

@MainActor
@Observable
public final class EncryptedItemDetailViewModel {
    public let item: EncryptedItem
    private let keyDeriverFactory: any VaultKeyDeriverFactory
    public var enteredEncryptionPassword = ""
    public private(set) var state: State = .base

    public enum State: Equatable {
        case base
        case decrypting
        case decryptedSecureNote(SecureNote)
        case decryptionError(PresentationError)

        public var preventsUserInteraction: Bool {
            switch self {
            case .decrypting: true
            default: false
            }
        }

        public var presentationError: PresentationError? {
            switch self {
            case let .decryptionError(error): error
            default: nil
            }
        }
    }

    public init(item: EncryptedItem, keyDeriverFactory: any VaultKeyDeriverFactory) {
        self.item = item
        self.keyDeriverFactory = keyDeriverFactory
    }

    public var canStartDecryption: Bool {
        state != .decrypting && enteredEncryptionPassword.isNotBlank
    }

    public func resetState() {
        state = .base
    }

    public func startDecryption() async {
        do {
            guard canStartDecryption else { return }
            state = .decrypting

            let signature = try VaultKeyDeriver.Signature(tryFromString: item.keygenSignature)
            let keyDeriver = keyDeriverFactory.lookupVaultKeyDeriver(signature: signature)
            let password = enteredEncryptionPassword
            let salt = item.keygenSalt
            let generatedPassword = try await Task.continuation {
                try keyDeriver.recreateEncryptionKey(password: password, salt: salt)
            }
            let action = attemptDecryption(password: generatedPassword)
            switch action {
            case .unknownItemError:
                throw PresentationError(
                    userTitle: "Error",
                    userDescription: "Your password was correct, but the item that was encrypted is not known to Vault. We can't display it.",
                    debugDescription: "unknownItemError"
                )
            case let .itemDataError(error):
                throw error // rethrow so state is set below
            case .promptForDifferentPassword:
                throw PresentationError(
                    userTitle: "Incorrect Password",
                    userDescription: "Your password was not recognized, please try again.",
                    debugDescription: "promptForDifferentPassword"
                )
            case let .decryptedSecureNote(secureNote):
                state = .decryptedSecureNote(secureNote)
            }
        } catch let localized as LocalizedError {
            state = .decryptionError(PresentationError(localizedError: localized))
        } catch {
            state = .decryptionError(PresentationError(
                userTitle: "Error",
                userDescription: "Unable to decrypt this item. Please try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }

    private enum Action {
        /// The item is of a kind that we cannot identify.
        case unknownItemError
        /// Decryption was successful, but the data is corrupt.
        case itemDataError(any Error)
        case promptForDifferentPassword
        case decryptedSecureNote(SecureNote)
    }

    private func attemptDecryption(password: DerivedEncryptionKey?) -> Action {
        guard let password else { return .promptForDifferentPassword }
        let decryptor = VaultItemDecryptor(key: password)
        do {
            let itemIdentifier = try decryptor.decryptItemIdentifier(item: item)
            switch itemIdentifier {
            case VaultIdentifiers.Item.secureNote:
                let decryptedNote: SecureNote = try decryptor.decrypt(
                    item: item,
                    expectedItemIdentifier: VaultIdentifiers.Item.secureNote
                )
                return .decryptedSecureNote(decryptedNote)
            default:
                throw UnsupportedItemError(identifier: itemIdentifier)
            }
        } catch VaultItemDecryptor.Error.decryptionFailed {
            return .promptForDifferentPassword
        } catch {
            return .itemDataError(error)
        }
    }

    /// Item is not supported in an encrypted container.
    private struct UnsupportedItemError: Error {
        var identifier: String
    }
}
