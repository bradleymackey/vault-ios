import Combine
import CryptoEngine
import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class TOTPCodeRendererTests: XCTestCase {
    func test_renderedCodePublisher_publishesCodesOnEpochSecondsTick() async throws {
        let (timer, sut) = makeSUT()

        let publisher = sut.renderedCodePublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(OTPTimerState(startTime: 1_111_111_109, endTime: 1_111_111_109 + 1))
            timer.subject.send(OTPTimerState(startTime: 1_111_111_111, endTime: 1_111_111_111 + 1))
            timer.subject.send(OTPTimerState(startTime: 2_000_000_000, endTime: 2_000_000_000 + 1))
        })
        XCTAssertEqual(values, [
            "07081804",
            "14050471",
            "69279037",
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (MockCodeTimerUpdater, some OTPCodeRenderer) {
        let timer = MockCodeTimerUpdater()
        let sut = TOTPCodeRenderer(timer: timer, totpGenerator: fixedGenerator(timeInterval: 30))
        trackForMemoryLeaks(sut, file: file, line: line)
        return (timer, sut)
    }

    private func fixedGenerator(timeInterval: UInt64) -> TOTPGenerator {
        let hotpGenerator = HOTPGenerator(secret: hotpRfcSecretData(), digits: .eight, algorithm: .sha1)
        return TOTPGenerator(generator: hotpGenerator, timeInterval: timeInterval)
    }
}
