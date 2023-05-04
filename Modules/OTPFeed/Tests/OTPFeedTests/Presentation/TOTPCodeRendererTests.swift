import Combine
import CryptoEngine
import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class TOTPCodeRendererTests: XCTestCase {
    func test_renderedCodePublisher_publishesInitialCodeBaseOnCurrentTimeValue() async throws {
        let (_, sut) = makeSUT(initialTime: 59)

        let publisher = sut.renderedCodePublisher().collectFirst(1)

        let values = try await awaitPublisher(publisher, when: {})
        XCTAssertEqual(values, ["94287082"])
    }

    func test_renderedCodePublisher_publishesCodesOnEpochSecondsTick() async throws {
        let (clock, sut) = makeSUT(initialTime: 59)

        let publisher = sut.renderedCodePublisher().collectFirst(4)

        let values = try await awaitPublisher(publisher, when: {
            clock.send(time: 1_111_111_109)
            clock.send(time: 1_111_111_111)
            clock.send(time: 2_000_000_000)
        })
        XCTAssertEqual(values, [
            "94287082", // from initial time
            "07081804",
            "14050471",
            "69279037",
        ])
    }

    // MARK: - Helpers

    private func makeSUT(initialTime: Double) -> (MockEpochClock, some OTPCodeRenderer) {
        let clock = MockEpochClock(initialTime: initialTime)
        let sut = TOTPCodeRenderer(clock: clock, totpGenerator: fixedGenerator(timeInterval: 30))
        return (clock, sut)
    }

    private func fixedGenerator(timeInterval: UInt64) -> TOTPGenerator {
        let hotpGenerator = HOTPGenerator(secret: hotpRfcSecretData(), digits: .eight, algorithm: .sha1)
        return TOTPGenerator(generator: hotpGenerator, timeInterval: timeInterval)
    }
}
