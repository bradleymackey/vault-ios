import Foundation
import SwiftUI

struct DetailSubtitleView: View {
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
        DetailSubtitleView(title: "Test", subtitle: nil)
        DetailSubtitleView(title: "Test", subtitle: "Hello there")
        DetailSubtitleView(title: "Test", subtitle: Array(repeating: "Hello", count: 20).joined(separator: " "))
    }
}
