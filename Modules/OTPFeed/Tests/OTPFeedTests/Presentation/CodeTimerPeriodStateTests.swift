import Combine
import Foundation
import OTPCore
import OTPFeed
import XCTest

@MainActor
final class CodeTimerPeriodStateTests: XCTestCase {
    func test_init_initialStateIsNil() {
        let sut = makeSUT(pub: PassthroughSubject().eraseToAnyPublisher())

        XCTAssertNil(sut.state)
    }

    func test_state_assignsValueToState() async throws {
        let valueSubject = PassthroughSubject<OTPTimerState, Never>()
        let sut = makeSUT(pub: valueSubject.eraseToAnyPublisher())

        let exp = expectation(description: "Wait for state change")
        withObservationTracking {
            let _ = sut.state
        } onChange: {
            exp.fulfill()
        }

        let initialState = OTPTimerState(startTime: 69, endTime: 420)
        valueSubject.send(initialState)

        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertEqual(sut.state, initialState)
    }

    // MARK: - Helpers

    private func makeSUT(pub: AnyPublisher<OTPTimerState, Never>) -> CodeTimerPeriodState {
        CodeTimerPeriodState(clock: EpochClock(makeCurrentTime: { 100 }), statePublisher: pub)
    }
}
