import Foundation
import OTPFeed
import XCTest

@MainActor
final class CodeIncrementerViewModelTests: XCTestCase {
    func test_isButtonEnabled_isInitiallyTrue() {
        let (_, sut) = makeSUT()

        XCTAssertTrue(sut.isButtonEnabled)
    }

    func test_isButtonEnabled_becomesDisabledAfterIncrementing() async throws {
        let (_, sut) = makeSUT()
        let publisher = sut.$isButtonEnabled.collectNext(1)

        let values = try await awaitPublisher(publisher, when: {
            sut.incrementCounter()
        })
        XCTAssertEqual(values, [false])
    }

    func test_isButtonEnabled_hasNoEffectIncrementingCounterMoreThanOnce() async throws {
        let (_, sut) = makeSUT()
        let publisher = sut.$isButtonEnabled.collectNext(2) // there should only be 1 event

        await awaitNoPublish(publisher: publisher, when: {
            sut.incrementCounter()
            sut.incrementCounter()
            sut.incrementCounter()
            sut.incrementCounter()
        })
    }

    func test_isButtonEnabled_enablesAfterTimerCompletion() async throws {
        let (timer, sut) = makeSUT()
        let publisher = sut.$isButtonEnabled.collectNext(2)

        let values = try await awaitPublisher(publisher, when: {
            sut.incrementCounter()
            timer.finishTimer()
        })
        XCTAssertEqual(values, [false, true])
    }

    func test_isButtonEnabled_timerCompletingMultipleTimesHasNoEffect() async throws {
        let (timer, sut) = makeSUT()
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

    // MARK: - Helpers

    private func makeSUT() -> (MockIntervalTimer, CodeIncrementerViewModel<MockIntervalTimer>) {
        let timer = MockIntervalTimer()
        let sut = CodeIncrementerViewModel(
            hotpRenderer: HOTPCodeRenderer(hotpGenerator: .init(secret: Data()), initialCounter: 0),
            timer: timer,
            initialCounter: 0
        )
        return (timer, sut)
    }
}
