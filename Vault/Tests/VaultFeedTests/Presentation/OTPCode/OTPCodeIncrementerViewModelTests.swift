import Combine
import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeIncrementerViewModelTests: XCTestCase {
    @MainActor
    func test_isButtonEnabled_isInitiallyTrue() {
        let (_, _, sut) = makeSUT()

        XCTAssertTrue(sut.isButtonEnabled)
    }

    @MainActor
    func test_isButtonEnabled_becomesDisabledAfterIncrementing() async throws {
        let (_, _, sut) = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            sut.incrementCounter()
        }

        XCTAssertEqual(sut.isButtonEnabled, false)
    }

    @MainActor
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

    @MainActor
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

    @MainActor
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

    @MainActor
    func test_incrementCounter_incrementsCounterWhileButtonEnabled() async throws {
        let (renderer, _, sut) = makeSUT()
        let publisher = renderer.counterIncrementedPublisher()
            .collectFirst(1)

        let incrementOperations: [Void] = try await awaitPublisher(publisher) {
            sut.incrementCounter()
        }
        XCTAssertEqual(incrementOperations.count, 1)
    }

    @MainActor
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

    @MainActor
    private func makeSUT() -> (HOTPCodeRenderer, IntervalTimerMock, OTPCodeIncrementerViewModel) {
        let renderer = HOTPCodeRenderer(hotpGenerator: .init(secret: Data()))
        let timer = IntervalTimerMock()
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
