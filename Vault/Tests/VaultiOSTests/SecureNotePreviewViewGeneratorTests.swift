import Combine
import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import Testing
import VaultCore
import VaultFeed
@testable import VaultiOS

@Suite
@MainActor
final class SecureNotePreviewViewGeneratorTests {
    @Test
    func init_hasNoSideEffects() {
        let factory = SecureNotePreviewViewFactoryMock()
        _ = makeSUT(factory: factory)

        #expect(factory.makeSecureNoteViewCallCount == 0)
    }

    @Test
    func makeVaultPreviewItem_generatesViews() throws {
        let factory = SecureNotePreviewViewFactoryMock()
        factory.makeSecureNoteViewHandler = { _, _ in AnyView(Color.red) }
        let sut = makeSUT(factory: factory)

        let view = sut.makeVaultPreviewView(item: anySecureNote(), metadata: uniqueMetadata(), behaviour: .normal)

        #expect(factory.makeSecureNoteViewCallCount == 1)
        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }
}

// MARK: - Helpers

extension SecureNotePreviewViewGeneratorTests {
    private typealias SUT = SecureNotePreviewViewGenerator<SecureNotePreviewViewFactoryMock>

    private func makeSUT(
        factory: SecureNotePreviewViewFactoryMock = SecureNotePreviewViewFactoryMock(),
    ) -> SUT {
        SecureNotePreviewViewGenerator(viewFactory: factory)
    }
}
