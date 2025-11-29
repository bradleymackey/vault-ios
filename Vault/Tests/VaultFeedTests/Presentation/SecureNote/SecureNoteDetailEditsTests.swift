import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

@Suite
struct SecureNoteDetailEditsTests {
    @Test
    func isValid_validForTitleWithContents() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "Nice"

        #expect(sut.isValid)
    }

    @Test
    func isValid_invalidForEmptySearchPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.viewConfig = .requiresSearchPassphrase
        sut.searchPassphrase = ""

        #expect(sut.isValid == false)
    }

    @Test
    func isValid_validForNonEmptySearchPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.viewConfig = .requiresSearchPassphrase
        sut.searchPassphrase = "passphrase"

        #expect(sut.isValid)
    }

    @Test
    func title_isFirstLineOfContent() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\nSecond\nThird"

        #expect(sut.titleLine == "First")
    }

    @Test
    func title_skipsEmptyLines() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "\n\nFirst\n\nSecond\nThird"

        #expect(sut.titleLine == "First")
    }

    @Test
    func contentPreviewLine_isSecondLineOfContent() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\nSecond\nThird"

        #expect(sut.contentPreviewLine == "Second")
    }

    @Test
    func contentPreviewLine_isEmptyIfNoSecondLine() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First"

        #expect(sut.contentPreviewLine == "")
    }

    @Test
    func contentPreviewLine_skipsEmptyLines() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "\n\nFirst\n\nSecond\nThird"

        #expect(sut.contentPreviewLine == "Second")
    }

    @Test
    func contentPreviewLine_isEmptyIfNoteEncrpyted() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\n\nSecond\nThird"
        sut.existingEncryptionKey = .init(key: .random(), salt: .random(count: 10), keyDervier: .testing)

        #expect(sut.contentPreviewLine == "")
    }

    @Test
    func contentPreviewLine_isEmptyIfNoteAboutToBeENcrpyted() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\n\nSecond\nThird"
        sut.newEncryptionPassword = "password"

        #expect(sut.contentPreviewLine == "")
    }
}
