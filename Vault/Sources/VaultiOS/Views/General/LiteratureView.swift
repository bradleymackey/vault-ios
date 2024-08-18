import Foundation
import SwiftUI

/// A view that displays a single block of scrolling text.
public struct LiteratureView: View {
    public var title: String
    public var bodyText: AttributedString
    public var bodyColor: Color

    public init(title: String, bodyText: AttributedString, bodyColor: Color) {
        self.title = title
        self.bodyText = bodyText
        self.bodyColor = bodyColor
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading) {
                Text(bodyText)
                    .font(.body)
                    .foregroundStyle(bodyColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(24)
        }
        .navigationTitle(Text(title))
    }
}

struct LiteratureView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LiteratureView(
                title: "Testing",
                bodyText: "Hi there, what's up\n\nSecond\nThird\nFourth\nFifth",
                bodyColor: .secondary
            )
        }
    }
}
