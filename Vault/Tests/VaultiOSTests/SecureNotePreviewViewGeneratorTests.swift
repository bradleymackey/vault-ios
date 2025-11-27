import Combine
import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

final class SecureNotePreviewViewGeneratorTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let factory = SecureNotePreviewViewFactoryMock()
        _ = makeSUT(factory: factory)

        XCTAssertEqual(factory.makeSecureNoteViewCallCount, 0)
    }

    @MainActor
    func test_makeVaultPreviewItem_generatesViews() throws {
        let factory = SecureNotePreviewViewFactoryMock()
        factory.makeSecureNoteViewHandler = { _, _ in AnyView(Color.red) }
        let sut = makeSUT(factory: factory)

        let view = sut.makeVaultPreviewView(item: anySecureNote(), metadata: uniqueMetadata(), behaviour: .normal)

        XCTAssertEqual(factory.makeSecureNoteViewCallCount, 1)
        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }
}

// MARK: - Helpers

extension SecureNotePreviewViewGeneratorTests {
    private typealias SUT = SecureNotePreviewViewGenerator<SecureNotePreviewViewFactoryMock>

    @MainActor
    private func makeSUT(
        factory: SecureNotePreviewViewFactoryMock = SecureNotePreviewViewFactoryMock(),
    ) -> SUT {
        SecureNotePreviewViewGenerator(viewFactory: factory)
    }
}
