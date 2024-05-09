import Combine
import Foundation
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
        factory.makeSecureNoteViewHandler = { _, _ in AnyView(Text("Hello, Secure Note!")) }
        let sut = makeSUT(factory: factory)

        let view = sut.makeVaultPreviewView(item: anySecureNote(), metadata: uniqueMetadata(), behaviour: .normal)

        let foundText = try view.inspect().anyView().text().string()
        XCTAssertEqual(foundText, "Hello, Secure Note!")
        XCTAssertEqual(factory.makeSecureNoteViewCallCount, 1)
    }

    @MainActor
    func test_previewActionForVaultItem_opensItemDetailForGivenID() {
        let sut = makeSUT()
        let itemID = UUID()

        let action = sut.previewActionForVaultItem(id: itemID)

        XCTAssertEqual(action, .openItemDetail(itemID))
    }
}

// MARK: - Helpers

extension SecureNotePreviewViewGeneratorTests {
    private typealias SUT = SecureNotePreviewViewGenerator<SecureNotePreviewViewFactoryMock>

    @MainActor
    private func makeSUT(
        factory: SecureNotePreviewViewFactoryMock = SecureNotePreviewViewFactoryMock()
    ) -> SUT {
        SecureNotePreviewViewGenerator(viewFactory: factory)
    }
}
