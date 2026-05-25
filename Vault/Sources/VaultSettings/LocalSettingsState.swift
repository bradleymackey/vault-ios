import Foundation
import FoundationExtensions
import VaultCore

/// Local settings for the codes.
@MainActor
public struct LocalSettingsState {
    @DefaultsStored public var pasteTimeToLive: PasteTTL

    /// When `true`, password copies are allowed to sync via iCloud Universal Clipboard.
    @DefaultsStored public var allowUniversalClipboardForPasswords: Bool
    /// When `true`, OTP copies are allowed to sync via iCloud Universal Clipboard.
    @DefaultsStored public var allowUniversalClipboardForOTPs: Bool
    /// When `true`, other sensitive copies are allowed to sync via iCloud Universal Clipboard.
    @DefaultsStored public var allowUniversalClipboardForOther: Bool

    init(defaults: Defaults) {
        _pasteTimeToLive = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init(VaultIdentifiers.Preferences.General.settingsPasteTTL),
            defaultValue: .default,
        )
        _allowUniversalClipboardForPasswords = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init(VaultIdentifiers.Preferences.UniversalClipboard.allowPasswords),
            defaultValue: false,
        )
        _allowUniversalClipboardForOTPs = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init(VaultIdentifiers.Preferences.UniversalClipboard.allowOTPs),
            defaultValue: false,
        )
        _allowUniversalClipboardForOther = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init(VaultIdentifiers.Preferences.UniversalClipboard.allowOther),
            defaultValue: false,
        )
    }

    /// Returns `true` if values of the given content type may be synced to Universal Clipboard.
    public func isUniversalClipboardAllowed(for contentType: PasteboardContentType) -> Bool {
        switch contentType {
        case .password: allowUniversalClipboardForPasswords
        case .otp: allowUniversalClipboardForOTPs
        case .other: allowUniversalClipboardForOther
        }
    }
}
