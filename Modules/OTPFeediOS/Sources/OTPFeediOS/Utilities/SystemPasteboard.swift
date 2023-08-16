import Foundation
import UIKit

public protocol SystemPasteboard {
    /// Copy the given string to the pasteboard.
    func copy(string: String)
}

/// The live iOS system pasteboard.
public struct LiveSystemPasteboard: SystemPasteboard {
    private let pasteboard = UIPasteboard.general
    public init() {}

    public func copy(string: String) {
        pasteboard.string = string
    }
}
