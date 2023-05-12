import Combine
import Foundation
import XCTest
@testable import OTPFeed

@MainActor
final class CodeTimerPeriodStateTests: XCTestCase {
    func test_init_initialStateIsNil() {
        let sut = makeSUT(pub: PassthroughSubject().eraseToAnyPublisher())

        XCTAssertNil(sut.state)
    }

    func test_recievePublish_assignsValuesToState() async throws {
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
        CodeTimerPeriodState(statePublisher: pub)
    }
}
