import Foundation
import VaultCore
import VaultKeygen

/// Controls the state and flow of loic during viewing an
struct EncryptedItemViewFlowState {
    enum Action {
        /// The item is of a kind that we cannot identify.
        case unknownItemError
        /// Decryption was successful, but the data is corrupt.
        case itemDataError(any Error)
        case promptForDifferentPassword
        case decryptedSecureNote(SecureNote)
    }

    let encryptedItem: EncryptedItem

    func passwordProvided(password: DerivedEncryptionKey?) -> Action {
        guard let password else { return .promptForDifferentPassword }
        let decryptor = VaultItemDecryptor(key: password)
        do {
            let itemIdentifier = try decryptor.decryptItemIdentifier(item: encryptedItem)
            switch itemIdentifier {
            case VaultIdentifiers.Item.secureNote:
                let decryptedNote: SecureNote = try decryptor.decrypt(
                    item: encryptedItem,
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
