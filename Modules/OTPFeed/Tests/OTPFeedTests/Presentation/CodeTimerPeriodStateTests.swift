import Combine
import Foundation
import OTPCore
import OTPFeed
import TestHelpers
import XCTest

@MainActor
final class CodeTimerPeriodStateTests: XCTestCase {
    func test_init_initialAnimationStateIsFrozen() {
        let sut = makeSUT(pub: PassthroughSubject().eraseToAnyPublisher())

        XCTAssertEqual(sut.animationState, .freeze(fraction: 0))
    }

    func test_animationState_assignsValueToState() async throws {
        let valueSubject = PassthroughSubject<OTPTimerState, Never>()
        let sut = makeSUT(pub: valueSubject.eraseToAnyPublisher())

        let initialState = OTPTimerState(startTime: 69, endTime: 420)
        await expectSingleObservableAccess(on: sut, keyPath: \.animationState) {
            valueSubject.send(initialState)
        }

        XCTAssertEqual(sut.animationState, .animate(initialState))
    }

    // MARK: - Helpers

    private func makeSUT(pub: AnyPublisher<OTPTimerState, Never>) -> CodeTimerPeriodState {
        CodeTimerPeriodState(clock: EpochClock(makeCurrentTime: { 100 }), statePublisher: pub)
    }
}
