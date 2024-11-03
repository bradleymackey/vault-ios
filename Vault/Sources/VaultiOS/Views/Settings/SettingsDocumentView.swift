import Foundation
import SwiftUI
import VaultFeed
import VaultSettings

/// A settings screen where the content is populated by a `FileBackedContent`
struct SettingsDocumentView: View {
    var title: String
    var bodyText: FormattedString

    init(title: String, content: some FileBackedContent) {
        self.title = title
        bodyText = content.loadContent() ?? .raw(content.errorLoadingMessage)
    }

    var body: some View {
        LiteratureView(title: title, bodyText: bodyText, bodyColor: .secondary)
            .navigationBarTitleDisplayMode(.inline)
    }
}
