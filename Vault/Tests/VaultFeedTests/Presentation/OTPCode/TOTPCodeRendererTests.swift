import Combine
import CryptoEngine
import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class TOTPCodeRendererTests: XCTestCase {
    @MainActor
    func test_renderedCodePublisher_publishesCodesOnEpochSecondsTick() async throws {
        let (timer, sut) = makeSUT(digits: 8)

        let publisher = sut.renderedCodePublisher().collectFirst(3)

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(OTPCodeTimerState(startTime: 1_111_111_109, endTime: 1_111_111_109 + 1))
            timer.subject.send(OTPCodeTimerState(startTime: 1_111_111_111, endTime: 1_111_111_111 + 1))
            timer.subject.send(OTPCodeTimerState(startTime: 2_000_000_000, endTime: 2_000_000_000 + 1))
        })
        XCTAssertEqual(values, [
            "07081804",
            "14050471",
            "69279037",
        ])
    }

    @MainActor
    func test_renderedCodePublisher_rendersZeroLengthCodes() async throws {
        let (timer, sut) = makeSUT(digits: 0)

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(OTPCodeTimerState(startTime: 1_111_111_109, endTime: 1_111_111_109 + 1))
            timer.subject.send(OTPCodeTimerState(startTime: 1_111_111_111, endTime: 1_111_111_111 + 1))
        })
        XCTAssertEqual(values, [
            "",
            "",
        ])
    }

    @MainActor
    func test_renderedCodePublisher_rendersCodesWithLeadingZeros() async throws {
        let (timer, sut) = makeSUT(digits: 20)

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            timer.subject.send(OTPCodeTimerState(startTime: 1_111_111_109, endTime: 1_111_111_109 + 1))
            timer.subject.send(OTPCodeTimerState(startTime: 1_111_111_111, endTime: 1_111_111_111 + 1))
        })
        XCTAssertEqual(values, [
            "00000000000907081804",
            "00000000000414050471",
        ])
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        digits: UInt16,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (MockOTPCodeTimerUpdater, some OTPCodeRenderer) {
        let timer = MockOTPCodeTimerUpdater()
        let sut = TOTPCodeRenderer(timer: timer, totpGenerator: fixedGenerator(timeInterval: 30, digits: digits))
        trackForMemoryLeaks(sut, file: file, line: line)
        return (timer, sut)
    }

    private func fixedGenerator(timeInterval: UInt64, digits: UInt16) -> TOTPGenerator {
        let hotpGenerator = HOTPGenerator(secret: hotpRfcSecretData(), digits: digits, algorithm: .sha1)
        return TOTPGenerator(generator: hotpGenerator, timeInterval: timeInterval)
    }
}
