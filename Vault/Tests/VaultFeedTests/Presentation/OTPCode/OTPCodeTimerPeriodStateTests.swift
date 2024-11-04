import Combine
import Foundation
import TestHelpers
import Testing
import VaultCore
import VaultFeed

@MainActor
struct OTPCodeTimerPeriodStateTests {
    @Test
    func init_initialAnimationStateIsFrozen() {
        let sut = makeSUT(pub: PassthroughSubject().eraseToAnyPublisher())

        #expect(sut.animationState == .freeze(fraction: 0))
    }

    @Test
    func animationState_assignsValueToState() async throws {
        let valueSubject = PassthroughSubject<OTPCodeTimerState, Never>()
        let sut = makeSUT(pub: valueSubject.eraseToAnyPublisher())

        let initialState = OTPCodeTimerState(startTime: 69, endTime: 420)
        try await sut.waitForChange(to: \.animationState) {
            valueSubject.send(initialState)
        }

        #expect(sut.animationState == .animate(initialState))
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(pub: AnyPublisher<OTPCodeTimerState, Never>) -> OTPCodeTimerPeriodState {
        OTPCodeTimerPeriodState(statePublisher: pub)
    }
}
