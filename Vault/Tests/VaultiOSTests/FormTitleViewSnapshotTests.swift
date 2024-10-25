import Foundation
import SwiftUI
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct FormTitleViewSnapshotTests {
    @Test
    func layout() {
        let sut = FormTitleView(title: "Hello", description: "Hello world", systemIcon: "lock.fill", color: .red)
            .frame(width: 400, height: 500)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_longDescription() {
        let description = Array(repeating: "This is long.", count: 20).joined(separator: " ")
        let sut = FormTitleView(
            title: "Hello",
            description: description,
            systemIcon: "batteryblock.stack.trianglebadge.exclamationmark",
            color: .green
        )
        .frame(width: 400, height: 500)

        assertSnapshot(of: sut, as: .image)
    }
}
