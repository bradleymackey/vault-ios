import Combine
import CryptoEngine
import Foundation
import OTPCore
import TestHelpers
import XCTest
@testable import OTPFeed

final class TOTPCodeRendererTests: XCTestCase {
    func test_renderedCodePublisher_publishesCodesOnEpochSecondsTick() async throws {
        let (timer, sut) = makeSUT(digits: 8)

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

    func test_renderedCodePublisher_rendersZeroLengthCodes() async throws {
        let (timer, sut) = makeSUT(digits: 0)

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(OTPTimerState(startTime: 1_111_111_109, endTime: 1_111_111_109 + 1))
            timer.subject.send(OTPTimerState(startTime: 1_111_111_111, endTime: 1_111_111_111 + 1))
        })
        XCTAssertEqual(values, [
            "",
            "",
        ])
    }

    func test_renderedCodePublisher_rendersCodesWithLeadingZeros() async throws {
        let (timer, sut) = makeSUT(digits: 20)

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(OTPTimerState(startTime: 1_111_111_109, endTime: 1_111_111_109 + 1))
            timer.subject.send(OTPTimerState(startTime: 1_111_111_111, endTime: 1_111_111_111 + 1))
        })
        XCTAssertEqual(values, [
            "00000000000907081804",
            "00000000000414050471",
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        digits: UInt16,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (MockCodeTimerUpdater, some OTPCodeRenderer) {
        let timer = MockCodeTimerUpdater()
        let sut = TOTPCodeRenderer(timer: timer, totpGenerator: fixedGenerator(timeInterval: 30, digits: digits))
        trackForMemoryLeaks(sut, file: file, line: line)
        return (timer, sut)
    }

    private func fixedGenerator(timeInterval: UInt64, digits: UInt16) -> TOTPGenerator {
        let hotpGenerator = HOTPGenerator(secret: hotpRfcSecretData(), digits: digits, algorithm: .sha1)
        return TOTPGenerator(generator: hotpGenerator, timeInterval: timeInterval)
    }
}
