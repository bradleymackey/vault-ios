import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import VaultiOS
import XCTest

final class GenericVaultItemPreviewViewGeneratorTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        _ = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        XCTAssertEqual(totp.calledMethods, [])
        XCTAssertEqual(hotp.calledMethods, [])
        XCTAssertEqual(note.calledMethods, [])
    }

    @MainActor
    func test_makeVaultPreviewView_makesTOTPViewForTOTP() throws {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let code = OTPAuthCode(type: .totp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(item: .otpCode(code), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_makeVaultPreviewView_makesHOTPViewForHOTP() throws {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let code = OTPAuthCode(type: .hotp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(item: .otpCode(code), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_makeVaultPreviewView_makesSecureNoteView() throws {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let noteItem = SecureNote(title: "Title", contents: "Contents")
        let view = sut.makeVaultPreviewView(item: .secureNote(noteItem), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_scenePhaseDidChange_callsOnAllCollaborators() {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        sut.scenePhaseDidChange(to: .active)

        XCTAssertEqual(totp.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(hotp.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(note.calledMethods, ["scenePhaseDidChange(to:)"])
    }

    @MainActor
    func test_didAppear_callsOnAllCollaborators() {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        sut.didAppear()

        XCTAssertEqual(totp.calledMethods, ["didAppear()"])
        XCTAssertEqual(hotp.calledMethods, ["didAppear()"])
        XCTAssertEqual(note.calledMethods, ["didAppear()"])
    }

    @MainActor
    func test_previewActionForVaultItem_returnsNilIfNoGeneratorCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.previewActionForVaultItemValue = nil
        let hotp = HOTPGeneratorMock()
        hotp.previewActionForVaultItemValue = nil
        let note = SecureNoteGeneratorMock()
        note.previewActionForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: .new())

        XCTAssertNil(action)
    }

    @MainActor
    func test_previewActionForVaultItem_returnsIfTOTPCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.previewActionForVaultItemValue = .copyText("totp")
        let hotp = HOTPGeneratorMock()
        hotp.previewActionForVaultItemValue = nil
        let note = SecureNoteGeneratorMock()
        note.previewActionForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: .new())

        XCTAssertEqual(action, .copyText("totp"))
    }

    @MainActor
    func test_previewActionForVaultItem_returnsIfHOTPCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.previewActionForVaultItemValue = nil
        let hotp = HOTPGeneratorMock()
        hotp.previewActionForVaultItemValue = .copyText("hotp")
        let note = SecureNoteGeneratorMock()
        note.previewActionForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: .new())

        XCTAssertEqual(action, .copyText("hotp"))
    }

    @MainActor
    func test_previewActionForVaultItem_returnsIfSecureNoteCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.previewActionForVaultItemValue = nil
        let hotp = HOTPGeneratorMock()
        hotp.previewActionForVaultItemValue = nil
        let note = SecureNoteGeneratorMock()
        note.previewActionForVaultItemValue = .copyText("secure note")
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: .new())

        XCTAssertEqual(action, .copyText("secure note"))
    }

    @MainActor
    func test_textToCopyForVaultItem_returnsNilIfNoGeneratorCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.textToCopyForVaultItemValue = nil
        let hotp = HOTPGeneratorMock()
        hotp.textToCopyForVaultItemValue = nil
        let note = SecureNoteGeneratorMock()
        note.textToCopyForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.textToCopyForVaultItem(id: .new())

        XCTAssertNil(action)
    }

    @MainActor
    func test_textToCopyForVaultItem_returnsIfTOTPCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.textToCopyForVaultItemValue = "totp"
        let hotp = HOTPGeneratorMock()
        hotp.textToCopyForVaultItemValue = nil
        let note = SecureNoteGeneratorMock()
        note.textToCopyForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.textToCopyForVaultItem(id: .new())

        XCTAssertEqual(action, "totp")
    }

    @MainActor
    func test_textToCopyForVaultItem_returnsIfHOTPCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.textToCopyForVaultItemValue = nil
        let hotp = HOTPGeneratorMock()
        hotp.textToCopyForVaultItemValue = "hotp"
        let note = SecureNoteGeneratorMock()
        note.textToCopyForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.textToCopyForVaultItem(id: .new())

        XCTAssertEqual(action, "hotp")
    }

    @MainActor
    func test_textToCopyForVaultItem_returnsIfSecureNoteCanHandle() {
        let totp = TOTPGeneratorMock()
        totp.textToCopyForVaultItemValue = nil
        let hotp = HOTPGeneratorMock()
        hotp.textToCopyForVaultItemValue = nil
        let note = SecureNoteGeneratorMock()
        note.textToCopyForVaultItemValue = "secure note"
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.textToCopyForVaultItem(id: .new())

        XCTAssertEqual(action, "secure note")
    }
}

// MARK: - Helpers

extension GenericVaultItemPreviewViewGeneratorTests {
    private typealias SUT = GenericVaultItemPreviewViewGenerator<
        TOTPGeneratorMock,
        HOTPGeneratorMock,
        SecureNoteGeneratorMock
    >
    @MainActor
    private func makeSUT(
        totp: TOTPGeneratorMock,
        hotp: HOTPGeneratorMock,
        secureNote: SecureNoteGeneratorMock
    ) -> SUT {
        GenericVaultItemPreviewViewGenerator(
            totpGenerator: totp,
            hotpGenerator: hotp,
            noteGenerator: secureNote
        )
    }
}

// MARK: - Mocks

private class HOTPGeneratorMock: VaultItemPreviewViewGenerator, VaultItemPreviewActionHandler,
    VaultItemCopyActionHandler
{
    typealias PreviewItem = HOTPAuthCode
    private(set) var calledMethods = [String]()

    @MainActor
    init() {}

    func makeVaultPreviewView(
        item _: PreviewItem,
        metadata _: VaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour
    ) -> some View {
        Text("HOTP")
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        calledMethods.append(#function)
    }

    func didAppear() {
        calledMethods.append(#function)
    }

    var previewActionForVaultItemValue: VaultItemPreviewAction? = nil
    func previewActionForVaultItem(id _: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        calledMethods.append(#function)
        return previewActionForVaultItemValue
    }

    var textToCopyForVaultItemValue: String? = nil
    func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> String? {
        calledMethods.append(#function)
        return textToCopyForVaultItemValue
    }
}

private class TOTPGeneratorMock: VaultItemPreviewViewGenerator, VaultItemPreviewActionHandler,
    VaultItemCopyActionHandler
{
    typealias PreviewItem = TOTPAuthCode
    private(set) var calledMethods = [String]()

    @MainActor
    init() {}

    func makeVaultPreviewView(
        item _: PreviewItem,
        metadata _: VaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour
    ) -> some View {
        Text("TOTP")
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        calledMethods.append(#function)
    }

    func didAppear() {
        calledMethods.append(#function)
    }

    var previewActionForVaultItemValue: VaultItemPreviewAction? = nil
    func previewActionForVaultItem(id _: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        calledMethods.append(#function)
        return previewActionForVaultItemValue
    }

    var textToCopyForVaultItemValue: String? = nil
    func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> String? {
        calledMethods.append(#function)
        return textToCopyForVaultItemValue
    }
}

private class SecureNoteGeneratorMock: VaultItemPreviewViewGenerator, VaultItemPreviewActionHandler,
    VaultItemCopyActionHandler
{
    typealias PreviewItem = SecureNote
    private(set) var calledMethods = [String]()

    @MainActor
    init() {}

    func makeVaultPreviewView(
        item _: SecureNote,
        metadata _: VaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour
    ) -> some View {
        Text("Secure Note")
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        calledMethods.append(#function)
    }

    func didAppear() {
        calledMethods.append(#function)
    }

    var previewActionForVaultItemValue: VaultItemPreviewAction? = nil
    func previewActionForVaultItem(id _: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        calledMethods.append(#function)
        return previewActionForVaultItemValue
    }

    var textToCopyForVaultItemValue: String? = nil
    func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> String? {
        calledMethods.append(#function)
        return textToCopyForVaultItemValue
    }
}
