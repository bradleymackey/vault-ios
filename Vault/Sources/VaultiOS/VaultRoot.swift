import Foundation
import FoundationExtensions
import SwiftSecurity
import VaultFeed
import VaultSettings

/// The root entrypoint for the vault application.
///
/// This is the composition root of the application.
public enum VaultRoot {
    // MARK: - Primitives

    @MainActor
    public static let defaults: Defaults = .init(userDefaults: .standard)

    @MainActor
    public static let localSettings: LocalSettings = .init(defaults: defaults)

    public static let timer: some IntervalTimer = IntervalTimerImpl()

    public static let clock: some EpochClock = EpochClockImpl()

    @MainActor
    public static let fileManager: FileManager = .default

    @MainActor
    public static let pasteboard: Pasteboard = .init(SystemPasteboardImpl(clock: clock), localSettings: localSettings)

    // MARK: - Stores

    public static let keychain: Keychain = .default

    public static let secureStorage: some SecureStorage = SecureStorageImpl(keychain: keychain)

    @MainActor
    static let vaultStorageDirectory: URL = {
        let groupID = "group.com.badbundle.vault-group"
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            fatalError("Unable to access the provided directory")
        }
        return url
    }()

    @MainActor
    public static let vaultStore: PersistedLocalVaultStore =
        PersistedLocalVaultStoreFactory(storageDirectory: vaultStorageDirectory)
            .makeVaultStore()

    public static let backupPasswordStore: some BackupPasswordStore =
        BackupPasswordStoreImpl(secureStorage: secureStorage)

    @MainActor
    public static let vaultDataModel: VaultDataModel = .init(
        vaultStore: vaultStore,
        vaultTagStore: vaultStore,
        vaultImporter: vaultStore,
        vaultDeleter: vaultStore,
        vaultKillphraseDeleter: vaultStore,
        backupPasswordStore: backupPasswordStore,
        backupEventLogger: backupEventLogger
    )

    // MARK: - Previews

    /// Performs the actions in order if it is able.
    ///
    /// We prefer copying text over opening item details.
    /// Therefore, we first of all try to copy text from the available repositories that support
    /// copying and, failing that, we then open the item detail.
    @MainActor
    static let vaultItemPreviewActionHandler: some VaultItemPreviewActionHandler =
        VaultItemPreviewActionHandlerPrefersTextCopy(copyHandlers: [vaultItemCopyHandler])

    /// Available data sources for providing text to copy.
    @MainActor
    public static let vaultItemCopyHandler: some VaultItemCopyActionHandler =
        GenericVaultItemCopyActionHandler(childHandlers: [
            totpPreviewRepository,
            hotpPreviewRepository,
        ])

    @MainActor
    static let secureNotePreviewViewGenerator =
        SecureNotePreviewViewGenerator(viewFactory: SecureNotePreviewViewFactoryImpl())

    @MainActor
    static let encryptedItemPreviewViewGenerator =
        EncryptedItemPreviewViewGenerator(viewFactory: EncryptedItemPreviewViewFactoryImpl())

    @MainActor
    static let otpCodeTimerUpdaterFactory: some OTPCodeTimerUpdaterFactory = OTPCodeTimerUpdaterFactoryImpl(
        timer: timer,
        clock: clock
    )

    @MainActor
    static let totpPreviewRepository: some TOTPPreviewViewRepository = {
        let repo = TOTPPreviewViewRepositoryImpl(
            clock: clock,
            timer: timer,
            updaterFactory: otpCodeTimerUpdaterFactory
        )
        vaultDataModel.itemCaches.append(repo)
        return repo
    }()

    // Ideally this would just vend the generic `some VaultItemPreviewViewGenerator<VaultItem.Payload>`
    // But that currently gives us a compiler error (only while archiving?!) so let's vend the full (massive) concrete
    // type for now :(
    @MainActor
    public static let genericVaultItemPreviewViewGenerator =
        GenericVaultItemPreviewViewGenerator(
            totpGenerator: totpPreviewViewGenerator,
            hotpGenerator: hotpPreviewViewGenerator,
            noteGenerator: secureNotePreviewViewGenerator,
            encryptedGenerator: encryptedItemPreviewViewGenerator
        )

    @MainActor
    static let totpPreviewViewGenerator =
        TOTPPreviewViewGenerator(
            viewFactory: TOTPPreviewViewFactoryImpl(),
            repository: totpPreviewRepository
        )

    @MainActor
    static let hotpPreviewRepository: some HOTPPreviewViewRepository = {
        let repo = HOTPPreviewViewRepositoryImpl(
            timer: timer,
            store: vaultDataModel
        )
        vaultDataModel.itemCaches.append(repo)
        return repo
    }()

    @MainActor
    static let hotpPreviewViewGenerator = HOTPPreviewViewGenerator(
        viewFactory: HOTPPreviewViewFactoryImpl(),
        repository: hotpPreviewRepository
    )

    // MARK: - Misc

    @MainActor
    public static let vaultKeyDeriverFactory: some VaultKeyDeriverFactory = VaultKeyDeriverFactoryImpl()

    @MainActor
    static let backupEventLogger: some BackupEventLogger = BackupEventLoggerImpl(defaults: defaults, clock: clock)

    static let encryptedVaultDecoder: some EncryptedVaultDecoder = EncryptedVaultDecoderImpl()

    @MainActor
    public static let deviceAuthenticationService: DeviceAuthenticationService = .init(policy: .default)

    @MainActor
    public static let vaultInjector: VaultInjector = .init(
        clock: clock,
        intervalTimer: timer,
        backupEventLogger: backupEventLogger,
        vaultKeyDeriverFactory: vaultKeyDeriverFactory,
        encryptedVaultDecoder: encryptedVaultDecoder,
        defaults: defaults,
        fileManager: fileManager
    )
}
