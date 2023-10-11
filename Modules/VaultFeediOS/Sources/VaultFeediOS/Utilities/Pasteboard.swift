import Combine
import Foundation
import UIKit

/// The iOS system pasteboard.
///
/// Publishes when a copy is performed to the pasteboard.
@MainActor
@Observable
public final class Pasteboard {
    private let systemPasteboard: any SystemPasteboard
    private let didPasteSubject = PassthroughSubject<Void, Never>()

    public init(_ systemPasteboard: any SystemPasteboard) {
        self.systemPasteboard = systemPasteboard
    }

    public func copy(_ string: String) {
        systemPasteboard.copy(string: string)
        didPasteSubject.send()
    }

    public func didPaste() -> AnyPublisher<Void, Never> {
        didPasteSubject.eraseToAnyPublisher()
    }
}
