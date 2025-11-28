import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class TOTPPreviewViewRepositoryImplTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let sut = makeSUT()

        XCTAssertEqual(sut.cachedViewsCount, 0)
        XCTAssertEqual(sut.cachedPeriodStateCount, 0)
        XCTAssertEqual(sut.cachedTimerControllerCount, 0)
    }

    @MainActor
    func test_previewViewModel_returnsSameViewModelInstanceUsingCachedViewModels() {
        let sut = makeSUT()

        let sharedID = Identifier<VaultItem>.new()
        let viewModel1 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: sharedID), code: anyTOTPCode())
        XCTAssertEqual(sut.cachedViewsCount, 1)
        let viewModel2 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: sharedID), code: anyTOTPCode())
        XCTAssertEqual(sut.cachedViewsCount, 1)
        let viewModel3 = sut.previewViewModel(metadata: anyVaultItemMetadata(id: .new()), code: anyTOTPCode())
        XCTAssertEqual(sut.cachedViewsCount, 2)

        XCTAssertIdentical(viewModel1, viewModel2)
        XCTAssertNotIdentical(viewModel1, viewModel3, "View model 3 has a different ID")
        XCTAssertNotIdentical(viewModel2, viewModel3, "View model 3 has a different ID")
    }

    @MainActor
    func test_timerUpdater_returnsSameInstanceUsingCachedViewModels() {
        let factory = OTPCodeTimerUpdaterFactoryMock()
        factory.makeUpdaterHandler = { _ in OTPCodeTimerUpdaterMock() }
        let sut = makeSUT(factory: factory)

        let sharedPeriod = 123 as UInt64
        let updater1 = sut.timerUpdater(period: sharedPeriod)
        XCTAssertEqual(sut.cachedTimerControllerCount, 1)
        let updater2 = sut.timerUpdater(period: sharedPeriod)
        XCTAssertEqual(sut.cachedTimerControllerCount, 1)
        let updater3 = sut.timerUpdater(period: 99)
        XCTAssertEqual(sut.cachedTimerControllerCount, 2)

        XCTAssertIdentical(updater1, updater2)
        XCTAssertNotIdentical(updater1, updater3, "Updater 3 is different")
        XCTAssertNotIdentical(updater2, updater3, "Updater 3 is different")
    }

    @MainActor
    func test_timerPeriodState_returnsSameInstanceUsingCachedViewModels() {
        let sut = makeSUT()

        let sharedPeriod = 123 as UInt64
        let state1 = sut.timerPeriodState(period: sharedPeriod)
        XCTAssertEqual(sut.cachedPeriodStateCount, 1)
        let state2 = sut.timerPeriodState(period: sharedPeriod)
        XCTAssertEqual(sut.cachedPeriodStateCount, 1)
        let state3 = sut.timerPeriodState(period: 99)
        XCTAssertEqual(sut.cachedPeriodStateCount, 2)

        XCTAssertIdentical(state1, state2)
        XCTAssertNotIdentical(state1, state3, "State 3 is different")
        XCTAssertNotIdentical(state2, state3, "State 3 is different")
    }

    @MainActor
    func test_textToCopyForVaultItem_isNilIfCacheEmpty() {
        let sut = makeSUT()

        let copyAction = sut.textToCopyForVaultItem(id: .new())

        XCTAssertNil(copyAction)
    }

    @MainActor
    func test_textToCopyForVaultItem_isNilWhenCodeIsObfuscated() {
        let sut = makeSUT()

        let id = Identifier<VaultItem>()
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyTOTPCode())
        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertNil(code, "Code is initially obfuscated, so this should be nil")
    }

    @MainActor
    func test_textToCopyForVaultItem_isCopyTextIfCodeHasBeenGenerated() {
        let sut = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyTOTPCode())
        viewModel.update(.visible("123456"))

        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertEqual(code, .init(text: "123456", requiresAuthenticationToCopy: false))
    }

    @MainActor
    func test_textToCopyForVaultItem_requiresAuthenticationToCopyIfLocked() {
        let sut = makeSUT()
        let id = Identifier<VaultItem>()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id), code: anyTOTPCode())
        viewModel.update(.locked(code: "123456"))

        let code = sut.textToCopyForVaultItem(id: id)

        XCTAssertEqual(code, .init(text: "123456", requiresAuthenticationToCopy: true))
    }

    @MainActor
    func test_stopAllTimers_cancelsAllTimers() async {
        let updater = OTPCodeTimerUpdaterMock()
        let sut = makeSUT(updater: updater)
        _ = sut.timerUpdater(period: 100)

        let exp = expectation(description: "Wait for timer cancelled")
        updater.cancelHandler = {
            exp.fulfill()
        }

        sut.stopAllTimers()

        await fulfillment(of: [exp], timeout: 1)
    }

    @MainActor
    func test_restartAllTimers_restartsAllTimers() async {
        let updater = OTPCodeTimerUpdaterMock()
        let sut = makeSUT(updater: updater)
        _ = sut.timerUpdater(period: 100)

        let exp = expectation(description: "Wait for timer updated")
        updater.recalculateHandler = {
            exp.fulfill()
        }

        sut.restartAllTimers()

        await fulfillment(of: [exp], timeout: 1)
    }

    @MainActor
    func test_obfuscateForPrivacy_obfuscatesViewModelsForPrivacy() async {
        let sut = makeSUT()
        let viewModel = sut.previewViewModel(metadata: anyVaultItemMetadata(), code: anyTOTPCode())
        viewModel.update(.visible("123456"))

        sut.obfuscateForPrivacy()

        XCTAssertEqual(viewModel.code, .obfuscated(.privacy))
    }

    @MainActor
    func test_vaultItemCacheClear_removesItemsMatchingIDFromCache() async {
        let sut = makeSUT()

        let id1 = Identifier<VaultItem>()
        let id2 = Identifier<VaultItem>()

        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id1), code: anyTOTPCode(period: 100))
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: id2), code: anyTOTPCode(period: 100))
        _ = sut.timerPeriodState(period: 100)
        _ = sut.timerPeriodState(period: 101)
        _ = sut.timerUpdater(period: 100)
        _ = sut.timerUpdater(period: 101)

        XCTAssertEqual(sut.cachedViewsCount, 2)
        XCTAssertEqual(sut.cachedPeriodStateCount, 2)
        XCTAssertEqual(sut.cachedTimerControllerCount, 2)

        await sut.vaultItemCacheClear(forVaultItemWithID: id1)

        XCTAssertEqual(sut.cachedViewsCount, 1)
        XCTAssertEqual(sut.cachedPeriodStateCount, 2, "Period-based state is not invalidated")
        XCTAssertEqual(sut.cachedTimerControllerCount, 2, "Period-based state is not invalidated")
    }

    @MainActor
    func test_vaultItemCacheClearAll_removesItemsAllItemsFromCache() async {
        let sut = makeSUT()

        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: .new()), code: anyTOTPCode(period: 100))
        _ = sut.previewViewModel(metadata: anyVaultItemMetadata(id: .new()), code: anyTOTPCode(period: 100))
        _ = sut.timerPeriodState(period: 100)
        _ = sut.timerPeriodState(period: 101)
        _ = sut.timerUpdater(period: 100)
        _ = sut.timerUpdater(period: 101)

        XCTAssertEqual(sut.cachedViewsCount, 2)
        XCTAssertEqual(sut.cachedPeriodStateCount, 2)
        XCTAssertEqual(sut.cachedTimerControllerCount, 2)

        await sut.vaultItemCacheClearAll()

        XCTAssertEqual(sut.cachedViewsCount, 0)
        XCTAssertEqual(sut.cachedPeriodStateCount, 0)
        XCTAssertEqual(sut.cachedTimerControllerCount, 0)
    }
}

// MARK: - Helpers

extension TOTPPreviewViewRepositoryImplTests {
    @MainActor
    private func makeSUT(
        clock: EpochClockMock = EpochClockMock(currentTime: 100),
        timer: IntervalTimerMock = IntervalTimerMock(),
        updater: OTPCodeTimerUpdaterMock = OTPCodeTimerUpdaterMock(),
    ) -> TOTPPreviewViewRepositoryImpl {
        let factory = OTPCodeTimerUpdaterFactoryMock()
        factory.makeUpdaterHandler = { _ in updater }
        return TOTPPreviewViewRepositoryImpl(clock: clock, timer: timer, updaterFactory: factory)
    }

    @MainActor
    private func makeSUT(
        clock: EpochClockMock = EpochClockMock(currentTime: 100),
        timer: IntervalTimerMock = IntervalTimerMock(),
        factory: OTPCodeTimerUpdaterFactoryMock,
    ) -> TOTPPreviewViewRepositoryImpl {
        TOTPPreviewViewRepositoryImpl(clock: clock, timer: timer, updaterFactory: factory)
    }
}
