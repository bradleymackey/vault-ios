import Combine
import Foundation
import TestHelpers
import VaultFeed
import XCTest

@MainActor
final class OTPCodeIncrementerViewModelTests: XCTestCase {
    func test_isButtonEnabled_isInitiallyTrue() {
        let (_, _, sut) = makeSUT()

        XCTAssertTrue(sut.isButtonEnabled)
    }

    func test_isButtonEnabled_becomesDisabledAfterIncrementing() async throws {
        let (_, _, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            sut.incrementCounter()
        }

        XCTAssertEqual(sut.isButtonEnabled, false)
    }

    func test_isButtonEnabled_hasNoEffectIncrementingCounterMoreThanOnce() async throws {
        let (_, _, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            sut.incrementCounter()
        }

        // No mutation now!
        await expectNoMutation(observable: sut, keyPath: \.isButtonEnabled) {
            sut.incrementCounter()
        }
    }

    func test_isButtonEnabled_enablesAfterTimerCompletion() async throws {
        let (_, timer, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            sut.incrementCounter()
        }
        XCTAssertEqual(sut.isButtonEnabled, false)

        await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            timer.finishTimer()
        }
        XCTAssertEqual(sut.isButtonEnabled, true)
    }

    func test_isButtonEnabled_timerCompletingMultipleTimesHasNoEffect() async throws {
        let (_, timer, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            sut.incrementCounter()
        }
        XCTAssertEqual(sut.isButtonEnabled, false)

        await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            timer.finishTimer()
        }
        XCTAssertEqual(sut.isButtonEnabled, true)

        await expectNoMutation(observable: sut, keyPath: \.isButtonEnabled) {
            timer.finishTimer()
        }
    }

    func test_incrementCounter_incrementsCounterWhileButtonEnabled() async throws {
        let (renderer, _, sut) = makeSUT()
        let publisher = renderer.counterIncrementedPublisher()
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

    private func makeSUT() -> (HOTPCodeRenderer, MockIntervalTimer, OTPCodeIncrementerViewModel) {
        let renderer = HOTPCodeRenderer(hotpGenerator: .init(secret: Data()))
        let timer = MockIntervalTimer()
        let sut = OTPCodeIncrementerViewModel(
            hotpRenderer: renderer,
            timer: timer,
            initialCounter: 0
        )
        return (renderer, timer, sut)
    }
}

extension HOTPCodeRenderer {
    func counterIncrementedPublisher() -> AnyPublisher<Void, any Error> {
        renderedCodePublisher().map { _ in }.eraseToAnyPublisher()
    }
}
