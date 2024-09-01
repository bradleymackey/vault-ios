import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class SingleCodeScannerTests: XCTestCase {
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
        let timer = IntervalTimerMock()
        let sut = makeSUT(intervalTimer: timer, mapper: { _ in
            throw anyNSError()
        })

        sut.scan(text: "any")

        XCTAssertEqual(sut.scanningState, .invalidCodeScanned)
    }

    @MainActor
    func test_scan_returnsToScanningAfterInvalidCodeFailure() async {
        let timer = IntervalTimerMock()
        let sut = makeSUT(intervalTimer: timer, mapper: { _ in
            throw anyNSError()
        })

        sut.scan(text: "invalid")
        await timer.finishTimer()

        XCTAssertEqual(sut.scanningState, .scanning)
    }

    @MainActor
    func test_scan_successSetsStateToSuccess() {
        let timer = IntervalTimerMock()
        let sut = makeSUT(intervalTimer: timer)

        sut.scan(text: OTPAuthURI.exampleCodeString)

        XCTAssertEqual(sut.scanningState, .success)
    }

    @MainActor
    func test_scan_publishesScannedCodeAfterDelay() async throws {
        let timer = IntervalTimerMock()
        let sut = makeSUT(intervalTimer: timer)

        sut.scan(text: OTPAuthURI.exampleCodeString)

        let exp = expectation(description: "Wait for code")
        let results = sut.itemScannedPublisher().collectFirst(1).sink { _ in
            exp.fulfill()
        }

        await timer.finishTimer()

        await fulfillment(of: [exp], timeout: 1.0)
        results.cancel()
    }
}

extension SingleCodeScannerTests {
    private struct DummyModel {}

    @MainActor
    private func makeSUT(
        intervalTimer: IntervalTimerMock = IntervalTimerMock(),
        mapper: @escaping (String) throws -> DummyModel = { _ in DummyModel() },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SingleCodeScanner<DummyModel> {
        let sut = SingleCodeScanner(intervalTimer: intervalTimer, mapper: mapper)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
