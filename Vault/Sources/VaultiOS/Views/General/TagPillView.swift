import Foundation
import SwiftUI
import VaultFeed

struct TagPillView: View {
    var tag: VaultItemTag
    var isSelected: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TagIconView(iconName: tag.iconName)
            Text(tag.name.isBlank ? "Tag" : tag.name)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .circular)
                .fill(fillColor)
                .stroke(strokeColor, lineWidth: 1)
        )
        .foregroundColor(strokeColor)
    }

    private var isLight: Bool {
        tag.color.color.isPercievedLight
    }

    private var isDark: Bool {
        tag.color.color.isPercievedDark
    }

    private var fillColor: Color {
        if isLight {
            isSelected ? tag.color.brighten(amount: -0.2).color : .clear
        } else if isDark {
            isSelected ? tag.color.brighten(amount: 0.2).color : .clear
        } else {
            isSelected ? tagColor : .clear
        }
    }

    private var strokeColor: Color {
        if isLight {
            isSelected ? .black.opacity(0.8) : tag.color.brighten(amount: -0.4).color
        } else if isDark {
            isSelected ? .white : .primary.opacity(0.9)
        } else {
            isSelected ? tagColor.contrastingForegroundColor : tagColor
        }
    }

    private var tagColor: Color {
        tag.color.color.opacity(isSelected ? 1 : 0.8)
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
