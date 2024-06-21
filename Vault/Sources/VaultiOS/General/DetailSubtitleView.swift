import Foundation
import SwiftUI

struct DetailSubtitleView: View {
    var systemIcon: String?
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemIcon {
                Image(systemName: systemIcon)
                    .frame(minWidth: 24)
                    .padding(.vertical, 2)
            }

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
}

struct DetailSubtitleView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSubtitleView(title: "Test", subtitle: "hello world")
    }
}
