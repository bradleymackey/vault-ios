import Combine
import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class OTPCodePreviewViewModelTests: XCTestCase {
    @MainActor
    func test_code_updatesWithCodes() async throws {
        let (renderer, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            renderer.subject.send("hello")
        }
        XCTAssertEqual(sut.code, .visible("hello"))

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            renderer.subject.send("world")
        }
        XCTAssertEqual(sut.code, .visible("world"))
    }

    @MainActor
    func test_code_goesToNoMoreCodesWhenFinished() async throws {
        let (renderer, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            renderer.subject.send("hi")
        }
        XCTAssertEqual(sut.code, .visible("hi"))

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            renderer.subject.send(completion: .finished)
        }
        XCTAssertEqual(sut.code, .finished)
    }

    @MainActor
    func test_code_goesToErrorWhenErrors() async throws {
        let (renderer, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            renderer.subject.send(completion: .failure(anyNSError()))
        }

        switch sut.code {
        case .error:
            break
        default:
            XCTFail("Unexpected output")
        }
    }

    @MainActor
    func test_hideCodeUntilNextUpdate_obfuscatesCode() async throws {
        let (_, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            sut.hideCodeUntilNextUpdate()
        }

        XCTAssertEqual(sut.code, .obfuscated)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (MockCodeRenderer, OTPCodePreviewViewModel) {
        let renderer = MockCodeRenderer()
        let viewModel = OTPCodePreviewViewModel(
            accountName: "any",
            issuer: "any",
            renderer: renderer
        )
        trackForMemoryLeaks(viewModel, file: file, line: line)
        return (renderer, viewModel)
    }

    private struct MockCodeRenderer: OTPCodeRenderer {
        let subject = PassthroughSubject<String, any Error>()
        func renderedCodePublisher() -> AnyPublisher<String, any Error> {
            subject.eraseToAnyPublisher()
        }
    }
}
