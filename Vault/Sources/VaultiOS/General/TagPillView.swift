import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct TagPillView: View {
    var tag: VaultItemTag
    var isSelected: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TagIconView(iconName: tag.iconName)
            Text(tag.name)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .circular)
                .fill(isSelected ? tagColor : .clear)
                .stroke(isSelected ? contrastingColor : tagColor, lineWidth: 1)
        )
        .foregroundColor(isSelected ? contrastingColor : tagColor)
    }

    private var tagColor: Color {
        (tag.color?.color ?? Color.accentColor).opacity(isSelected ? 1 : 0.8)
    }

    private var contrastingColor: Color {
        tagColor.contrastingForegroundColor
    }
}

#Preview("Not selected", traits: .sizeThatFitsLayout) {
    VStack {
        TagPillView(
            tag: .init(id: .init(), name: "Tag", color: .init(color: .blue), iconName: "tag.fill"),
            isSelected: false
        )
        TagPillView(
            tag: .init(id: .init(), name: "Tag", color: .init(color: .white), iconName: "tag.fill"),
            isSelected: false
        )
        TagPillView(
            tag: .init(id: .init(), name: "Tag", color: .init(color: .black), iconName: "tag.fill"),
            isSelected: false
        )
    }
}

#Preview("Selected", traits: .sizeThatFitsLayout) {
    VStack {
        TagPillView(
            tag: .init(id: .init(), name: "Tag", color: .init(color: .blue), iconName: "tag.fill"),
            isSelected: true
        )
        TagPillView(
            tag: .init(id: .init(), name: "Tag", color: .init(color: .white), iconName: "tag.fill"),
            isSelected: true
        )
        TagPillView(
            tag: .init(id: .init(), name: "Tag", color: .init(color: .black), iconName: "tag.fill"),
            isSelected: true
        )
    }
}
