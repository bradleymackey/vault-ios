import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct TagPillView: View {
    var tag: VaultItemTag

    var body: some View {
        Label(tag.name, systemImage: tag.iconName ?? "tag.fill")
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .circular)
                    .fill(tag.color?.color ?? Color.accentColor)
            )
            .foregroundColor(.white)
    }
}

#Preview {
    TagPillView(tag: .init(id: .init(), name: "Tag", color: .init(color: .blue), iconName: "tag.fill"))
}
