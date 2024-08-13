import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class VaultTagDetailViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNotSideEffectsOnStore() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        _ = makeSUT(dataModel: dataModel)

        XCTAssertEqual(store.calledMethods, [])
        XCTAssertEqual(tagStore.calledMethods, [])
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
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await sut.save()

        XCTAssertEqual(store.calledMethods, [])
        XCTAssertEqual(tagStore.calledMethods, [.insertTag, .retrieveTags])
        XCTAssertNil(sut.saveError)
    }

    @MainActor
    func test_save_existingTagUpdatesIntoStore() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

        await sut.save()

        XCTAssertEqual(store.calledMethods, [])
        XCTAssertEqual(tagStore.calledMethods, [.updateTag, .retrieveTags])
        XCTAssertNil(sut.saveError)
    }

    @MainActor
    func test_save_insertErrorSetsSaveError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await sut.save()

        XCTAssertNotNil(sut.saveError)
    }

    @MainActor
    func test_save_updateErrorSetsSaveError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

        await sut.save()

        XCTAssertNotNil(sut.saveError)
    }

    @MainActor
    func test_delete_noExistingTagDoesNotCallDelete() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await sut.delete()

        XCTAssertEqual(store.calledMethods, [])
        XCTAssertEqual(tagStore.calledMethods, [])
        XCTAssertNil(sut.deleteError)
    }

    @MainActor
    func test_delete_existingTagCallsDelete() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

        await sut.delete()

        XCTAssertEqual(store.calledMethods, [.retrieve])
        XCTAssertEqual(tagStore.calledMethods, [.deleteTag, .retrieveTags])
        XCTAssertNil(sut.deleteError)
    }

    @MainActor
    func test_delete_deleteErrorSetsDeleteError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = VaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

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
    func makeSUT(
        dataModel: VaultDataModel = VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultTagStoreStub()),
        existingTag: VaultItemTag? = nil
    ) -> VaultTagDetailViewModel {
        .init(dataModel: dataModel, existingTag: existingTag)
    }
}
