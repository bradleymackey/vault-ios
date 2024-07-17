import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class VaultTagDetailViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNotSideEffectsOnStore() async {
        let store = VaultTagStoreStub.empty
        _ = makeSUT(store: store)

        XCTAssertEqual(store.retrieveTagsCallCount, 0)
        XCTAssertEqual(store.insertTagCallCount, 0)
        XCTAssertEqual(store.updateTagCallCount, 0)
        XCTAssertEqual(store.deleteTagCallCount, 0)
    }

    @MainActor
    func test_init_errorsAreNil() async {
        let sut = makeSUT()

        XCTAssertNil(sut.saveError)
        XCTAssertNil(sut.deleteError)
    }

    @MainActor
    func test_init_whenExistingTagIsNil_setsDefaultValues() async {
        let sut = makeSUT()

        XCTAssertEqual(sut.title, "")
        XCTAssertEqual(sut.color, .tagDefault)
        XCTAssertEqual(sut.systemIconName, "tag.fill")
    }

    @MainActor
    func test_init_whenExistingTagIsNotNil_fallsBackToDefaultTagIfIconNameInvalid() async {
        let color = VaultItemColor.random()
        let tag = VaultItemTag(id: .init(), name: "tag", color: color, iconName: "tagicon")
        let sut = makeSUT(existingTag: tag)

        XCTAssertEqual(sut.title, "tag")
        XCTAssertEqual(sut.color, color)
        XCTAssertEqual(sut.systemIconName, "tag.fill")
    }

    @MainActor
    func test_init_whenExistingTagIsNotNil_setsValueFromTag() async {
        let color = VaultItemColor.random()
        let tag = VaultItemTag(id: .init(), name: "tag", color: color, iconName: "figure.2.arms.open")
        let sut = makeSUT(existingTag: tag)

        XCTAssertEqual(sut.title, "tag")
        XCTAssertEqual(sut.color, color)
        XCTAssertEqual(sut.systemIconName, "figure.2.arms.open")
    }

    @MainActor
    func test_save_newTagInsertsIntoStore() async {
        let store = VaultTagStoreStub.empty
        let sut = makeSUT(store: store)

        await sut.save()

        XCTAssertEqual(store.insertTagCallCount, 1)
        XCTAssertEqual(store.updateTagCallCount, 0)
        XCTAssertNil(sut.saveError)
    }

    @MainActor
    func test_save_existingTagUpdatesIntoStore() async {
        let store = VaultTagStoreStub.empty
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(store: store, existingTag: tag)

        await sut.save()

        XCTAssertEqual(store.insertTagCallCount, 0)
        XCTAssertEqual(store.updateTagCallCount, 1)
        XCTAssertNil(sut.saveError)
    }

    @MainActor
    func test_save_insertErrorSetsSaveError() async {
        let store = VaultTagStoreErroring(error: TestError())
        let sut = makeSUT(store: store)

        await sut.save()

        XCTAssertNotNil(sut.saveError)
    }

    @MainActor
    func test_save_updateErrorSetsSaveError() async {
        let store = VaultTagStoreErroring(error: TestError())
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(store: store, existingTag: tag)

        await sut.save()

        XCTAssertNotNil(sut.saveError)
    }

    @MainActor
    func test_delete_noExistingTagDoesNotCallDelete() async {
        let store = VaultTagStoreStub.empty
        let sut = makeSUT(store: store)

        await sut.delete()

        XCTAssertEqual(store.deleteTagCallCount, 0)
        XCTAssertNil(sut.deleteError)
    }

    @MainActor
    func test_delete_existingTagCallsDelete() async {
        let store = VaultTagStoreStub.empty
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(store: store, existingTag: tag)

        await sut.delete()

        XCTAssertEqual(store.deleteTagCallCount, 1)
        XCTAssertNil(sut.deleteError)
    }

    @MainActor
    func test_delete_deleteErrorSetsDeleteError() async {
        let store = VaultTagStoreErroring(error: TestError())
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(store: store, existingTag: tag)

        await sut.delete()

        XCTAssertNotNil(sut.deleteError)
    }

    @MainActor
    func test_clearErrors_setsErrorsToNil() async {
        let sut = makeSUT()
        sut.saveError = .init(userTitle: "title", userDescription: "desc", debugDescription: "debug")
        sut.deleteError = .init(userTitle: "title", userDescription: "desc", debugDescription: "debug")

        sut.clearErrors()

        XCTAssertNil(sut.saveError)
        XCTAssertNil(sut.deleteError)
    }
}

// MARK: - Helpers

extension VaultTagDetailViewModelTests {
    @MainActor
    func makeSUT<S: VaultTagStore>(
        store: S = VaultTagStoreStub(),
        existingTag: VaultItemTag? = nil
    ) -> VaultTagDetailViewModel<S> {
        .init(store: store, existingTag: existingTag)
    }
}
