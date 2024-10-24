import Combine
import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class OTPCodePreviewViewModelTests: XCTestCase {
    @MainActor
    func test_code_updatesWithCodes() async throws {
        let (codePublisher, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            codePublisher.subject.send("hello")
        }
        XCTAssertEqual(sut.code, .visible("hello"))

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            codePublisher.subject.send("world")
        }
        XCTAssertEqual(sut.code, .visible("world"))
    }

    @MainActor
    func test_code_goesToNoMoreCodesWhenFinished() async throws {
        let (codePublisher, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            codePublisher.subject.send("hi")
        }
        XCTAssertEqual(sut.code, .visible("hi"))

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            codePublisher.subject.send(completion: .finished)
        }
        XCTAssertEqual(sut.code, .finished)
    }

    @MainActor
    func test_code_goesToErrorWhenErrors() async throws {
        let (codePublisher, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            codePublisher.subject.send(completion: .failure(anyNSError()))
        }

        switch sut.code {
        case .error:
            break
        default:
            XCTFail("Unexpected output")
        }
    }

    @MainActor
    func test_codeExpired_obfuscatesCode() async throws {
        let (_, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            sut.codeExpired()
        }

        XCTAssertEqual(sut.code, .obfuscated(.expiry))
    }

    @MainActor
    func test_obfuscateCodeForPrivacy_obfuscatesCode() async throws {
        let (_, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            sut.obfuscateCodeForPrivacy()
        }

        XCTAssertEqual(sut.code, .obfuscated(.privacy))
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

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        issuer: String = "any",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (OTPCodePublisherMock, OTPCodePreviewViewModel) {
        let codePublisher = OTPCodePublisherMock()
        let viewModel = OTPCodePreviewViewModel(
            accountName: "any",
            issuer: issuer,
            color: .default,
            codePublisher: codePublisher
        )
        trackForMemoryLeaks(viewModel, file: file, line: line)
        return (codePublisher, viewModel)
    }
}
