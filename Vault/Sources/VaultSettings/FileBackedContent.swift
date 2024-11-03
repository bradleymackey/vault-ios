import Foundation
import VaultCore

/// A view model for content that is loaded from a resource file.
public protocol FileBackedContent {
    var fileName: String { get }
    var fileExtension: String { get }
}

extension FileBackedContent {
    /// Load the content from this file.
    public func loadContent() -> FormattedString? {
        guard let path = Bundle.module.path(forResource: fileName, ofType: fileExtension) else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let contents = try? Data(contentsOf: url) else {
            return nil
        }
        guard let string = String(data: contents, encoding: .utf8) else {
            return nil
        }
        return switch fileExtension {
        case "md": .markdown(MarkdownString(string))
        default: .raw(string)
        }
    }

    public var errorLoadingMessage: String {
        localized(key: "settings.errorLoadingDocument")
    }
}
