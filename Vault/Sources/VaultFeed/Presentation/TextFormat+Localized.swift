import Foundation
import VaultCore

extension TextFormat {
    public var localizedString: String {
        switch self {
        case .markdown: "Markdown"
        case .plain: "Plain"
        }
    }
}
