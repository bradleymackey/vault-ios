import Foundation
import FoundationExtensions
import PDFKit
import VaultBackup
import VaultCore
import VaultFeed
import VaultKeygen

func uniqueCode() -> OTPAuthCode {
    let randomData = Data.random(count: 50)
    return OTPAuthCode(
        type: .totp(),
        data: .init(
            secret: .init(data: randomData, format: .base32),
            accountName: "Some Account"
        )
    )
}

@MainActor
func anyVaultDataModel(
    vaultStore: some VaultStore = VaultStoreStub(),
    vaultTagStore: some VaultTagStore = VaultTagStoreStub(),
    vaultImporter: some VaultStoreImporter = VaultStoreImporterMock(),
    vaultDeleter: some VaultStoreDeleter = VaultStoreDeleterMock(),
    vaultKillphraseDeleter: some VaultStoreKillphraseDeleter = VaultStoreKillphraseDeleterMock(),
    backupPasswordStore: some BackupPasswordStore = BackupPasswordStoreMock(),
    backupEventLogger: some BackupEventLogger = BackupEventLoggerMock()
) -> VaultDataModel {
    VaultDataModel(
        vaultStore: vaultStore,
        vaultTagStore: vaultTagStore,
        vaultImporter: vaultImporter,
        vaultDeleter: vaultDeleter,
        vaultKillphraseDeleter: vaultKillphraseDeleter,
        backupPasswordStore: backupPasswordStore,
        backupEventLogger: backupEventLogger
    )
}

func anyPDFData() throws -> Data {
    let path = randomTmpPath()
    let pdf = PDFDocument()
    pdf.write(to: path)
    return try Data(contentsOf: path)
}

func anyHOTPCode() -> HOTPAuthCode {
    let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
    return .init(data: codeData)
}

func anyTOTPCode(period: UInt64 = 30) -> TOTPAuthCode {
    let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
    return .init(period: period, data: codeData)
}

func anyVaultApplicationPayload() -> VaultApplicationPayload {
    .init(userDescription: "", items: [], tags: [])
}

func randomTmpPath() -> URL {
    FileManager().temporaryDirectory.appending(path: UUID().uuidString)
}

func anyEncryptedVault(
    data: Data = .random(count: 50),
    salt: Data = .random(count: 32)
) -> EncryptedVault {
    EncryptedVault(
        data: data,
        authentication: Data(),
        encryptionIV: Data(),
        keygenSalt: salt,
        keygenSignature: VaultKeyDeriver.Signature.testing.rawValue
    )
}

func anyBackupPassword() -> DerivedEncryptionKey {
    .init(key: .random(), salt: .random(count: 32), keyDervier: .testing)
}

func testUserDefaults() throws -> UserDefaults {
    struct NoDefaults: Error {}
    let id = UUID()
    let defaults = UserDefaults(suiteName: id.uuidString)
    guard let defaults else { throw NoDefaults() }
    defaults.removePersistentDomain(forName: id.uuidString)
    return defaults
}

// MARK: - VaultItem

func anySecureNote(
    title: String = "",
    contents: String = "",
    format: TextFormat = .markdown
) -> SecureNote {
    SecureNote(title: title, contents: contents, format: format)
}

func anyOTPAuthCode(
    type: OTPAuthType = .totp(),
    algorithm: OTPAuthAlgorithm = .default,
    digits: OTPAuthDigits = .default,
    accountName: String = "",
    issuerName: String = ""
) -> OTPAuthCode {
    let randomData = Data.random(count: 50)
    return OTPAuthCode(
        type: type,
        data: .init(
            secret: .init(data: randomData, format: .base32),
            algorithm: algorithm,
            digits: digits,
            accountName: accountName,
            issuer: issuerName
        )
    )
}

/// A unique vault item.
/// The default payload is any OTPAuthCode.
func uniqueVaultItem(
    id: Identifier<VaultItem> = .new(),
    item: VaultItem.Payload = .otpCode(anyOTPAuthCode()),
    relativeOrder: UInt64 = .min,
    updatedDate: Date = Date(),
    userDescription: String = "",
    visibility: VaultItemVisibility = .always,
    tags: Set<Identifier<VaultItemTag>> = [],
    killphrase: String? = nil,
    lockState: VaultItemLockState = .notLocked
) -> VaultItem {
    VaultItem(
        metadata: anyVaultItemMetadata(
            id: id,
            relativeOrder: relativeOrder,
            updatedDate: updatedDate,
            userDescription: userDescription,
            visibility: visibility,
            tags: tags,
            killphrase: killphrase,
            lockState: lockState
        ),
        item: item
    )
}

/// A unique vault item with custom metadata.
/// The default payload is any OTPAuthCode.
func uniqueVaultItem(
    metadata: VaultItem.Metadata,
    item: VaultItem.Payload = .otpCode(anyOTPAuthCode())
) -> VaultItem {
    VaultItem(
        metadata: metadata,
        item: item
    )
}

func anyVaultItemMetadata(
    id: Identifier<VaultItem> = .new(),
    relativeOrder: UInt64 = .min,
    updatedDate: Date = Date(),
    userDescription: String = "",
    visibility: VaultItemVisibility = .always,
    tags: Set<Identifier<VaultItemTag>> = [],
    searchableLevel: VaultItemSearchableLevel = .full,
    searchPassphrase: String? = nil,
    killphrase: String? = nil,
    lockState: VaultItemLockState = .notLocked,
    color: VaultItemColor? = nil
) -> VaultItem.Metadata {
    .init(
        id: id,
        created: Date(),
        updated: updatedDate,
        relativeOrder: relativeOrder,
        userDescription: userDescription,
        tags: tags,
        visibility: visibility,
        searchableLevel: searchableLevel,
        searchPassphrase: searchPassphrase,
        killphrase: killphrase,
        lockState: lockState,
        color: color
    )
}

extension SecureNote {
    func wrapInAnyVaultItem(
        userDescription: String = "",
        visibility: VaultItemVisibility = .always,
        tags: Set<Identifier<VaultItemTag>> = [],
        searchableLevel: VaultItemSearchableLevel = .full,
        searchPassphrase: String? = nil,
        killphrase: String? = nil,
        lockState: VaultItemLockState = .notLocked
    ) -> VaultItem {
        VaultItem(
            metadata: anyVaultItemMetadata(
                userDescription: userDescription,
                visibility: visibility,
                tags: tags,
                searchableLevel: searchableLevel,
                searchPassphrase: searchPassphrase,
                killphrase: killphrase,
                lockState: lockState
            ),
            item: .secureNote(self)
        )
    }
}

extension EncryptedItem {
    func wrapInAnyVaultItem(
        userDescription: String = "",
        visibility: VaultItemVisibility = .always,
        tags: Set<Identifier<VaultItemTag>> = [],
        searchableLevel: VaultItemSearchableLevel = .full,
        searchPassphrase: String? = nil,
        killphrase: String? = nil,
        lockState: VaultItemLockState = .notLocked
    ) -> VaultItem {
        VaultItem(
            metadata: anyVaultItemMetadata(
                userDescription: userDescription,
                visibility: visibility,
                tags: tags,
                searchableLevel: searchableLevel,
                searchPassphrase: searchPassphrase,
                killphrase: killphrase,
                lockState: lockState
            ),
            item: .encryptedItem(self)
        )
    }
}

extension OTPAuthCode {
    func wrapInAnyVaultItem(
        userDescription: String = "",
        visibility: VaultItemVisibility = .always,
        tags: Set<Identifier<VaultItemTag>> = [],
        searchableLevel: VaultItemSearchableLevel = .full,
        searchPassphrase: String? = nil,
        killphrase: String? = nil,
        lockState: VaultItemLockState = .notLocked,
        color: VaultItemColor? = nil
    ) -> VaultItem {
        VaultItem(
            metadata: anyVaultItemMetadata(
                userDescription: userDescription,
                visibility: visibility,
                tags: tags,
                searchableLevel: searchableLevel,
                searchPassphrase: searchPassphrase,
                killphrase: killphrase,
                lockState: lockState,
                color: color
            ),
            item: .otpCode(self)
        )
    }
}

// MARK: - VaultItemTag

func anyVaultItemTag(
    id: UUID = UUID(),
    name: String = "name",
    color: VaultItemColor = .tagDefault,
    iconName: String = VaultItemTag.defaultIconName
) -> VaultItemTag {
    VaultItemTag(id: .init(id: id), name: name, color: color, iconName: iconName)
}

// MARK: - Constants

func hotpRfcSecretData() -> Data {
    Data([
        0x31,
        0x32,
        0x33,
        0x34,
        0x35,
        0x36,
        0x37,
        0x38,
        0x39,
        0x30,
        0x31,
        0x32,
        0x33,
        0x34,
        0x35,
        0x36,
        0x37,
        0x38,
        0x39,
        0x30,
    ])
}

// MARK: - Misc

struct TestError: Error {}

extension UserDefaults {
    var keys: Set<String> {
        dictionaryRepresentation().keys.reducedToSet()
    }
}

struct VaultItemEncryptedContainerMock: VaultItemEncryptedContainer {
    var id: UUID
    var exampleKey: String = "exampleValue"
    var title: String = "hello"
}

struct VaultItemEncryptableMock: Equatable, VaultItemEncryptable {
    typealias EncryptedContainer = VaultItemEncryptedContainerMock
    var id: UUID

    init(id: UUID) {
        self.id = id
    }

    init(encryptedContainer: VaultItemEncryptedContainerMock) {
        self = .init(id: encryptedContainer.id)
    }

    func makeEncryptedContainer() throws -> VaultItemEncryptedContainerMock {
        .init(id: id)
    }
}
