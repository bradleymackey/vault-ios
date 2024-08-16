import Foundation
import SwiftUI
import VaultFeed

struct TagIconView: View {
    var iconName: String?

    var body: some View {
        Image(systemName: iconName ?? VaultItemTag.defaultIconName)
    }
}
