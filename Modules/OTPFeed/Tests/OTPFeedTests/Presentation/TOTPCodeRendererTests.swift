import Combine
import CombineTestExtensions
import CryptoEngine
import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class TOTPCodeRendererTests: XCTestCase {
    func test_renderedCodePublisher_publishesInitialCodeBaseOnCurrentTimeValue() throws {
        let (_, sut) = makeSUT(initialTime: 59)

        let publisher = sut.renderedCodePublisher()
            .record(scheduler: TestScheduler(), numberOfRecords: 1)

        let values = publisher.waitAndCollectRecords()
        XCTAssertEqual(values, [
            .value("94287082"), // from initial time
        ])
    }

    func test_renderedCodePublisher_publishesCodesOnEpochSecondsTick() throws {
        let (clock, sut) = makeSUT(initialTime: 59)

        let publisher = sut.renderedCodePublisher()
            .record(scheduler: TestScheduler(), numberOfRecords: 3)

        clock.send(time: 1_111_111_109)
        clock.send(time: 1_111_111_111)
        clock.send(time: 2_000_000_000)

        let values = publisher.waitAndCollectRecords()
        XCTAssertEqual(values, [
            .value("94287082"), // from initial time
            .value("07081804"),
            .value("14050471"),
            .value("69279037"),
        ])
    }

    // MARK: - Helpers

    private func makeSUT(initialTime: UInt64) -> (MockEpochClock, some OTPCodeRenderer) {
        let clock = MockEpochClock(initialTime: initialTime)
        let sut = TOTPCodeRenderer(clock: clock, totpGenerator: fixedGenerator(timeInterval: 30))
        return (clock, sut)
    }

    private func fixedGenerator(timeInterval: UInt64) -> TOTPGenerator {
        let hotpGenerator = HOTPGenerator(secret: hotpRfcSecretData(), digits: .eight, algorithm: .sha1)
        return TOTPGenerator(generator: hotpGenerator, timeInterval: timeInterval)
    }

    private struct MockEpochClock: EpochClock {
        private let publisher: CurrentValueSubject<UInt64, Never>
        init(initialTime: UInt64) {
            publisher = CurrentValueSubject<UInt64, Never>(initialTime)
        }

        func send(time: UInt64) {
            publisher.send(time)
        }

        func secondsPublisher() -> AnyPublisher<UInt64, Never> {
            publisher.eraseToAnyPublisher()
        }

        var currentTime: UInt64 {
            publisher.value
        }
    }
}
