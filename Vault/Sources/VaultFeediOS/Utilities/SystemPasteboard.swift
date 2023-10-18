import Foundation
import UIKit
import VaultCore
import VaultSettings

public protocol SystemPasteboard {
    /// Copy the given string to the pasteboard.
    ///
    /// `ttl` is the amount of time that this should live in the pasteboard.
    /// If it's `nil`, it doesn't expire
    func copy(string: String, ttl: Double?)
}

/// The live iOS system pasteboard.
public struct LiveSystemPasteboard: SystemPasteboard {
    private let pasteboard = UIPasteboard.general
    private let clock: EpochClock

    public init(clock: EpochClock) {
        self.clock = clock
    }

    public func copy(string: String, ttl: Double?) {
        var options: [UIPasteboard.OptionsKey: Any] = [.localOnly: false]
        if let ttl {
            let expiryDate = Date(timeIntervalSince1970: clock.currentTime).addingTimeInterval(ttl)
            options[.expirationDate] = expiryDate
        }

        pasteboard.setItems([[UIPasteboard.typeAutomatic: string]], options: options)
    }
}
