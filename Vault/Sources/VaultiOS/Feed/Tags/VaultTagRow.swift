import Foundation
import SwiftUI
import VaultFeed

struct VaultTagRow: View {
    var tag: VaultItemTag

    var body: some View {
        Label {
            Text(tag.name)
        } icon: {
            Image(systemName: tag.iconName ?? "tag.fill")
                .foregroundStyle(tag.color?.color ?? .primary)
        }
        .id(tag.id)
    }
}
