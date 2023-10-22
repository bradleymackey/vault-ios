import Foundation
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import VaultiOS
import XCTest

@MainActor
final class GenericVaultItemPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let note = MockSecureNoteGenerator()
        _ = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        XCTAssertEqual(totp.calledMethods, [])
        XCTAssertEqual(hotp.calledMethods, [])
        XCTAssertEqual(note.calledMethods, [])
    }

    func test_makeVaultPreviewView_makesTOTPViewForTOTP() throws {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let note = MockSecureNoteGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let code = OTPAuthCode(type: .totp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(item: .otpCode(code), metadata: uniqueMetadata(), behaviour: .normal)

        let text = try view.inspect().text().string()
        XCTAssertEqual(text, "TOTP")
    }

    func test_makeVaultPreviewView_makesHOTPViewForHOTP() throws {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let note = MockSecureNoteGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let code = OTPAuthCode(type: .hotp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(item: .otpCode(code), metadata: uniqueMetadata(), behaviour: .normal)

        let text = try view.inspect().text().string()
        XCTAssertEqual(text, "HOTP")
    }

    func test_makeVaultPreviewView_makesSecureNoteView() throws {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let note = MockSecureNoteGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let noteItem = SecureNote(title: "Title", contents: "Contents")
        let view = sut.makeVaultPreviewView(item: .secureNote(noteItem), metadata: uniqueMetadata(), behaviour: .normal)

        let text = try view.inspect().text().string()
        XCTAssertEqual(text, "Secure Note")
    }

    func test_scenePhaseDidChange_callsOnAllCollaborators() {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let note = MockSecureNoteGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        sut.scenePhaseDidChange(to: .active)

        XCTAssertEqual(totp.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(hotp.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(note.calledMethods, ["scenePhaseDidChange(to:)"])
    }

    func test_didAppear_callsOnAllCollaborators() {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let note = MockSecureNoteGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        sut.didAppear()

        XCTAssertEqual(totp.calledMethods, ["didAppear()"])
        XCTAssertEqual(hotp.calledMethods, ["didAppear()"])
        XCTAssertEqual(note.calledMethods, ["didAppear()"])
    }

    func test_previewActionForVaultItem_returnsNilIfNoGeneratorCanHandle() {
        let totp = MockTOTPGenerator()
        totp.previewActionForVaultItemValue = nil
        let hotp = MockHOTPGenerator()
        hotp.previewActionForVaultItemValue = nil
        let note = MockSecureNoteGenerator()
        note.previewActionForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: UUID())

        XCTAssertNil(action)
    }

    func test_previewActionForVaultItem_returnsIfTOTPCanHandle() {
        let totp = MockTOTPGenerator()
        totp.previewActionForVaultItemValue = .copyText("totp")
        let hotp = MockHOTPGenerator()
        hotp.previewActionForVaultItemValue = nil
        let note = MockSecureNoteGenerator()
        note.previewActionForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: UUID())

        XCTAssertEqual(action, .copyText("totp"))
    }

    func test_previewActionForVaultItem_returnsIfHOTPCanHandle() {
        let totp = MockTOTPGenerator()
        totp.previewActionForVaultItemValue = nil
        let hotp = MockHOTPGenerator()
        hotp.previewActionForVaultItemValue = .copyText("hotp")
        let note = MockSecureNoteGenerator()
        note.previewActionForVaultItemValue = nil
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: UUID())

        XCTAssertEqual(action, .copyText("hotp"))
    }

    func test_previewActionForVaultItem_returnsIfSecureNoteCanHandle() {
        let totp = MockTOTPGenerator()
        totp.previewActionForVaultItemValue = nil
        let hotp = MockHOTPGenerator()
        hotp.previewActionForVaultItemValue = nil
        let note = MockSecureNoteGenerator()
        note.previewActionForVaultItemValue = .copyText("secure note")
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note)

        let action = sut.previewActionForVaultItem(id: UUID())

        XCTAssertEqual(action, .copyText("secure note"))
    }
}

extension GenericVaultItemPreviewViewGeneratorTests {
    private typealias SUT = GenericVaultItemPreviewViewGenerator<
        MockTOTPGenerator,
        MockHOTPGenerator,
        MockSecureNoteGenerator
    >
    private func makeSUT(
        totp: MockTOTPGenerator,
        hotp: MockHOTPGenerator,
        secureNote: MockSecureNoteGenerator
    ) -> SUT {
        GenericVaultItemPreviewViewGenerator(
            totpGenerator: totp,
            hotpGenerator: hotp,
            noteGenerator: secureNote
        )
    }

    private class MockHOTPGenerator: VaultItemPreviewViewGenerator, VaultItemPreviewActionHandler {
        typealias PreviewItem = HOTPAuthCode
        private(set) var calledMethods = [String]()

        @MainActor
        init() {}

        func makeVaultPreviewView(
            item _: PreviewItem,
            metadata _: StoredVaultItem.Metadata,
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
        func previewActionForVaultItem(id _: UUID) -> VaultItemPreviewAction? {
            calledMethods.append(#function)
            return previewActionForVaultItemValue
        }
    }

    private class MockTOTPGenerator: VaultItemPreviewViewGenerator, VaultItemPreviewActionHandler {
        typealias PreviewItem = TOTPAuthCode
        private(set) var calledMethods = [String]()

        @MainActor
        init() {}

        func makeVaultPreviewView(
            item _: PreviewItem,
            metadata _: StoredVaultItem.Metadata,
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
        func previewActionForVaultItem(id _: UUID) -> VaultItemPreviewAction? {
            calledMethods.append(#function)
            return previewActionForVaultItemValue
        }
    }

    private class MockSecureNoteGenerator: VaultItemPreviewViewGenerator, VaultItemPreviewActionHandler {
        typealias PreviewItem = SecureNote
        private(set) var calledMethods = [String]()

        @MainActor
        init() {}

        func makeVaultPreviewView(
            item _: SecureNote,
            metadata _: StoredVaultItem.Metadata,
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
        func previewActionForVaultItem(id _: UUID) -> VaultItemPreviewAction? {
            calledMethods.append(#function)
            return previewActionForVaultItemValue
        }
    }
}
