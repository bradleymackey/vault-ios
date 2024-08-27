import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class VaultDataModelEditorAdapterTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        _ = makeSUT(dataModel: dataModel)

        XCTAssertEqual(store.calledMethods, [])
        XCTAssertEqual(tagStore.calledMethods, [])
    }

    @MainActor
    func test_createCode_createsOTPCodeInFeed_createsCodeInFeed() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)
        let initialCode = OTPAuthCode(
            type: .totp(period: 40),
            data: .init(secret: .empty(), algorithm: .sha256, digits: .default, accountName: "myacc", issuer: "myiss")
        )
        let initialEdits = OTPCodeDetailEdits(
            hydratedFromCode: initialCode,
            relativeOrder: .min,
            userDescription: "mydesc",
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )

        let exp = expectation(description: "Wait for creation")
        store.insertHandler = { data in
            defer { exp.fulfill() }
            switch data.item {
            case let .otpCode(code):
                XCTAssertEqual(
                    code,
                    initialCode,
                    "The code that is saved should be the same as the state from the edits"
                )
            default:
                XCTFail("invalid kind")
            }
            return .new()
        }

        try await sut.createCode(initialEdits: initialEdits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createCode_propagatesFailureOnError() async throws {
        let store = VaultStoreErroring(error: anyNSError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: store)
        let sut = makeSUT(dataModel: dataModel)

        let edits = anyOTPCodeDetailEdits()
        await XCTAssertThrowsError(try await sut.createCode(initialEdits: edits))
    }

    @MainActor
    func test_updateCode_translatesCodeDataForCall() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        var code = uniqueCode()
        code.data.accountName = "old account name"
        code.data.issuer = "old issuer name"
        var item = uniqueVaultItem(item: .otpCode(code))
        item.metadata.userDescription = "old description"
        let color = VaultItemColor(red: 0.0, green: 0.0, blue: 0.0)
        item.metadata.color = color

        var edits = OTPCodeDetailEdits(
            hydratedFromCode: code,
            relativeOrder: .min,
            userDescription: "mydesc",
            color: VaultItemColor(red: 0.5, green: 0.5, blue: 0.5),
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )
        edits.issuerTitle = "new issuer name"
        edits.accountNameTitle = "new account name"
        edits.description = "new description"
        edits.searchPassphrase = "new pass"

        let exp = expectation(description: "Wait for update")
        store.updateHandler = { _, data in
            XCTAssertEqual(data.userDescription, "new description")
            XCTAssertEqual(data.searchPassphase, "new pass")
            switch data.item {
            case let .otpCode(otpCode):
                XCTAssertEqual(otpCode.data.accountName, "new account name")
                XCTAssertEqual(otpCode.data.issuer, "new issuer name")
            case .secureNote:
                XCTFail("invalid kind")
            }
            exp.fulfill()
        }

        try await sut.updateCode(id: item.metadata.id, item: code, edits: edits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateCode_propagatesFailureOnError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        let edits = anyOTPCodeDetailEdits()
        await XCTAssertThrowsError(try await sut.updateCode(
            id: .new(),
            item: uniqueCode(),
            edits: edits
        ))
    }

    @MainActor
    func test_deleteCode_deletesFromFeed() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        let id = Identifier<VaultItem>.new()

        let exp = expectation(description: "Wait for delete")
        store.deleteHandler = { actualID in
            XCTAssertEqual(id, actualID)
            exp.fulfill()
        }

        try await sut.deleteCode(id: id)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteCode_propagatesFailureOnError() async {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await XCTAssertThrowsError(try await sut.deleteCode(id: .new()))
    }

    @MainActor
    func test_createNote_createsNoteInFeed() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        var initialEdits = SecureNoteDetailEdits.new()
        initialEdits.contents = "first line\nsecond line"
        initialEdits.viewConfig = .requiresSearchPassphrase
        initialEdits.searchPassphrase = "pass"
        initialEdits.lockState = .lockedWithNativeSecurity

        let exp = expectation(description: "Wait for creation")
        store.insertHandler = { data in
            defer { exp.fulfill() }
            XCTAssertEqual(data.userDescription, "second line")
            XCTAssertEqual(data.visibility, .onlySearch)
            XCTAssertEqual(data.searchableLevel, .onlyPassphrase)
            XCTAssertEqual(data.searchPassphase, "pass")
            switch data.item {
            case let .secureNote(note):
                XCTAssertEqual(note.title, "first line")
                XCTAssertEqual(note.contents, "first line\nsecond line")
            default:
                XCTFail("invalid kind")
            }
            return .new()
        }

        try await sut.createNote(initialEdits: initialEdits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createNote_propagatesFailureOnError() async throws {
        let store = VaultStoreErroring(error: TestError())
        let tagStore = VaultTagStoreErroring(error: TestError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        await XCTAssertThrowsError(try await sut.createNote(initialEdits: .new()))
    }

    @MainActor
    func test_updateNote_updatesNoteInFeed() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        var note = anySecureNote()
        note.title = "old title"
        note.contents = "old contents"
        note.format = .plain
        var item = uniqueVaultItem(item: .secureNote(note))
        item.metadata.userDescription = "old description"

        var edits = SecureNoteDetailEdits.new()
        edits.textFormat = .markdown
        edits.contents = "first line\nsecond line"
        edits.viewConfig = .alwaysVisible
        edits.searchPassphrase = "new pass"

        let exp = expectation(description: "Wait for update")
        store.updateHandler = { _, data in
            defer { exp.fulfill() }
            XCTAssertEqual(data.userDescription, "second line")
            XCTAssertEqual(data.visibility, .always)
            XCTAssertEqual(data.searchableLevel, .full)
            XCTAssertEqual(data.searchPassphase, "new pass")
            switch data.item {
            case let .secureNote(note):
                XCTAssertEqual(note.title, "first line")
                XCTAssertEqual(note.contents, "first line\nsecond line")
                XCTAssertEqual(note.format, .markdown)
            default:
                XCTFail("invalid kind")
            }
        }

        try await sut.updateNote(id: item.metadata.id, item: note, edits: edits)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateNote_propagatesFailureOnError() async {
        let store = VaultStoreErroring(error: anyNSError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: store)
        let sut = makeSUT(dataModel: dataModel)

        await XCTAssertThrowsError(try await sut.updateNote(id: .new(), item: anySecureNote(), edits: .new()))
    }

    @MainActor
    func test_deleteNote_deletesFromFeed() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: tagStore)
        let sut = makeSUT(dataModel: dataModel)

        let id = Identifier<VaultItem>.new()

        let exp = expectation(description: "Wait for delete")
        store.deleteHandler = { actualID in
            XCTAssertEqual(id, actualID)
            exp.fulfill()
        }

        try await sut.deleteNote(id: id)

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteNote_propagatesFailureOnError() async {
        let store = VaultStoreErroring(error: anyNSError())
        let dataModel = anyVaultDataModel(vaultStore: store, vaultTagStore: store)
        let sut = makeSUT(dataModel: dataModel)

        await XCTAssertThrowsError(try await sut.deleteNote(id: .new()))
    }
}

extension VaultDataModelEditorAdapterTests {
    @MainActor
    private func makeSUT(
        dataModel: VaultDataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        )
    ) -> VaultDataModelEditorAdapter {
        VaultDataModelEditorAdapter(dataModel: dataModel)
    }

    private func anyOTPCodeDetailEdits() -> OTPCodeDetailEdits {
        .init(
            codeType: .totp,
            relativeOrder: .min,
            totpPeriodLength: 30,
            hotpCounterValue: 0,
            secretBase32String: "",
            algorithm: .sha1,
            numberOfDigits: 6,
            issuerTitle: "iss",
            accountNameTitle: "acc",
            description: "desc",
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked,
            color: nil
        )
    }
}
