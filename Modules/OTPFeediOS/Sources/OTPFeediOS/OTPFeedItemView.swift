import OTPFeed
import SwiftUI

public struct OTPFeedItemView<Preview: View>: View {
    var preview: Preview
    var buttonPadding: Double
    var onDetailTap: () -> Void

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            preview

            Button {
                onDetailTap()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
            }
            .foregroundColor(.accentColor)
            .padding(buttonPadding)
        }
    }
}
