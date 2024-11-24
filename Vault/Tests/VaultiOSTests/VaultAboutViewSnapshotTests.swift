import Foundation
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct VaultAboutViewSnapshotTests {
    @Test
    func layout() {
        let sut = VaultAboutView(viewModel: .init())
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }
}
