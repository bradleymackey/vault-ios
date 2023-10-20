import Foundation
import TestHelpers
import VaultFeed
import XCTest

@MainActor
final class SecureNoteDetailViewModelTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let editor = MockSecureNoteDetailEditor()
        _ = makeSUT(editor: editor)

        XCTAssertEqual(editor.operationsPerformed, [])
    }
}

extension SecureNoteDetailViewModelTests {
    private func makeSUT(
        editor: MockSecureNoteDetailEditor = MockSecureNoteDetailEditor()
    ) -> SecureNoteDetailViewModel {
        SecureNoteDetailViewModel(storedNote: anyStoredNote(), storedMetadata: uniqueStoredMetadata(), editor: editor)
    }
}
