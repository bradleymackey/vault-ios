import Combine
import Foundation
import OTPFeed
import TestHelpers
import XCTest

@MainActor
final class CodePreviewViewModelTests: XCTestCase {
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

    func test_hideCodeUntilNextUpdate_obfuscatesCode() async throws {
        let (_, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.code) {
            sut.hideCodeUntilNextUpdate()
        }

        XCTAssertEqual(sut.code, .obfuscated)
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (MockCodeRenderer, CodePreviewViewModel) {
        let renderer = MockCodeRenderer()
        let viewModel = CodePreviewViewModel(
            accountName: "any",
            issuer: "any",
            renderer: renderer
        )
        trackForMemoryLeaks(viewModel, file: file, line: line)
        return (renderer, viewModel)
    }

    private struct MockCodeRenderer: OTPCodeRenderer {
        let subject = PassthroughSubject<String, Error>()
        func renderedCodePublisher() -> AnyPublisher<String, Error> {
            subject.eraseToAnyPublisher()
        }
    }
}
