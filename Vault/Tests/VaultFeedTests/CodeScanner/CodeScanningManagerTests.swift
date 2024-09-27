import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class CodeScanningManagerTests: XCTestCase {
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
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.invalidCode) }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")

        XCTAssertEqual(sut.scanningState, .failure(.temporary))
    }

    @MainActor
    func test_scan_returnsToScanningAfterInvalidCodeFailure() async {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.invalidCode) }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")
        await expectSingleMutation(observable: sut, keyPath: \.scanningState) {
            await timer.finishTimer()
        }

        XCTAssertEqual(sut.scanningState, .scanning)
    }

    @MainActor
    func test_scan_successSetsStateToSuccess() {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.success) }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")

        XCTAssertEqual(sut.scanningState, .success(.temporary))
    }

    @MainActor
    func test_scan_publishesScannedCodeAfterDelayWhenCompletedScanning() async throws {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .endScanning(.dataRetrieved("any")) }
        let sut = makeSUT(intervalTimer: timer)
        sut.startScanning()

        sut.scan(text: "any")

        let exp = expectation(description: "Wait for code")
        let results = sut.itemScannedPublisher().collectFirst(1).sink { _ in
            exp.fulfill()
        }

        await timer.finishTimer()

        await fulfillment(of: [exp], timeout: 1.0)
        results.cancel()

        XCTAssertEqual(sut.scanningState, .success(.complete))
    }

    @MainActor
    func test_scan_unrecoverableErrorSetsStateToDataError() async throws {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .endScanning(.unrecoverableError) }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")
        await expectNoMutation(observable: sut, keyPath: \.scanningState) {
            await timer.finishTimer()
        }
        XCTAssertEqual(sut.scanningState, .failure(.unrecoverable))
    }

    @MainActor
    func test_scan_returnsToScanningAfterDelayWhenContinueScanningReturned() async throws {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.success) }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")

        await expectSingleMutation(observable: sut, keyPath: \.scanningState) {
            await timer.finishTimer()
        }

        XCTAssertEqual(sut.scanningState, .scanning)
    }

    @MainActor
    func test_scan_scanningStateUnchangedIfShouldIgnore() async throws {
        let timer = IntervalTimerMock()
        let handler = CodeScanningHandlerMock()
        handler.decodeHandler = { _ in .continueScanning(.ignore) }
        let sut = makeSUT(intervalTimer: timer, handler: handler)
        sut.startScanning()

        sut.scan(text: "any")
        await expectNoMutation(observable: sut, keyPath: \.scanningState) {
            await timer.finishTimer()
        }
        XCTAssertEqual(sut.scanningState, .scanning)
    }
}

extension CodeScanningManagerTests {
    @MainActor
    private func makeSUT(
        intervalTimer: IntervalTimerMock = IntervalTimerMock(),
        handler: CodeScanningHandlerMock = .defaultCompletedScanning,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CodeScanningManager<CodeScanningHandlerMock> {
        let sut = CodeScanningManager(intervalTimer: intervalTimer, handler: handler)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(handler, file: file, line: line)
        return sut
    }
}

extension CodeScanningHandlerMock {
    fileprivate static var defaultCompletedScanning: CodeScanningHandlerMock {
        let mock = CodeScanningHandlerMock()
        mock.decodeHandler = { _ in .endScanning(.dataRetrieved("any")) }
        return mock
    }
}
