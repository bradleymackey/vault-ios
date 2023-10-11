import Foundation
import SwiftUI

struct SettingsHeaderView: View {
    var image: Image
    var title: String

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            image
            Text(title)
        }
        .font(.footnote.bold())
        .textCase(.none)
    }
}
