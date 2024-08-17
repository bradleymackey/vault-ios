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
            VStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.headline.bold())
                if let subtitle {
                    Text(subtitle)
                        .font(.body)
                }
            }
        }
        .textCase(.none)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        // list row seperator is as wide as the content
        // (ideally it would be as wide as the list row, but we can't size based on parent at the moment easily)
        .alignmentGuide(.listRowSeparatorLeading, computeValue: { _ in 0 })
        .alignmentGuide(.listRowSeparatorTrailing, computeValue: { $0.width })
    }
}
