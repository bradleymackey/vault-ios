import Foundation
import SwiftUI

struct TextAndSubtitle: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    List {
        TextAndSubtitle(title: "Test", subtitle: nil)
        TextAndSubtitle(title: "Test", subtitle: "Hello there")
        TextAndSubtitle(title: "Test", subtitle: Array(repeating: "Hello", count: 20).joined(separator: " "))
    }
}
