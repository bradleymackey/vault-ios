import Foundation
import UIKit
import VaultFeed
import VaultSettings

/// @mockable
public protocol SystemPasteboard {
    /// Copy the given string to the pasteboard.
    ///
    /// - Parameters:
    ///   - string: The value to copy.
    ///   - ttl: How long the item should live in the pasteboard. `nil` means no expiry.
    ///   - localOnly: When `true`, the item is not pushed to iCloud Universal Clipboard.
    func copy(string: String, ttl: Double?, localOnly: Bool)
}

/// The live iOS system pasteboard.
struct SystemPasteboardImpl: SystemPasteboard {
    /// Widely-supported clipboard-manager UTI for marking copied values as concealed (passwords / OTPs).
    /// Honoured by tools like Paste, Maccy, etc. so the copied value is not shown in clipboard previews.
    private static let concealedTypeIdentifier = "org.nspasteboard.ConcealedType"

    private let pasteboard = UIPasteboard.general
    private let clock: any EpochClock

    init(clock: any EpochClock) {
        self.clock = clock
    }

    func copy(string: String, ttl: Double?, localOnly: Bool) {
        var options: [UIPasteboard.OptionsKey: Any] = [.localOnly: localOnly]
        if let ttl {
            let expiryDate = Date(timeIntervalSince1970: clock.currentTime).addingTimeInterval(ttl)
            options[.expirationDate] = expiryDate
        }

        pasteboard.setItems([[
            UIPasteboard.typeAutomatic: string,
            Self.concealedTypeIdentifier: string,
        ]], options: options)
    }
}
