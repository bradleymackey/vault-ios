import Combine
import Foundation
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

final class TOTPPreviewViewGeneratorTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
//        isRecording = true
    }

    @MainActor
    func test_init_hasNoSideEffects() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let timer = MockIntervalTimer()
        _ = makeSUT(factory: factory, timer: timer)

        XCTAssertEqual(factory.makeTOTPViewCallCount, 0)
        XCTAssertEqual(timer.recordedWaitedIntervals, [])
    }

    @MainActor
    func test_makeOTPView_generatesViews() throws {
        let factory = TOTPPreviewViewFactoryMock()
        factory.makeTOTPViewHandler = { _, _, _, _ in AnyView(Color.green) }
        let sut = makeSUT(factory: factory)

        let view = sut.makeVaultPreviewView(item: anyTOTPCode(), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_makeOTPView_returnsSameViewModelInstanceUsingCachedViewModels() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)
        let sharedID = UUID()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    @MainActor
    func test_makeOTPView_returnsSameTimerPeriodStateUsingCachedModels() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)
        let sharedID = UUID()
        let models = collectCodeTimerPeriodState(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(models.count, 2)
        expectAllIdentical(in: models)
    }

    @MainActor
    func test_previewActionForVaultItem_isNilIfCacheEmpty() {
        let sut = makeSUT()

        let code = sut.previewActionForVaultItem(id: UUID())

        XCTAssertNil(code)
    }

    @MainActor
    func test_previewActionForVaultItem_isCopyTextIfCodeHasBeenGenerated() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)
        let id = UUID()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [id])

        for viewModel in viewModels {
            viewModel.update(code: .visible("123456"))
        }

        let code = sut.previewActionForVaultItem(id: id)

        XCTAssertEqual(code, .copyText("123456"))
    }

    @MainActor
    func test_textToCopyForVaultItem_isNilIfCacheEmpty() {
        let sut = makeSUT()

        let code = sut.textToCopyForVaultItem(id: UUID())

        XCTAssertNil(code)
    }

    @MainActor
    func test_textToCopyForVaultItem_isCopyTextIfCodeHasBeenGenerated() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)
        let id = UUID()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [id])

        for viewModel in viewModels {
            viewModel.update(code: .visible("123456"))
        }

        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertEqual(code, "123456")
    }

    @MainActor
    func test_invalidateCache_removesCodeSpecificObjectsFromCache() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)
        let id = UUID()

        _ = sut.makeVaultPreviewView(item: anyTOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(sut.cachedPeriodStateCount, 1)
        XCTAssertEqual(sut.cachedTimerControllerCount, 1)

        sut.invalidateVaultItemDetailCache(forVaultItemWithID: id)

        XCTAssertEqual(sut.cachedViewsCount, 0)
        XCTAssertEqual(sut.cachedPeriodStateCount, 1, "This is shared across codes, and should not be invalidated")
        XCTAssertEqual(sut.cachedTimerControllerCount, 1, "This is shared across codes, and should not be invalidated")
    }

    @MainActor
    func test_recalculateAllTimers_recalculatesAllCachedTimers() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)

        expectRecalculatesCachedTimers(sut: sut, factory: factory) {
            sut.recalculateAllTimers()
        }
    }

    @MainActor
    func test_scenePhaseDidChange_activeRecalculatesAllCachedTimers() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)

        expectRecalculatesCachedTimers(sut: sut, factory: factory) {
            sut.scenePhaseDidChange(to: .active)
        }
    }

    @MainActor
    func test_didAppear_recalculatesAllCachedTimers() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let sut = makeSUT(factory: factory)

        expectRecalculatesCachedTimers(sut: sut, factory: factory) {
            sut.didAppear()
        }
    }
}

extension TOTPPreviewViewGeneratorTests {
    private typealias SUT = TOTPPreviewViewGenerator<TOTPPreviewViewFactoryMock>

    @MainActor
    private func makeSUT(
        factory: TOTPPreviewViewFactoryMock = makeTOTPPreviewViewFactoryMock(),
        updaterFactory: MockCodeTimerUpdaterFactory = MockCodeTimerUpdaterFactory(),
        clock: EpochClock = EpochClock { 100 },
        timer: MockIntervalTimer = MockIntervalTimer()
    ) -> SUT {
        SUT(viewFactory: factory, updaterFactory: updaterFactory, clock: clock, timer: timer)
    }

    private func anyTOTPCode() -> TOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }

    @MainActor
    private func expectRecalculatesCachedTimers(
        sut: SUT,
        factory: TOTPPreviewViewFactoryMock,
        when action: () -> Void
    ) {
        let updaters = collectCodeTimerUpdaters(sut: sut, factory: factory, ids: [UUID(), UUID(), UUID()])

        for updater in updaters {
            XCTAssertEqual(updater.recalculateCallCount, 0)
        }

        action()

        for updater in updaters {
            XCTAssertEqual(updater.recalculateCallCount, 1)
        }
    }

    @MainActor
    private func collectFactoryParameters(
        sut: SUT,
        factory: TOTPPreviewViewFactoryMock,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [(OTPCodePreviewViewModel, OTPCodeTimerPeriodState, MockCodeTimerUpdater)] {
        var models = [(OTPCodePreviewViewModel, OTPCodeTimerPeriodState, MockCodeTimerUpdater)]()

        let group = DispatchGroup()
        factory.makeTOTPViewHandler = { viewModel, periodState, updater, _ in
            defer { group.leave() }
            guard let mockUpdater = updater as? MockCodeTimerUpdater else {
                return AnyView(Text("Hello, TOTP!"))
            }
            models.append((viewModel, periodState, mockUpdater))
            return AnyView(Text("Hello, TOTP!"))
        }

        for id in ids {
            group.enter()
            _ = sut.makeVaultPreviewView(item: anyTOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        }

        _ = group.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(
            models.count,
            ids.count,
            "Invariant failed, expected number of view models to match the number of IDs we requested",
            file: file,
            line: line
        )
        return models
    }

    @MainActor
    private func collectCodePreviewViewModels(
        sut: SUT,
        factory: TOTPPreviewViewFactoryMock,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodePreviewViewModel] {
        collectFactoryParameters(sut: sut, factory: factory, ids: ids, file: file, line: line)
            .map(\.0)
    }

    @MainActor
    private func collectCodeTimerPeriodState(
        sut: SUT,
        factory: TOTPPreviewViewFactoryMock,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodeTimerPeriodState] {
        collectFactoryParameters(sut: sut, factory: factory, ids: ids, file: file, line: line)
            .map(\.1)
    }

    @MainActor
    private func collectCodeTimerUpdaters(
        sut: SUT,
        factory: TOTPPreviewViewFactoryMock,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [MockCodeTimerUpdater] {
        collectFactoryParameters(sut: sut, factory: factory, ids: ids, file: file, line: line)
            .map(\.2)
    }

    private final class MockCodeTimerUpdaterFactory: OTPCodeTimerUpdaterFactory {
        func makeUpdater(period: UInt64) -> any OTPCodeTimerUpdater {
            MockCodeTimerUpdater(period: period)
        }
    }

    private final class MockCodeTimerUpdater: OTPCodeTimerUpdater {
        let period: UInt64
        init(period: UInt64) {
            self.period = period
        }

        private(set) var recalculateCallCount = 0
        func recalculate() {
            recalculateCallCount += 1
        }

        let timerUpdatedPublisherSubject = PassthroughSubject<OTPCodeTimerState, Never>()
        func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
            timerUpdatedPublisherSubject.eraseToAnyPublisher()
        }
    }
}

@MainActor
private func makeTOTPPreviewViewFactoryMock() -> TOTPPreviewViewFactoryMock {
    let mock = TOTPPreviewViewFactoryMock()
    mock.makeTOTPViewHandler = { _, _, _, _ in AnyView(Text("Nice")) }
    return mock
}
