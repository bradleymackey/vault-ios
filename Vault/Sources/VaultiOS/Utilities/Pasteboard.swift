import Combine
import Foundation
import UIKit
import VaultCore
import VaultFeed
import VaultSettings

/// The iOS system pasteboard.
///
/// Publishes when a copy is performed to the pasteboard.
@MainActor
@Observable
public final class Pasteboard {
    private let systemPasteboard: any SystemPasteboard
    private let didPasteSubject = PassthroughSubject<Void, Never>()
    private let localSettings: LocalSettings

    init(_ systemPasteboard: any SystemPasteboard, localSettings: LocalSettings) {
        self.systemPasteboard = systemPasteboard
        self.localSettings = localSettings
    }

    func copy(_ action: VaultTextCopyAction) {
        let ttl = localSettings.state.pasteTimeToLive.duration
        let localOnly = !localSettings.state.isUniversalClipboardAllowed(for: action.contentType)
        systemPasteboard.copy(string: action.text, ttl: ttl, localOnly: localOnly)
        didPasteSubject.send()
    }

    func didPaste() -> AnyPublisher<Void, Never> {
        didPasteSubject.eraseToAnyPublisher()
    }
}
