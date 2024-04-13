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
        let factory = MockSecureNoteViewFactory()
        _ = makeSUT(factory: factory)

        XCTAssertEqual(factory.makeSecureNoteViewExecutedCount, 0)
    }

    @MainActor
    func test_makeVaultPreviewItem_generatesViews() throws {
        let factory = MockSecureNoteViewFactory()
        let sut = makeSUT(factory: factory)

        let view = sut.makeVaultPreviewView(item: anySecureNote(), metadata: uniqueMetadata(), behaviour: .normal)

        let foundText = try view.inspect().text().string()
        XCTAssertEqual(foundText, "Hello, Secure Note!")
        XCTAssertEqual(factory.makeSecureNoteViewExecutedCount, 1)
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
    private typealias SUT = SecureNotePreviewViewGenerator<MockSecureNoteViewFactory>

    @MainActor
    private func makeSUT(
        factory: MockSecureNoteViewFactory = MockSecureNoteViewFactory()
    ) -> SUT {
        SecureNotePreviewViewGenerator(viewFactory: factory)
    }

    private final class MockSecureNoteViewFactory: SecureNotePreviewViewFactory {
        var makeSecureNoteViewExecutedCount = 0
        var makeSecureNoteViewExecuted: (
            SecureNotePreviewViewModel
        )
            -> Void = { _ in
            }

        func makeSecureNoteView(viewModel: SecureNotePreviewViewModel) -> some View {
            makeSecureNoteViewExecutedCount += 1
            makeSecureNoteViewExecuted(viewModel)
            return Text("Hello, Secure Note!")
        }
    }
}
