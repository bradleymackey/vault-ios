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

        try await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            try await sut.incrementCounter()
        }

        XCTAssertEqual(sut.isButtonEnabled, false)
    }

    @MainActor
    func test_isButtonEnabled_hasNoEffectIncrementingCounterMoreThanOnce() async throws {
        let (_, _, sut) = makeSUT()

        try await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            try await sut.incrementCounter()
        }

        // No mutation now!
        try await expectNoMutation(observable: sut, keyPath: \.isButtonEnabled) {
            try await sut.incrementCounter()
        }
    }

    @MainActor
    func test_isButtonEnabled_enablesAfterTimerCompletion() async throws {
        let (_, timer, sut) = makeSUT()

        try await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            try await sut.incrementCounter()
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

        try await expectSingleMutation(observable: sut, keyPath: \.isButtonEnabled) {
            try await sut.incrementCounter()
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
        let (codePublisher, _, sut) = makeSUT()
        let publisher = codePublisher.counterIncrementedPublisher()
            .collectFirst(1)

        let incrementOperations: [Void] = try await awaitPublisher(publisher) {
            try await sut.incrementCounter()
        }
        XCTAssertEqual(incrementOperations.count, 1)
    }

    @MainActor
    func test_incrementCounter_doesNotIncrementCounterWhileButtonDisabled() async throws {
        let (codePublisher, _, sut) = makeSUT()
        let publisher = codePublisher.counterIncrementedPublisher()
            .dropFirst() // the renderer publishes the first value right away, so ignore that
            .collectFirst(1)

        try await sut.incrementCounter() // disable button

        try await awaitNoPublish(publisher: publisher) {
            try await sut.incrementCounter()
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT() -> (HOTPCodePublisher, IntervalTimerMock, OTPCodeIncrementerViewModel) {
        let codePublisher = HOTPCodePublisher(hotpGenerator: .init(secret: Data()))
        let timer = IntervalTimerMock()
        let sut = OTPCodeIncrementerViewModel(
            id: .new(),
            codePublisher: codePublisher,
            timer: timer,
            initialCounter: 0,
            incrementerStore: VaultStoreHOTPIncrementerMock()
        )
        return (codePublisher, timer, sut)
    }
}

extension HOTPCodePublisher {
    func counterIncrementedPublisher() -> AnyPublisher<Void, any Error> {
        renderedCodePublisher().map { _ in }.eraseToAnyPublisher()
    }
}
