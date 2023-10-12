import Combine
import Foundation
import UIKit
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

    public init(_ systemPasteboard: any SystemPasteboard, localSettings: LocalSettings) {
        self.systemPasteboard = systemPasteboard
        self.localSettings = localSettings
    }

    public func copy(_ string: String) {
        let ttl = localSettings.state.pasteTimeToLive.duration
        systemPasteboard.copy(string: string, ttl: ttl)
        didPasteSubject.send()
    }

    public func didPaste() -> AnyPublisher<Void, Never> {
        didPasteSubject.eraseToAnyPublisher()
    }
}
