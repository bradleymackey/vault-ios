import Foundation
import SwiftUI

/// Temporary view to use when there is no content with: icon, title, description.
struct PlaceholderView: View {
    var systemIcon: String
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: systemIcon)
                .font(.largeTitle)
                .foregroundStyle(.primary)
            VStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .textCase(.none)
        .multilineTextAlignment(.center)
        .listRowSeparator(.hidden)
    }
}

#Preview {
    Form {
        PlaceholderView(systemIcon: "checkmark", title: "Hello World", subtitle: "This is the subtitle for this view")
            .containerRelativeFrame(.horizontal)
    }
}
