import Combine
import Foundation
import OTPFeed
import XCTest

final class CodePreviewViewModelTests: XCTestCase {
    func test_code_updatesWithCodes() async throws {
        let (renderer, sut) = makeSUT()
        let publisher = sut.$code.collectNext(2)

        let output = try await awaitPublisher(publisher) {
            renderer.subject.send("hello")
            renderer.subject.send("world")
        }
        XCTAssertEqual(output, [.visible("hello"), .visible("world")])
    }

    func test_code_goesToNoMoreCodesWhenFinished() async throws {
        let (renderer, sut) = makeSUT()
        let publisher = sut.$code.collectNext(2)

        let output = try await awaitPublisher(publisher) {
            renderer.subject.send("hi")
            renderer.subject.send(completion: .finished)
        }
        XCTAssertEqual(output, [.visible("hi"), .noMoreCodes])
    }

    func test_code_goesToNoErrorWhenErrors() async throws {
        let (renderer, sut) = makeSUT()
        let publisher = sut.$code.collectNext(2)

        let output = try await awaitPublisher(publisher) {
            renderer.subject.send("hi")
            renderer.subject.send(completion: .failure(anyNSError()))
        }
        let kind: [String] = output.map {
            switch $0 {
            case .error:
                return "error"
            default:
                return "other"
            }
        }
        XCTAssertEqual(kind, ["other", "error"])
    }

    // MARK: - Helpers

    private func makeSUT() -> (MockCodeRenderer, CodePreviewViewModel) {
        let renderer = MockCodeRenderer()
        let viewModel = CodePreviewViewModel(renderer: renderer)
        return (renderer, viewModel)
    }

    private struct MockCodeRenderer: OTPCodeRenderer {
        let subject = PassthroughSubject<String, Error>()
        func renderedCodePublisher() -> AnyPublisher<String, Error> {
            subject.eraseToAnyPublisher()
        }
    }
}
