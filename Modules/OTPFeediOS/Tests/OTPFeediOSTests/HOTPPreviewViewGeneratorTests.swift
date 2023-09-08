import Foundation
import OTPCore
import OTPFeed
import OTPFeediOS
import SwiftUI
import TestHelpers
import XCTest

@MainActor
final class HOTPPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let (_, timer, _) = makeSUT()

        XCTAssertEqual(timer.recordedWaitedIntervals, [])
    }

    func test_makeOTPView_generatesViews() throws {
        let (sut, _, _) = makeSUT()

        let view = sut.makeOTPView(id: UUID(), code: anyHOTPCode(), behaviour: nil)

        let foundText = try view.inspect().text()
        let string = try foundText.string()
        XCTAssertEqual(string, "Hello, world")
    }

    func test_makeOTPView_viewModelsAreInitiallyObfuscated() {
        let (sut, _, factory) = makeSUT()
        var viewModels = [CodePreviewViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewExecuted = { viewModel, _, _ in
            viewModels.append(viewModel)
            group.leave()
        }

        let id = UUID()
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)

        _ = group.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(viewModels.count, 2)
        XCTAssertTrue(viewModels.allSatisfy { $0.code == .obfuscated })
    }

    func test_makeOTPView_returnsSameViewModelInstanceUsingCachedViewModels() {
        let (sut, _, factory) = makeSUT()
        var viewModels = [CodePreviewViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewExecuted = { viewModel, _, _ in
            viewModels.append(viewModel)
            group.leave()
        }

        let id = UUID()
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)

        _ = group.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    func test_makeOTPView_returnsSameIncrementerInstanceUsingCachedViewModels() {
        let (sut, _, factory) = makeSUT()
        var viewModels = [CodeIncrementerViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewExecuted = { _, incrementer, _ in
            viewModels.append(incrementer)
            group.leave()
        }

        let id = UUID()
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)

        _ = group.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    func test_currentCode_isNilIfCacheEmpty() {
        let (sut, _, _) = makeSUT()

        let code = sut.currentCode(id: UUID())

        XCTAssertNil(code)
    }

    func test_currentCode_isValueIfCodeHasBeenGenerated() {
        let (sut, _, _) = makeSUT()

        let code = sut.currentCode(id: UUID())

        XCTAssertNil(code)
    }

    func test_hideAllCodesUntilNextUpdate_marksCachedViewModelsAsObfuscated() {
        let (sut, _, factory) = makeSUT()
        var viewModels = [CodePreviewViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewExecuted = { viewModel, _, _ in
            viewModels.append(viewModel)
            group.leave()
        }

        let id = UUID()
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)
        group.enter()
        _ = sut.makeOTPView(id: id, code: anyHOTPCode(), behaviour: nil)

        _ = group.wait(timeout: .now() + .seconds(1))

        for viewModel in viewModels {
            viewModel.update(code: .visible("1234"))
        }

        XCTAssertTrue(viewModels.allSatisfy { $0.code != .obfuscated })

        sut.hideAllCodesUntilNextUpdate()

        XCTAssertTrue(viewModels.allSatisfy { $0.code == .obfuscated })
    }
}

extension HOTPPreviewViewGeneratorTests {
    private typealias SUT = HOTPPreviewViewGenerator<MockHOTPViewFactory>
    private func makeSUT() -> (SUT, MockIntervalTimer, MockHOTPViewFactory) {
        let factory = MockHOTPViewFactory()
        let timer = MockIntervalTimer()
        let sut = HOTPPreviewViewGenerator(viewFactory: factory, timer: timer)
        return (sut, timer, factory)
    }

    private func anyHOTPCode() -> HOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }

    private final class MockHOTPViewFactory: HOTPPreviewViewFactory {
        var makeHOTPViewExecuted: (CodePreviewViewModel, CodeIncrementerViewModel, OTPViewBehaviour?)
            -> Void = { _, _, _ in }
        func makeHOTPView(
            viewModel: CodePreviewViewModel,
            incrementer: CodeIncrementerViewModel,
            behaviour: OTPViewBehaviour?
        ) -> some View {
            makeHOTPViewExecuted(viewModel, incrementer, behaviour)
            return Text("Hello, world")
        }
    }

    private func expectAllIdentical(
        in array: [some AnyObject],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            array.allSatisfy { $0 === array.first },
            "All items are not identical instances",
            file: file,
            line: line
        )
    }
}
