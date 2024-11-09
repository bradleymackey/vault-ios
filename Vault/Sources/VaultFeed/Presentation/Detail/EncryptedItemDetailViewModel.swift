import Foundation

@MainActor
@Observable
public final class EncryptedItemDetailViewModel {
    public let item: EncryptedItem
    public var enteredEncryptionPassword = ""

    public init(item: EncryptedItem) {
        self.item = item
    }

    public var shouldAllowDecryptionToStart: Bool {
        enteredEncryptionPassword.isNotBlank
    }
}
