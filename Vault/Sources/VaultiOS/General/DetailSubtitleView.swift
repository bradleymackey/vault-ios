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
            }
        }
    }
}

struct DetailSubtitleView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSubtitleView(title: "Test", subtitle: "hello world")
    }
}
