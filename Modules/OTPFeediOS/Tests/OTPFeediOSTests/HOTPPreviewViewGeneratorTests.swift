import Foundation
import OTPCore
import OTPFeediOS
import XCTest

@MainActor
final class HOTPPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let (_, timer) = makeSUT()

        XCTAssertEqual(timer.recordedWaitedIntervals, [])
    }

    func test_makeOTPView_generatesViews() {
        let (sut, _) = makeSUT()

        let view = sut.makeOTPView(id: UUID(), code: anyHOTPCode(), behaviour: nil)

        XCTAssertNotNil(view)
    }

    func test_currentCode_isNilIfCacheEmpty() {
        let (sut, _) = makeSUT()

        let code = sut.currentCode(id: UUID())

        XCTAssertNil(code)
    }

    func test_currentCode_isValueIfCodeHasBeenGenerated() {
        let (sut, _) = makeSUT()

        let code = sut.currentCode(id: UUID())

        XCTAssertNil(code)
    }
}

extension HOTPPreviewViewGeneratorTests {
    private func makeSUT() -> (HOTPPreviewViewGenerator, MockIntervalTimer) {
        let timer = MockIntervalTimer()
        let sut = HOTPPreviewViewGenerator(timer: timer)
        return (sut, timer)
    }

    private func anyHOTPCode() -> HOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }
}
