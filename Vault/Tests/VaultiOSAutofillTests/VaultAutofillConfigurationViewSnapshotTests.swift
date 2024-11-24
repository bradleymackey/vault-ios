import Foundation
import TestHelpers
import Testing
@testable import VaultiOSAutofill

@MainActor
struct VaultAutofillConfigurationViewSnapshotTests {
    @Test
    func layout() {
        let viewModel = VaultAutofillConfigurationViewModel(dismissSubject: .init())
        let sut = VaultAutofillConfigurationView(viewModel: viewModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }
}
