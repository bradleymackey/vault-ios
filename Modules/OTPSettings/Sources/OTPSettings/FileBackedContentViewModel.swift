import Foundation

/// A view model for content that is loaded from a resource file.
public protocol FileBackedContentViewModel {
    var fileName: String { get }
    var fileExtension: String { get }
}

public extension FileBackedContentViewModel {
    /// Load the content from this file.
    func loadContent() -> String? {
        guard let path = Bundle.module.path(forResource: fileName, ofType: fileExtension) else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let contents = try? Data(contentsOf: url) else {
            return nil
        }
        return String(data: contents, encoding: .utf8)
    }
}
