import Combine
import Foundation
import OTPFeed
import XCTest

@MainActor
final class CodeIncrementerViewModelTests: XCTestCase {
    func test_isButtonEnabled_isInitiallyTrue() {
        let (_, _, sut) = makeSUT()

        XCTAssertTrue(sut.isButtonEnabled)
    }

    func test_isButtonEnabled_becomesDisabledAfterIncrementing() async throws {
        let (_, _, sut) = makeSUT()
        let publisher = sut.$isButtonEnabled.collectNext(1)

        let values = try await awaitPublisher(publisher, when: {
            sut.incrementCounter()
        })
        XCTAssertEqual(values, [false])
    }

    func test_isButtonEnabled_hasNoEffectIncrementingCounterMoreThanOnce() async throws {
        let (_, _, sut) = makeSUT()
        let publisher = sut.$isButtonEnabled.collectNext(2) // there should only be 1 event

        await awaitNoPublish(publisher: publisher, when: {
            sut.incrementCounter()
            sut.incrementCounter()
            sut.incrementCounter()
            sut.incrementCounter()
        })
    }

    func test_isButtonEnabled_enablesAfterTimerCompletion() async throws {
        let (_, timer, sut) = makeSUT()
        let publisher = sut.$isButtonEnabled.collectNext(2)

        let values = try await awaitPublisher(publisher, when: {
            sut.incrementCounter()
            timer.finishTimer()
        })
        XCTAssertEqual(values, [false, true])
    }

    func test_isButtonEnabled_timerCompletingMultipleTimesHasNoEffect() async throws {
        let (_, timer, sut) = makeSUT()
        let publisher = sut.$isButtonEnabled.collectNext(3) // there should only be 2 events

        await awaitNoPublish(publisher: publisher, when: {
            sut.incrementCounter()
            timer.finishTimer()
            timer.finishTimer()
            timer.finishTimer()
            timer.finishTimer()
            timer.finishTimer()
        })
    }

    func test_incrementCounter_incrementsCounterWhileButtonEnabled() async throws {
        let (renderer, _, sut) = makeSUT()
        let publisher = renderer.counterIncrementedPublisher()
            .dropFirst() // the renderer publishes the first value right away, so ignore that
            .collectFirst(1)

        let incrementOperations: [Void] = try await awaitPublisher(publisher) {
            sut.incrementCounter()
        }
        XCTAssertEqual(incrementOperations.count, 1)
    }

    func test_incrementCounter_doesNotIncrementCounterWhileButtonDisabled() async throws {
        let (renderer, _, sut) = makeSUT()
        let publisher = renderer.counterIncrementedPublisher()
            .dropFirst() // the renderer publishes the first value right away, so ignore that
            .collectFirst(1)

        sut.incrementCounter() // disable button

        await awaitNoPublish(publisher: publisher) {
            sut.incrementCounter()
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> (HOTPCodeRenderer, MockIntervalTimer, CodeIncrementerViewModel) {
        let renderer = HOTPCodeRenderer(hotpGenerator: .init(secret: Data()))
        let timer = MockIntervalTimer()
        let sut = CodeIncrementerViewModel(
            hotpRenderer: renderer,
            timer: timer,
            initialCounter: 0
        )
        return (renderer, timer, sut)
    }
}

extension HOTPCodeRenderer {
    func counterIncrementedPublisher() -> AnyPublisher<Void, Error> {
        renderedCodePublisher().map { _ in }.eraseToAnyPublisher()
    }
}
