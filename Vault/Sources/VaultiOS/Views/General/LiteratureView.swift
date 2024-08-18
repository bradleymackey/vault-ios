import Foundation
import MarkdownUI
import SwiftUI
import VaultCore

/// A view that displays a single block of scrolling text.
public struct LiteratureView: View {
    public var title: String
    public var bodyText: FormattedString
    public var bodyColor: Color

    public init(title: String, bodyText: FormattedString, bodyColor: Color) {
        self.title = title
        self.bodyText = bodyText
        self.bodyColor = bodyColor
    }

    public var body: some View {
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
        bodyText: .markdown(.init(content: "Hi there, what's up\n\nSecond\nThird\nFourth\nFifth")),
        bodyColor: .secondary
    )
}
