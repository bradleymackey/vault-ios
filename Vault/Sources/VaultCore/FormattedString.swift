import Foundation

public enum FormattedString {
    case raw(String)
    case markdown(MarkdownString)
}

extension FormattedString {
    public var textFormat: TextFormat {
        switch self {
        case .raw: .plain
        case .markdown: .markdown
        }
    }
}
