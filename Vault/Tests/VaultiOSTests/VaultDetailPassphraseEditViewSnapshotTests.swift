import Foundation
import SwiftUI
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct VaultDetailPassphraseEditViewSnapshotTests {
    @Test
    func layout_notEnabled() async {
        let sut = VaultDetailPassphraseEditView(
            title: "My title",
            description: "This is my description",
            hiddenWithPassphraseTitle: "This is hidden title",
            viewConfig: .constant(.alwaysVisible),
            passphrase: .constant("this is passphrase"),
        )
        .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_enabled() async {
        let sut = VaultDetailPassphraseEditView(
            title: "My title",
            description: "This is my description",
            hiddenWithPassphraseTitle: "This is hidden title",
            viewConfig: .constant(.requiresSearchPassphrase),
            passphrase: .constant("this is passphrase"),
        )
        .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }
}
