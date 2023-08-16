import Combine
import Foundation
import UIKit

/// The iOS system pasteboard.
///
/// Publishes when a copy is performed to the pasteboard.
@MainActor
public final class Pasteboard: ObservableObject {
    private let systemPasteboard: any SystemPasteboard
    public init(_ systemPasteboard: any SystemPasteboard) {
        self.systemPasteboard = systemPasteboard
    }

    public func copy(_ string: String) {
        systemPasteboard.copy(string: string)
        objectWillChange.send()
    }
}
