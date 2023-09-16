import Attribution
import SwiftUI

struct ThirdPartyLibraryRowView: View {
    var library: ThirdPartyLibrary
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(library.name)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(library.url.absoluteString)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}
