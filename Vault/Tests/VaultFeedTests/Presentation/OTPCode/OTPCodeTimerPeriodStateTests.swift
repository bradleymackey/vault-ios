import Combine
import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeTimerPeriodStateTests: XCTestCase {
    func test_init_initialAnimationStateIsFrozen() {
        let sut = makeSUT(pub: PassthroughSubject().eraseToAnyPublisher())

        XCTAssertEqual(sut.animationState, .freeze(fraction: 0))
    }

    func test_animationState_assignsValueToState() async throws {
        let valueSubject = PassthroughSubject<OTPCodeTimerState, Never>()
        let sut = makeSUT(pub: valueSubject.eraseToAnyPublisher())

        let initialState = OTPCodeTimerState(startTime: 69, endTime: 420)
        await expectSingleMutation(observable: sut, keyPath: \.animationState) {
            valueSubject.send(initialState)
        }

        XCTAssertEqual(sut.animationState, .animate(initialState))
    }

    // MARK: - Helpers

    private func makeSUT(pub: AnyPublisher<OTPCodeTimerState, Never>) -> OTPCodeTimerPeriodState {
        OTPCodeTimerPeriodState(clock: EpochClock(makeCurrentTime: { 100 }), statePublisher: pub)
    }
}
