import Foundation
import SwiftUI
import VaultFeed
import VaultSettings

/// A settings screen where the content is populated by a `FileBackedContentViewModel`
struct SettingsDocumentView: View {
    var title: String
    var bodyText: FormattedString

    init(title: String, viewModel: some FileBackedContentViewModel) {
        self.title = title
        bodyText = viewModel.loadContent() ?? .raw(viewModel.errorLoadingMessage)
    }

    var body: some View {
        LiteratureView(title: title, bodyText: bodyText, bodyColor: .secondary)
            .navigationBarTitleDisplayMode(.inline)
    }
}
