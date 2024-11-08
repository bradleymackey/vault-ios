import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

final class GenericVaultItemPreviewViewGeneratorTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        _ = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        XCTAssertEqual(totp.calledMethods, [])
        XCTAssertEqual(hotp.calledMethods, [])
        XCTAssertEqual(note.calledMethods, [])
        XCTAssertEqual(encrypted.calledMethods, [])
    }

    @MainActor
    func test_makeVaultPreviewView_makesTOTPViewForTOTP() throws {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        let code = OTPAuthCode(type: .totp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(item: .otpCode(code), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_makeVaultPreviewView_makesHOTPViewForHOTP() throws {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        let code = OTPAuthCode(type: .hotp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(item: .otpCode(code), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_makeVaultPreviewView_makesSecureNoteView() throws {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        let noteItem = SecureNote(title: "Title", contents: "Contents", format: .markdown)
        let view = sut.makeVaultPreviewView(item: .secureNote(noteItem), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_makeVaultPreviewView_makesEncryptedItemView() throws {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        let encryptedItem = EncryptedItem(
            title: "Hello, there!",
            data: .random(count: 10),
            authentication: .random(count: 10),
            encryptionIV: .random(count: 10),
            keygenSalt: .random(count: 10),
            keygenSignature: "any"
        )
        let view = sut.makeVaultPreviewView(
            item: .encryptedItem(encryptedItem),
            metadata: uniqueMetadata(),
            behaviour: .normal
        )

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_scenePhaseDidChange_callsOnAllCollaborators() {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        sut.scenePhaseDidChange(to: .active)

        XCTAssertEqual(totp.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(hotp.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(note.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(encrypted.calledMethods, ["scenePhaseDidChange(to:)"])
    }

    @MainActor
    func test_clearViewCache_callsOnAllCollaborators() async {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        await sut.clearViewCache()

        XCTAssertEqual(totp.calledMethods, ["clearViewCache()"])
        XCTAssertEqual(hotp.calledMethods, ["clearViewCache()"])
        XCTAssertEqual(note.calledMethods, ["clearViewCache()"])
        XCTAssertEqual(encrypted.calledMethods, ["clearViewCache()"])
    }

    @MainActor
    func test_didAppear_callsOnAllCollaborators() {
        let totp = TOTPGeneratorMock()
        let hotp = HOTPGeneratorMock()
        let note = SecureNoteGeneratorMock()
        let encrypted = EncryptedItemGeneratorMock()
        let sut = makeSUT(totp: totp, hotp: hotp, secureNote: note, encryptedItem: encrypted)

        sut.didAppear()

        XCTAssertEqual(totp.calledMethods, ["didAppear()"])
        XCTAssertEqual(hotp.calledMethods, ["didAppear()"])
        XCTAssertEqual(note.calledMethods, ["didAppear()"])
        XCTAssertEqual(encrypted.calledMethods, ["didAppear()"])
    }
}

// MARK: - Helpers

extension GenericVaultItemPreviewViewGeneratorTests {
    private typealias SUT = GenericVaultItemPreviewViewGenerator<
        TOTPGeneratorMock,
        HOTPGeneratorMock,
        SecureNoteGeneratorMock,
        EncryptedItemGeneratorMock
    >
    @MainActor
    private func makeSUT(
        totp: TOTPGeneratorMock,
        hotp: HOTPGeneratorMock,
        secureNote: SecureNoteGeneratorMock,
        encryptedItem: EncryptedItemGeneratorMock
    ) -> SUT {
        GenericVaultItemPreviewViewGenerator(
            totpGenerator: totp,
            hotpGenerator: hotp,
            noteGenerator: secureNote,
            encryptedGenerator: encryptedItem
        )
    }
}

// MARK: - Mocks

private class HOTPGeneratorMock: VaultItemPreviewViewGenerator {
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

    func clearViewCache() async {
        calledMethods.append(#function)
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        calledMethods.append(#function)
    }

    func didAppear() {
        calledMethods.append(#function)
    }
}

private class TOTPGeneratorMock: VaultItemPreviewViewGenerator {
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

    func clearViewCache() async {
        calledMethods.append(#function)
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        calledMethods.append(#function)
    }

    func didAppear() {
        calledMethods.append(#function)
    }
}

private class SecureNoteGeneratorMock: VaultItemPreviewViewGenerator {
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

    func clearViewCache() async {
        calledMethods.append(#function)
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        calledMethods.append(#function)
    }

    func didAppear() {
        calledMethods.append(#function)
    }
}

private class EncryptedItemGeneratorMock: VaultItemPreviewViewGenerator {
    typealias PreviewItem = EncryptedItem
    private(set) var calledMethods = [String]()

    @MainActor
    init() {}

    func makeVaultPreviewView(
        item _: EncryptedItem,
        metadata _: VaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour
    ) -> some View {
        Text("Encrypted Item")
    }

    func clearViewCache() async {
        calledMethods.append(#function)
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        calledMethods.append(#function)
    }

    func didAppear() {
        calledMethods.append(#function)
    }
}
