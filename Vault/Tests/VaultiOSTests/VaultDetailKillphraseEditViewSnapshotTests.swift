import Foundation
import SwiftUI
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct VaultDetailKillphraseEditViewSnapshotTests {
    @Test
    func layout_notEnabled() async {
        let sut = VaultDetailKillphraseEditView(
            title: "This is my title",
            description: "This is my description",
            hiddenWithKillphraseTitle: "This is hidden with passphrase",
            killphrase: .constant("")
        )
        .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_enabled() async {
        let sut = VaultDetailKillphraseEditView(
            title: "This is my title",
            description: "This is my description",
            hiddenWithKillphraseTitle: "This is hidden with passphrase",
            killphrase: .constant("this is kill")
        )
        .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }
}
