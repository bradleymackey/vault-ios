import Foundation
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

@MainActor
final class HOTPPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let (_, timer, factory) = makeSUT()

        XCTAssertEqual(factory.makeHOTPViewExecutedCount, 0)
        XCTAssertEqual(timer.recordedWaitedIntervals, [])
    }

    func test_makeOTPView_generatesViews() throws {
        let (sut, _, _) = makeSUT()

        let view = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(), behaviour: .normal)

        let foundText = try view.inspect().text().string()
        XCTAssertEqual(foundText, "Hello, HOTP!")
    }

    func test_makeOTPView_viewModelsAreInitiallyObfuscated() {
        let (sut, _, factory) = makeSUT()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [UUID(), UUID()])

        XCTAssertEqual(viewModels.count, 2)
        XCTAssertTrue(viewModels.allSatisfy { $0.code == .obfuscated })
    }

    func test_makeOTPView_returnsSameViewModelInstanceUsingCachedViewModels() {
        let (sut, _, factory) = makeSUT()
        let sharedID = UUID()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    func test_makeOTPView_returnsSameIncrementerInstanceUsingCachedViewModels() {
        let (sut, _, factory) = makeSUT()
        let sharedID = UUID()
        let viewModels = collectCodeIncrementerViewModels(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    func test_previewActionForVaultItem_isNilIfCacheEmpty() {
        let (sut, _, _) = makeSUT()

        let code = sut.previewActionForVaultItem(id: UUID())

        XCTAssertNil(code)
    }

    func test_previewActionForVaultItem_isNilWhenCodeIsObfuscated() {
        let (sut, _, _) = makeSUT()

        let id = UUID()
        _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        let code = sut.previewActionForVaultItem(id: id)

        XCTAssertNil(code, "Code is initially obfuscated, so this should be nil")
    }

    func test_previewActionForVaultItem_isCopyTextIfCodeHasBeenGenerated() {
        let (sut, _, factory) = makeSUT()
        let id = UUID()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [id])

        for viewModel in viewModels {
            viewModel.update(code: .visible("123456"))
        }

        let code = sut.previewActionForVaultItem(id: id)

        XCTAssertEqual(code, .copyText("123456"))
    }

    func test_hideAllCodesUntilNextUpdate_marksCachedViewModelsAsObfuscated() {
        let (sut, _, factory) = makeSUT()

        expectHidesAllCodesUntilNextUpdate(sut: sut, factory: factory) {
            sut.hideAllCodesUntilNextUpdate()
        }
    }

    func test_scenePhaseDidChange_backgroundHidesAllCodesUntilNextUpdate() {
        let (sut, _, factory) = makeSUT()

        expectHidesAllCodesUntilNextUpdate(sut: sut, factory: factory) {
            sut.scenePhaseDidChange(to: .background)
        }
    }

    func test_invalidateCache_removesCodeSpecificObjectsFromCache() {
        let (sut, _, _) = makeSUT()

        let id = UUID()

        _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(sut.cachedRendererCount, 1)
        XCTAssertEqual(sut.cachedIncrementerCount, 1)

        sut.invalidateVaultItemDetailCache(forVaultItemWithID: id)

        XCTAssertEqual(sut.cachedViewsCount, 0)
        XCTAssertEqual(sut.cachedRendererCount, 0)
        XCTAssertEqual(sut.cachedIncrementerCount, 0)
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

    private func expectHidesAllCodesUntilNextUpdate(sut: SUT, factory: MockHOTPViewFactory, when action: () -> Void) {
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [UUID(), UUID()])

        for viewModel in viewModels {
            viewModel.update(code: .visible("1234"))
        }

        XCTAssertTrue(viewModels.allSatisfy { $0.code != .obfuscated })

        action()

        XCTAssertTrue(viewModels.allSatisfy { $0.code == .obfuscated })
    }

    private final class MockHOTPViewFactory: HOTPPreviewViewFactory {
        var makeHOTPViewExecutedCount = 0
        var makeHOTPViewExecuted: (OTPCodePreviewViewModel, OTPCodeIncrementerViewModel, VaultItemViewBehaviour)
            -> Void = { _, _, _ in }
        func makeHOTPView(
            viewModel: OTPCodePreviewViewModel,
            incrementer: OTPCodeIncrementerViewModel,
            behaviour: VaultItemViewBehaviour
        ) -> some View {
            makeHOTPViewExecutedCount += 1
            makeHOTPViewExecuted(viewModel, incrementer, behaviour)
            return Text("Hello, HOTP!")
        }
    }

    private func collectCodePreviewViewModels(
        sut: SUT,
        factory: MockHOTPViewFactory,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodePreviewViewModel] {
        var viewModels = [OTPCodePreviewViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewExecuted = { viewModel, _, _ in
            viewModels.append(viewModel)
            group.leave()
        }

        for id in ids {
            group.enter()
            _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        }

        _ = group.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(
            viewModels.count,
            ids.count,
            "Invariant failed, expected number of view models to match the number of IDs we requested",
            file: file,
            line: line
        )
        return viewModels
    }

    private func collectCodeIncrementerViewModels(
        sut: SUT,
        factory: MockHOTPViewFactory,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodeIncrementerViewModel] {
        var viewModels = [OTPCodeIncrementerViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewExecuted = { _, incrementer, _ in
            viewModels.append(incrementer)
            group.leave()
        }

        for id in ids {
            group.enter()
            _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        }

        _ = group.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(
            viewModels.count,
            ids.count,
            "Invariant failed, expected number of view models to match the number of IDs we requested",
            file: file,
            line: line
        )
        return viewModels
    }
}
