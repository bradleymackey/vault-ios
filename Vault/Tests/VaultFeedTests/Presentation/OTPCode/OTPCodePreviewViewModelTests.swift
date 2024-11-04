import Combine
import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class OTPCodePreviewViewModelTests: XCTestCase {
    @MainActor
    func test_code_updatesWithCodes() async throws {
        let (codePublisher, sut) = makeSUT()

        try await sut.waitForChange(to: \.code) {
            codePublisher.subject.send("hello")
        }
        XCTAssertEqual(sut.code, .visible("hello"))

        try await sut.waitForChange(to: \.code) {
            codePublisher.subject.send("world")
        }
        XCTAssertEqual(sut.code, .visible("world"))
    }

    @MainActor
    func test_code_lockedUpdatesWithObfuscatedCodes() async throws {
        let (codePublisher, sut) = makeSUT(isLocked: true)

        try await sut.waitForChange(to: \.code) {
            codePublisher.subject.send("hello")
        }
        XCTAssertEqual(sut.code, .locked(code: "hello"))

        try await sut.waitForChange(to: \.code) {
            codePublisher.subject.send("world")
        }
        XCTAssertEqual(sut.code, .locked(code: "world"))
    }

    @MainActor
    func test_code_goesToNoMoreCodesWhenFinished() async throws {
        let (codePublisher, sut) = makeSUT()

        try await sut.waitForChange(to: \.code) {
            codePublisher.subject.send("hi")
        }
        XCTAssertEqual(sut.code, .visible("hi"))

        try await sut.waitForChange(to: \.code) {
            codePublisher.subject.send(completion: .finished)
        }
        XCTAssertEqual(sut.code, .finished)
    }

    @MainActor
    func test_code_goesToErrorWhenErrors() async throws {
        let (codePublisher, sut) = makeSUT()

        try await sut.waitForChange(to: \.code) {
            codePublisher.subject.send(completion: .failure(TestError()))
        }

        switch sut.code {
        case .error:
            break
        default:
            XCTFail("Unexpected output")
        }
    }

    @MainActor
    func test_update_setsCodeToVisible() {
        let (_, sut) = makeSUT()

        sut.update(.visible("123456"))

        XCTAssertEqual(sut.code, .visible("123456"))
    }

    @MainActor
    func test_update_obfuscatesForPrivacy() {
        let (_, sut) = makeSUT()

        sut.update(.visible("123456"))
        sut.update(.obfuscated(.privacy))

        XCTAssertEqual(sut.code, .obfuscated(.privacy))
    }

    @MainActor
    func test_updateRemovePrivacyObfuscation_removesPreviousPrivacyObfuscation() {
        let (_, sut) = makeSUT()

        sut.update(.visible("456"))
        sut.update(.obfuscated(.privacy))
        sut.updateRemovePrivacyObfuscation()

        XCTAssertEqual(sut.code, .visible("456"))
    }

    @MainActor
    func test_updateRemovePrivacyObfuscation_hasNoEffectForNonPrivacyObfuscation() {
        let states: [OTPCodeState] = [
            .obfuscated(.expiry),
            .error(.init(userTitle: "", debugDescription: ""), digits: 1),
            .finished,
            .notReady,
            .visible("111"),
            .locked(code: "1234"),
        ]
        for state in states {
            let (_, sut) = makeSUT()
            sut.update(.visible("456"))
            sut.update(state)
            sut.updateRemovePrivacyObfuscation()

            XCTAssertEqual(sut.code, state, "\(state) should be the current state")
        }
    }

    @MainActor
    func test_visibleIssuer_isPlaceholderIfIssuerEmpty() {
        let (_, sut) = makeSUT(issuer: "")

        XCTAssertEqual(sut.visibleIssuer, "Unnamed")
    }

    @MainActor
    func test_visibleIssuer_isIssuerIfNotEmpty() {
        let (_, sut) = makeSUT(issuer: "my issuer")

        XCTAssertEqual(sut.visibleIssuer, "my issuer")
    }

    @MainActor
    func test_pasteboardCopyText_isVisibleCode() {
        let (_, sut) = makeSUT()
        sut.update(.visible("1234"))

        let expected = VaultTextCopyAction(text: "1234", requiresAuthenticationToCopy: false)
        XCTAssertEqual(sut.pasteboardCopyText, expected)
    }

    @MainActor
    func test_pasteboardCopyText_isLockedCode() {
        let (_, sut) = makeSUT()
        sut.update(.locked(code: "4567"))

        let expected = VaultTextCopyAction(text: "4567", requiresAuthenticationToCopy: true)
        XCTAssertEqual(sut.pasteboardCopyText, expected)
    }

    @MainActor
    func test_pasteboardCopyText_isNil() {
        let nilCases: [OTPCodeState] = [
            .notReady,
            .finished,
            .error(.init(userTitle: "", debugDescription: ""), digits: 1),
            .obfuscated(.privacy),
            .obfuscated(.expiry),
        ]
        for nilCase in nilCases {
            let (_, sut) = makeSUT()
            sut.update(nilCase)

            XCTAssertNil(sut.pasteboardCopyText)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        issuer: String = "any",
        isLocked: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (OTPCodePublisherMock, OTPCodePreviewViewModel) {
        let codePublisher = OTPCodePublisherMock()
        let viewModel = OTPCodePreviewViewModel(
            accountName: "any",
            issuer: issuer,
            color: .default,
            isLocked: isLocked,
            codePublisher: codePublisher
        )
        trackForMemoryLeaks(viewModel, file: file, line: line)
        return (codePublisher, viewModel)
    }
}
