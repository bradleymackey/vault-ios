import Foundation
import MarkdownUI
import SwiftUI
import VaultFeed

/// A view that displays a single block of scrolling text.
struct LiteratureView: View {
    var title: String
    var bodyText: FormattedString
    var bodyColor: Color

    init(title: String, bodyText: FormattedString, bodyColor: Color) {
        self.title = title
        self.bodyText = bodyText
        self.bodyColor = bodyColor
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading) {
                switch bodyText {
                case let .raw(string):
                    Text(string)
                        .font(.body)
                        .foregroundStyle(bodyColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case let .markdown(markdownString):
                    Markdown(MarkdownContent(markdownString.content))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 8)
            .padding(24)
        }
        .navigationTitle(Text(title))
    }
}

#Preview {
    LiteratureView(
        title: "Testing",
        bodyText: .markdown(.init("Hi there, what's up\n\nSecond\nThird\nFourth\nFifth")),
        bodyColor: .secondary,
    )
}
