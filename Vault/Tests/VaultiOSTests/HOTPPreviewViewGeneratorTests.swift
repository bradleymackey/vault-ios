import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

final class HOTPPreviewViewGeneratorTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let (_, timer, factory) = makeSUT()

        XCTAssertEqual(factory.makeHOTPViewCallCount, 0)
        XCTAssertEqual(timer.waitArgValues, [])
    }

    @MainActor
    func test_makeOTPView_generatesViews() throws {
        let (sut, _, _) = makeSUT()

        let view = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_makeOTPView_viewModelsAreInitiallyObfuscated() {
        let (sut, _, factory) = makeSUT()
        let viewModels = collectCodePreviewViewModels(
            sut: sut,
            factory: factory,
            ids: [Identifier<VaultItem>(), Identifier<VaultItem>()]
        )

        XCTAssertEqual(viewModels.count, 2)
        XCTAssertTrue(viewModels.allSatisfy { $0.code == .obfuscated })
    }

    @MainActor
    func test_makeOTPView_returnsSameViewModelInstanceUsingCachedViewModels() {
        let (sut, _, factory) = makeSUT()
        let sharedID = Identifier<VaultItem>()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    @MainActor
    func test_makeOTPView_returnsSameIncrementerInstanceUsingCachedViewModels() {
        let (sut, _, factory) = makeSUT()
        let sharedID = Identifier<VaultItem>()
        let viewModels = collectCodeIncrementerViewModels(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    @MainActor
    func test_previewActionForVaultItem_isNilIfCacheEmpty() {
        let (sut, _, _) = makeSUT()

        let code = sut.previewActionForVaultItem(id: Identifier<VaultItem>())

        XCTAssertNil(code)
    }

    @MainActor
    func test_previewActionForVaultItem_isNilWhenCodeIsObfuscated() {
        let (sut, _, _) = makeSUT()

        let id = Identifier<VaultItem>()
        _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        let code = sut.previewActionForVaultItem(id: id)

        XCTAssertNil(code, "Code is initially obfuscated, so this should be nil")
    }

    @MainActor
    func test_previewActionForVaultItem_isCopyTextIfCodeHasBeenGenerated() {
        let (sut, _, factory) = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [id])

        for viewModel in viewModels {
            viewModel.update(code: .visible("123456"))
        }

        let code = sut.previewActionForVaultItem(id: id)

        XCTAssertEqual(code, .copyText("123456"))
    }

    @MainActor
    func test_textToCopyForVaultItem_isNilIfCacheEmpty() {
        let (sut, _, _) = makeSUT()

        let code = sut.textToCopyForVaultItem(id: Identifier<VaultItem>())

        XCTAssertNil(code)
    }

    @MainActor
    func test_textToCopyForVaultItem_isNilWhenCodeIsObfuscated() {
        let (sut, _, _) = makeSUT()

        let id = Identifier<VaultItem>()
        _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertNil(code, "Code is initially obfuscated, so this should be nil")
    }

    @MainActor
    func test_textToCopyForVaultItem_isCopyTextIfCodeHasBeenGenerated() {
        let (sut, _, factory) = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [id])

        for viewModel in viewModels {
            viewModel.update(code: .visible("123456"))
        }

        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertEqual(code, "123456")
    }

    @MainActor
    func test_hideAllCodesUntilNextUpdate_marksCachedViewModelsAsObfuscated() {
        let (sut, _, factory) = makeSUT()

        expectHidesAllCodesUntilNextUpdate(sut: sut, factory: factory) {
            sut.hideAllCodesUntilNextUpdate()
        }
    }

    @MainActor
    func test_scenePhaseDidChange_backgroundHidesAllCodesUntilNextUpdate() {
        let (sut, _, factory) = makeSUT()

        expectHidesAllCodesUntilNextUpdate(sut: sut, factory: factory) {
            sut.scenePhaseDidChange(to: .background)
        }
    }

    @MainActor
    func test_invalidateCache_removesCodeSpecificObjectsFromCache() async throws {
        let (sut, _, _) = makeSUT()

        let id = Identifier<VaultItem>()

        _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(sut.cachedRendererCount, 1)
        XCTAssertEqual(sut.cachedIncrementerCount, 1)

        await sut.invalidateVaultItemDetailCache(forVaultItemWithID: id)

        XCTAssertEqual(sut.cachedViewsCount, 0)
        XCTAssertEqual(sut.cachedRendererCount, 0)
        XCTAssertEqual(sut.cachedIncrementerCount, 0)
    }
}

extension HOTPPreviewViewGeneratorTests {
    private typealias SUT = HOTPPreviewViewGenerator<HOTPPreviewViewFactoryMock>
    @MainActor
    private func makeSUT() -> (SUT, IntervalTimerMock, HOTPPreviewViewFactoryMock) {
        let factory = HOTPPreviewViewFactoryMock()
        factory.makeHOTPViewHandler = { _, _, _ in AnyView(Color.green) }
        let timer = IntervalTimerMock()
        let sut = HOTPPreviewViewGenerator(viewFactory: factory, timer: timer, store: VaultStoreHOTPIncrementerMock())
        return (sut, timer, factory)
    }

    private func anyHOTPCode() -> HOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }

    @MainActor
    private func expectHidesAllCodesUntilNextUpdate(
        sut: SUT,
        factory: HOTPPreviewViewFactoryMock,
        when action: () -> Void
    ) {
        let viewModels = collectCodePreviewViewModels(
            sut: sut,
            factory: factory,
            ids: [Identifier<VaultItem>(), Identifier<VaultItem>()]
        )

        for viewModel in viewModels {
            viewModel.update(code: .visible("1234"))
        }

        XCTAssertTrue(viewModels.allSatisfy { $0.code != .obfuscated })

        action()

        XCTAssertTrue(viewModels.allSatisfy { $0.code == .obfuscated })
    }

    @MainActor
    private func collectCodePreviewViewModels(
        sut: SUT,
        factory: HOTPPreviewViewFactoryMock,
        ids: [Identifier<VaultItem>],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodePreviewViewModel] {
        var viewModels = [OTPCodePreviewViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewHandler = { viewModel, _, _ in
            viewModels.append(viewModel)
            group.leave()
            return AnyView(Text("Hello, HOTP!"))
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

    @MainActor
    private func collectCodeIncrementerViewModels(
        sut: SUT,
        factory: HOTPPreviewViewFactoryMock,
        ids: [Identifier<VaultItem>],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodeIncrementerViewModel] {
        var viewModels = [OTPCodeIncrementerViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewHandler = { _, incrementer, _ in
            viewModels.append(incrementer)
            group.leave()
            return AnyView(Text("Hello, HOTP!"))
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
