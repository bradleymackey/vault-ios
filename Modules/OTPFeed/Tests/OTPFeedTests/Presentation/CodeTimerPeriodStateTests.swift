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

    func test_precondition_CurrentValueSubjectSendsValueOnSubscriber() async throws {
        // Precondition for test_state_isSetImmediatelyFromInitialValueOfPublisherOnInit

        let subject = CurrentValueSubject<Int, Never>(100)

        let exp = expectation(description: "Wait for initial publish")
        let handle = subject.sink { value in
            XCTAssertEqual(value, 100)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: 1.0)
        handle.cancel()
    }

    // TODO: fix flake!
    func test_state_isSetImmediatelyFromInitialValueOfPublisherOnInit() async throws {
        let initialState = OTPTimerState(startTime: 69, endTime: 420)
        // CurrentValueSubject publishes immediately on subscription.
        let initiallyPublishingPublisher = CurrentValueSubject<OTPTimerState, Never>(initialState)
            .eraseToAnyPublisher()
        let sut = makeSUT(pub: initiallyPublishingPublisher)

        let recieved = sut.$state.collectFirst(1)

        let values = try await awaitPublisher(recieved) {
            // noop
        }

        XCTAssertEqual(values, [initialState])
    }

    func test_state_assignsValuesToState() async throws {
        let publisher = PassthroughSubject<OTPTimerState, Never>()
        let sut = makeSUT(pub: publisher.eraseToAnyPublisher())

        let recieved = sut.$state.collectNext(3)

        let values = try await awaitPublisher(recieved) {
            publisher.send(OTPTimerState(startTime: 69, endTime: 420))
            publisher.send(OTPTimerState(startTime: 800, endTime: 900))
            publisher.send(OTPTimerState(startTime: 900, endTime: 1000))
        }
        XCTAssertEqual(values, [
            OTPTimerState(startTime: 69, endTime: 420),
            OTPTimerState(startTime: 800, endTime: 900),
            OTPTimerState(startTime: 900, endTime: 1000),
        ])
    }

    // MARK: - Helpers

    private func makeSUT(pub: AnyPublisher<OTPTimerState, Never>) -> CodeTimerPeriodState {
        CodeTimerPeriodState(clock: EpochClock(makeCurrentTime: { 100 }), statePublisher: pub)
    }
}
