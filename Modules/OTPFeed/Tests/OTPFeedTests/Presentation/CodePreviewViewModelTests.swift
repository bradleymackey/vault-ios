import Combine
import Foundation
import OTPFeed
import XCTest

final class CodePreviewViewModelTests: UnitTestCase {
    func test_code_updatesWithCodes() {
        let (renderer, sut) = makeSUT()
        let expectation = sut.$code.recordPublished(numberOfRecords: 2)

        renderer.subject.send("hello")
        renderer.subject.send("world")

        let values = expectation.waitAndCollectRecords()
        let mappedValues: [CodePreviewViewModel.VisibleCode?] = values.map {
            switch $0 {
            case let .value(output):
                return output
            default:
                return nil
            }
        }
        XCTAssertEqual(mappedValues, [.visible("hello"), .visible("world")])
    }

    func test_code_goesToNoMoreCodesWhenFinished() {
        let (renderer, sut) = makeSUT()
        let expectation = sut.$code.recordPublished(numberOfRecords: 2)

        renderer.subject.send("hello")
        renderer.subject.send("world")
        renderer.subject.send(completion: .finished)

        let values = expectation.waitAndCollectRecords()
        let mappedValues: [String?] = values.map {
            switch $0 {
            case let .value(v):
                switch v {
                case .noMoreCodes:
                    return "no more codes"
                default:
                    return "value"
                }
            default:
                return nil
            }
        }
        XCTAssertEqual(mappedValues, ["value", "value", "no more codes"])
    }

    func test_code_goesToNoErrorWhenErrors() {
        let (renderer, sut) = makeSUT()
        let expectation = sut.$code.recordPublished(numberOfRecords: 2)

        renderer.subject.send("hello")
        renderer.subject.send("world")
        renderer.subject.send(completion: .failure(anyNSError()))

        let values = expectation.waitAndCollectRecords()
        let mappedValues: [String?] = values.map {
            switch $0 {
            case let .value(v):
                switch v {
                case .error:
                    return "error"
                default:
                    return "value"
                }
            default:
                return nil
            }
        }
        XCTAssertEqual(mappedValues, ["value", "value", "error"])
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
