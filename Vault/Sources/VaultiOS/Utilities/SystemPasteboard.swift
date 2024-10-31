import Foundation
import UIKit
import VaultFeed
import VaultSettings

/// @mockable
public protocol SystemPasteboard {
    /// Copy the given string to the pasteboard.
    ///
    /// `ttl` is the amount of time that this should live in the pasteboard.
    /// If it's `nil`, it doesn't expire
    func copy(string: String, ttl: Double?)
}

/// The live iOS system pasteboard.
struct SystemPasteboardImpl: SystemPasteboard {
    private let pasteboard = UIPasteboard.general
    private let clock: any EpochClock

    init(clock: any EpochClock) {
        self.clock = clock
    }

    func copy(string: String, ttl: Double?) {
        var options: [UIPasteboard.OptionsKey: Any] = [.localOnly: false]
        if let ttl {
            let expiryDate = Date(timeIntervalSince1970: clock.currentTime).addingTimeInterval(ttl)
            options[.expirationDate] = expiryDate
        }

        pasteboard.setItems([[UIPasteboard.typeAutomatic: string]], options: options)
    }
}
