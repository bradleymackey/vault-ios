import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct TagPillView: View {
    var tag: VaultItemTag
    var isSelected: Bool = false

    var body: some View {
        Label(tag.name, systemImage: tag.iconName ?? "tag.fill")
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .circular)
                    .fill(isSelected ? tagColor : Color.clear)
                    .stroke(isSelected ? Color.clear : tagColor, lineWidth: 2)
            )
            .foregroundColor(isSelected ? .white : tagColor)
    }

    private var tagColor: Color {
        tag.color?.color ?? Color.accentColor
    }
}

#Preview("Not selected", traits: .sizeThatFitsLayout) {
    TagPillView(
        tag: .init(id: .init(), name: "Tag", color: .init(color: .blue), iconName: "tag.fill"),
        isSelected: false
    )
}

#Preview("Selected", traits: .sizeThatFitsLayout) {
    TagPillView(
        tag: .init(id: .init(), name: "Tag", color: .init(color: .blue), iconName: "tag.fill"),
        isSelected: true
    )
}
