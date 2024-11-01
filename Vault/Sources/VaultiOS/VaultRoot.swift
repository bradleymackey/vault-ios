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
        let groupID = "group.dev.mcky.vault.group"
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
        backupPasswordStore: backupPasswordStore,
        backupEventLogger: backupEventLogger
    )

    // MARK: - Previews

    @MainActor
    public static let vaultItemCopyHandler: some VaultItemCopyActionHandler =
        GenericVaultItemCopyActionHandler(childHandlers: [
            totpPreviewRepository,
            hotpPreviewRepository,
        ])

    @MainActor
    static let secureNotePreviewViewGenerator: some ActionableVaultItemPreviewViewGenerator<SecureNote> =
        SecureNotePreviewViewGenerator(viewFactory: SecureNotePreviewViewFactoryImpl())

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

    @MainActor
    public static let genericVaultItemPreviewViewGenerator: some VaultItemPreviewViewGenerator<VaultItem.Payload> =
        GenericVaultItemPreviewViewGenerator(
            totpGenerator: totpPreviewViewGenerator,
            hotpGenerator: hotpPreviewViewGenerator,
            noteGenerator: secureNotePreviewViewGenerator
        )

    @MainActor
    static let totpPreviewViewGenerator: some ActionableVaultItemPreviewViewGenerator<TOTPAuthCode> =
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
    static let hotpPreviewViewGenerator: some ActionableVaultItemPreviewViewGenerator<HOTPAuthCode> =
        HOTPPreviewViewGenerator(
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
