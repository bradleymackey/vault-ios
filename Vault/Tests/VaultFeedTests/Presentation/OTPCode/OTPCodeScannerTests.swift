import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeScannerTests: XCTestCase {
    @MainActor
    func test_init_initialStateIsDisabled() {
        let sut = makeSUT()

        XCTAssertEqual(sut.scanningState, .disabled)
    }

    @MainActor
    func test_startScanning_setsStateToStart() {
        let sut = makeSUT()

        sut.startScanning()

        XCTAssertEqual(sut.scanningState, .scanning)
    }

    @MainActor
    func test_disable_setsStateToDisabled() {
        let sut = makeSUT()

        sut.startScanning()
        sut.disable()

        XCTAssertEqual(sut.scanningState, .disabled)
    }

    @MainActor
    func test_scan_setsStateToInvalidForInvalidCode() {
        let timer = MockIntervalTimer()
        let sut = makeSUT(intervalTimer: timer)

        sut.scan(text: "invalid")

        XCTAssertEqual(sut.scanningState, .invalidCodeScanned)
    }

    @MainActor
    func test_scan_returnsToScanningAfterInvalidCodeFailure() {
        let timer = MockIntervalTimer()
        let sut = makeSUT(intervalTimer: timer)

        sut.scan(text: "invalid")
        timer.finishTimer()

        XCTAssertEqual(sut.scanningState, .scanning)
    }

    @MainActor
    func test_scan_successSetsStateToSuccess() {
        let timer = MockIntervalTimer()
        let sut = makeSUT(intervalTimer: timer)

        sut.scan(text: OTPAuthURI.exampleCodeString)

        XCTAssertEqual(sut.scanningState, .success)
    }

    @MainActor
    func test_scan_publishesScannedCodeAfterDelay() async throws {
        let timer = MockIntervalTimer()
        let sut = makeSUT(intervalTimer: timer)

        sut.scan(text: OTPAuthURI.exampleCodeString)

        let exp = expectation(description: "Wait for code")
        let results = sut.navigateToScannedCodePublisher().collectFirst(1).sink { _ in
            exp.fulfill()
        }

        timer.finishTimer()

        await fulfillment(of: [exp], timeout: 1.0)
        results.cancel()
    }
}

extension OTPCodeScannerTests {
    @MainActor
    private func makeSUT(
        intervalTimer: MockIntervalTimer = MockIntervalTimer(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeScanner {
        let sut = OTPCodeScanner(intervalTimer: intervalTimer)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
