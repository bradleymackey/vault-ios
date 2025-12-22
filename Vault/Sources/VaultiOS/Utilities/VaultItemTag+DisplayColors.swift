import Foundation
import SwiftUI
import VaultFeed

extension VaultItemTag {
    /// Returns the fill/background color for displaying this tag
    /// - Parameter isSelected: Whether the tag is in a selected state
    func fillColor(isSelected: Bool) -> Color {
        let baseColor = color.color
        let isLight = baseColor.isPercievedLight
        let isDark = baseColor.isPercievedDark

        if isLight {
            return isSelected ? color.brighten(amount: -0.2).color : .clear
        } else if isDark {
            return isSelected ? color.brighten(amount: 0.2).color : .clear
        } else {
            let tagColor = baseColor.opacity(isSelected ? 1 : 0.8)
            return isSelected ? tagColor : .clear
        }
    }

    /// Returns the stroke/foreground color for displaying this tag
    /// - Parameter isSelected: Whether the tag is in a selected state
    func strokeColor(isSelected: Bool) -> Color {
        let baseColor = color.color
        let isLight = baseColor.isPercievedLight
        let isDark = baseColor.isPercievedDark

        if isLight {
            return isSelected ? .black.opacity(0.8) : color.brighten(amount: -0.4).color
        } else if isDark {
            return isSelected ? .white : .primary.opacity(0.9)
        } else {
            let tagColor = baseColor.opacity(isSelected ? 1 : 0.8)
            return isSelected ? tagColor.contrastingForegroundColor : tagColor
        }
    }

    /// Returns the background color for list row display (subtle tint for visibility)
    func listRowBackgroundColor() -> Color? {
        let baseColor = color.color

        if baseColor.isPercievedLight {
            return fillColor(isSelected: true)
        } else if baseColor.isPercievedDark {
            return fillColor(isSelected: true)
        }

        return nil
    }

    /// Returns the foreground color for list row display
    func listRowForegroundColor() -> Color {
        let baseColor = color.color

        // If color is too light or dark for default list background, use contrasting color
        if baseColor.isPercievedLight || baseColor.isPercievedDark {
            return baseColor.contrastingForegroundColor
        }

        return baseColor
    }
}
