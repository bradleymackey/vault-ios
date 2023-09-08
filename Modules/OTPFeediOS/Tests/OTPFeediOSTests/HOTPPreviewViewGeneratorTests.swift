import Foundation
import OTPCore
import OTPFeed
import OTPFeediOS
import SwiftUI
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
    private typealias SUT = HOTPPreviewViewGenerator<MockHOTPViewFactory>
    private func makeSUT() -> (SUT, MockIntervalTimer) {
        let factory = MockHOTPViewFactory()
        let timer = MockIntervalTimer()
        let sut = HOTPPreviewViewGenerator(viewFactory: factory, timer: timer)
        return (sut, timer)
    }

    private func anyHOTPCode() -> HOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }

    private final class MockHOTPViewFactory: HOTPPreviewViewFactory {
        func makeHOTPView(
            viewModel _: CodePreviewViewModel,
            incrementer _: CodeIncrementerViewModel,
            behaviour _: OTPViewBehaviour?
        ) -> some View {
            Text("Hello")
        }
    }
}
