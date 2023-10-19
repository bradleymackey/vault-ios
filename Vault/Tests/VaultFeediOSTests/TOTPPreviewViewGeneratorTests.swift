import Combine
import Foundation
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultFeediOS

@MainActor
final class TOTPPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let factory = MockTOTPViewFactory()
        let timer = MockIntervalTimer()
        _ = makeSUT(factory: factory, timer: timer)

        XCTAssertEqual(factory.makeTOTPViewExecutedCount, 0)
        XCTAssertEqual(timer.recordedWaitedIntervals, [])
    }

    func test_makeOTPView_generatesViews() throws {
        let sut = makeSUT()

        let view = sut.makeVaultPreviewView(item: anyTOTPCode(), metadata: uniqueMetadata(), behaviour: .normal)

        let foundText = try view.inspect().text().string()
        XCTAssertEqual(foundText, "Hello, TOTP!")
    }

    func test_makeOTPView_returnsSameViewModelInstanceUsingCachedViewModels() {
        let factory = MockTOTPViewFactory()
        let sut = makeSUT(factory: factory)
        let sharedID = UUID()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(viewModels.count, 2)
        expectAllIdentical(in: viewModels)
    }

    func test_makeOTPView_returnsSameTimerPeriodStateUsingCachedModels() {
        let factory = MockTOTPViewFactory()
        let sut = makeSUT(factory: factory)
        let sharedID = UUID()
        let models = collectCodeTimerPeriodState(sut: sut, factory: factory, ids: [sharedID, sharedID])

        XCTAssertEqual(models.count, 2)
        expectAllIdentical(in: models)
    }

    func test_currentVisibleCode_isNilIfCacheEmpty() {
        let sut = makeSUT()

        let code = sut.currentCopyableText(id: UUID())

        XCTAssertNil(code)
    }

    func test_currentVisibleCode_isValueIfCodeHasBeenGenerated() {
        let factory = MockTOTPViewFactory()
        let sut = makeSUT(factory: factory)
        let id = UUID()
        let viewModels = collectCodePreviewViewModels(sut: sut, factory: factory, ids: [id])

        for viewModel in viewModels {
            viewModel.update(code: .visible("123456"))
        }

        let code = sut.currentCopyableText(id: id)

        XCTAssertEqual(code, "123456")
    }

    func test_invalidateCache_removesCodeSpecificObjectsFromCache() {
        let factory = MockTOTPViewFactory()
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

    func test_recalculateAllTimers_recalculatesAllCachedTimers() {
        let factory = MockTOTPViewFactory()
        let sut = makeSUT(factory: factory)

        expectRecalculatesCachedTimers(sut: sut, factory: factory) {
            sut.recalculateAllTimers()
        }
    }

    func test_scenePhaseDidChange_activeRecalculatesAllCachedTimers() {
        let factory = MockTOTPViewFactory()
        let sut = makeSUT(factory: factory)

        expectRecalculatesCachedTimers(sut: sut, factory: factory) {
            sut.scenePhaseDidChange(to: .active)
        }
    }

    func test_didAppear_recalculatesAllCachedTimers() {
        let factory = MockTOTPViewFactory()
        let sut = makeSUT(factory: factory)

        expectRecalculatesCachedTimers(sut: sut, factory: factory) {
            sut.didAppear()
        }
    }
}

extension TOTPPreviewViewGeneratorTests {
    private typealias SUT = TOTPPreviewViewGenerator<MockTOTPViewFactory>
    private func makeSUT(
        factory: MockTOTPViewFactory = MockTOTPViewFactory(),
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

    private func expectRecalculatesCachedTimers(sut: SUT, factory: MockTOTPViewFactory, when action: () -> Void) {
        let updaters = collectCodeTimerUpdaters(sut: sut, factory: factory, ids: [UUID(), UUID(), UUID()])

        for updater in updaters {
            XCTAssertEqual(updater.recalculateCallCount, 0)
        }

        action()

        for updater in updaters {
            XCTAssertEqual(updater.recalculateCallCount, 1)
        }
    }

    private final class MockTOTPViewFactory: TOTPPreviewViewFactory {
        var makeTOTPViewExecutedCount = 0
        var makeTOTPViewExecuted: (
            OTPCodePreviewViewModel,
            OTPCodeTimerPeriodState,
            any OTPCodeTimerUpdater,
            VaultItemViewBehaviour
        )
            -> Void = { _, _, _, _ in
            }

        func makeTOTPView(
            viewModel: OTPCodePreviewViewModel,
            periodState: OTPCodeTimerPeriodState,
            updater: any OTPCodeTimerUpdater,
            behaviour: VaultItemViewBehaviour
        ) -> some View {
            makeTOTPViewExecutedCount += 1
            makeTOTPViewExecuted(viewModel, periodState, updater, behaviour)
            return Text("Hello, TOTP!")
        }
    }

    private func collectFactoryParameters(
        sut: SUT,
        factory: MockTOTPViewFactory,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [(OTPCodePreviewViewModel, OTPCodeTimerPeriodState, MockCodeTimerUpdater)] {
        var models = [(OTPCodePreviewViewModel, OTPCodeTimerPeriodState, MockCodeTimerUpdater)]()

        let group = DispatchGroup()
        factory.makeTOTPViewExecuted = { viewModel, periodState, updater, _ in
            defer { group.leave() }
            guard let mockUpdater = updater as? MockCodeTimerUpdater else {
                return
            }
            models.append((viewModel, periodState, mockUpdater))
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

    private func collectCodePreviewViewModels(
        sut: SUT,
        factory: MockTOTPViewFactory,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodePreviewViewModel] {
        collectFactoryParameters(sut: sut, factory: factory, ids: ids, file: file, line: line)
            .map(\.0)
    }

    private func collectCodeTimerPeriodState(
        sut: SUT,
        factory: MockTOTPViewFactory,
        ids: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodeTimerPeriodState] {
        collectFactoryParameters(sut: sut, factory: factory, ids: ids, file: file, line: line)
            .map(\.1)
    }

    private func collectCodeTimerUpdaters(
        sut: SUT,
        factory: MockTOTPViewFactory,
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
