import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

@Suite
@MainActor
struct VaultTagDetailViewModelTests {
    @Test
    func init_hasNotSideEffectsOnStore() {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        _ = makeSUT(dataModel: dataModel)

        #expect(store.calledMethods == [])
        #expect(tagStore.calledMethods == [])
    }

    @Test
    func init_errorsAreNil() {
        let sut = makeSUT()

        #expect(sut.saveError == nil)
        #expect(sut.deleteError == nil)
    }

    @Test
    func init_whenExistingTagIsNil_setsDefaultValues() {
        let sut = makeSUT()

        #expect(sut.currentTag.name == "")
        #expect(sut.currentTag.color == .tagDefault)
        #expect(sut.currentTag.iconName == "tag.fill")
    }

    @Test
    func init_whenExistingTagIsNotNil_setsValueFromTag() {
        let color = VaultItemColor.random()
        let tag = VaultItemTag(id: .init(), name: "tag", color: color, iconName: "figure.2.arms.open")
        let sut = makeSUT(existingTag: tag)

        #expect(sut.currentTag.name == "tag")
        #expect(sut.currentTag.color == color)
        #expect(sut.currentTag.iconName == "figure.2.arms.open")
    }

    @Test
    func save_newTagInsertsIntoStore() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await sut.save()

        #expect(store.calledMethods == [.export])
        #expect(tagStore.calledMethods == [.insertTag, .retrieveTags])
        #expect(sut.saveError == nil)
    }

    @Test
    func save_existingTagUpdatesIntoStore() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

        await sut.save()

        #expect(store.calledMethods == [.export])
        #expect(tagStore.calledMethods == [.updateTag, .retrieveTags])
        #expect(sut.saveError == nil)
    }

    @Test
    func save_insertErrorSetsSaveError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await sut.save()

        #expect(sut.saveError != nil)
    }

    @Test
    func save_updateErrorSetsSaveError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

        await sut.save()

        #expect(sut.saveError != nil)
    }

    @Test
    func delete_noExistingTagDoesNotCallDelete() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await sut.delete()

        #expect(store.calledMethods == [])
        #expect(tagStore.calledMethods == [])
        #expect(sut.deleteError == nil)
    }

    @Test
    func delete_existingTagCallsDelete() async {
        let store = VaultStoreStub.empty
        let tagStore = VaultTagStoreStub.empty
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

        await sut.delete()

        #expect(store.calledMethods == [.retrieve, .export])
        #expect(tagStore.calledMethods == [.deleteTag, .retrieveTags])
        #expect(sut.deleteError == nil)
    }

    @Test
    func delete_deleteErrorSetsDeleteError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let tag = VaultItemTag(id: .init(), name: "tag")
        let sut = makeSUT(dataModel: dataModel, existingTag: tag)

        await sut.delete()

        #expect(sut.deleteError != nil)
    }

    @Test
    func clearErrors_setsErrorsToNil() {
        let sut = makeSUT()
        sut.saveError = .init(userTitle: "title", userDescription: "desc", debugDescription: "debug")
        sut.deleteError = .init(userTitle: "title", userDescription: "desc", debugDescription: "debug")

        sut.clearErrors()

        #expect(sut.saveError == nil)
        #expect(sut.deleteError == nil)
    }
}

// MARK: - Helpers

extension VaultTagDetailViewModelTests {
    @MainActor
    private func makeSUT(
        dataModel: VaultDataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            vaultKillphraseDeleter: VaultStoreKillphraseDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock(),
        ),
        existingTag: VaultItemTag? = nil,
    ) -> VaultTagDetailViewModel {
        .init(dataModel: dataModel, existingTag: existingTag)
    }
}
