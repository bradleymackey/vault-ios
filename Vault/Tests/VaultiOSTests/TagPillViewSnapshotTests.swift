import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
struct TagPillViewSnapshotTests {
    @Test
    func darkColored() {
        let tag = VaultItemTag(id: .new(), name: "Dark Color", color: .init(red: 0.05, green: 0.1, blue: 0.02))

        snapshotScenarios(tag: tag)
    }

    @Test
    func midColored() {
        let tag = VaultItemTag(id: .new(), name: "Light Color", color: .init(red: 0.5, green: 0.5, blue: 0.5))

        snapshotScenarios(tag: tag)
    }

    @Test
    func lightColored() {
        let tag = VaultItemTag(id: .new(), name: "Light Color", color: .init(red: 1, green: 1, blue: 1))

        snapshotScenarios(tag: tag)
    }
}

extension TagPillViewSnapshotTests {
    func snapshotScenarios(tag: VaultItemTag, testName: String = #function) {
        for isSelected in [true, false] {
            let tagView = TagPillView(tag: tag, isSelected: isSelected)
            let isSelectedName = isSelected ? "selected" : "no-selected"
            for colorScheme in ColorScheme.allCases {
                let colorSchemeName = colorScheme.description
                let sut = tagView
                    .frame(width: 300, height: 200)
                    .background(Color(UIColor.systemBackground))
                    .environment(\.colorScheme, colorScheme)

                let config = [isSelectedName, colorSchemeName].joined(separator: ".")
                assertSnapshot(of: sut, as: .image, named: config, testName: testName)
            }
        }
    }
}

extension ColorScheme: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .light: "light"
        case .dark: "dark"
        @unknown default: "unknown"
        }
    }
}
