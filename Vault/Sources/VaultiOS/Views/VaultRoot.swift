import Foundation
import FoundationExtensions
import SwiftSecurity
import VaultFeed
import VaultSettings

/// The root entrypoint for the vault application.
///
/// This is the composition root of the application.
enum VaultRoot {
    // MARK: - Primitives

    @MainActor
    static let defaults: Defaults = .init(userDefaults: .standard)

    @MainActor
    static let localSettings: LocalSettings = .init(defaults: defaults)

    static let timer: some IntervalTimer = IntervalTimerImpl()

    static let clock: some EpochClock = EpochClockImpl()

    @MainActor
    static let fileManager: FileManager = .default

    @MainActor
    static let pasteboard: Pasteboard = .init(SystemPasteboardImpl(clock: clock), localSettings: localSettings)

    // MARK: - Stores

    static let keychain: Keychain = .default

    static let secureStorage: some SecureStorage = SecureStorageImpl(keychain: keychain)

    @MainActor
    static let vaultStore: PersistedLocalVaultStore = PersistedLocalVaultStoreFactory(fileManager: fileManager)
        .makeVaultStore()

    static let backupPasswordStore: some BackupPasswordStore = BackupPasswordStoreImpl(secureStorage: secureStorage)

    @MainActor
    static let vaultDataModel: VaultDataModel = .init(
        vaultStore: vaultStore,
        vaultTagStore: vaultStore,
        vaultImporter: vaultStore,
        vaultDeleter: vaultStore,
        backupPasswordStore: backupPasswordStore,
        backupEventLogger: backupEventLogger
    )

    // MARK: - Previews

    @MainActor
    static let vaultItemCopyHandler: some VaultItemCopyActionHandler =
        GenericVaultItemCopyActionHandler(childHandlers: [
            secureNotePreviewViewGenerator,
            totpPreviewViewGenerator,
            hotpPreviewViewGenerator,
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
    static let vaultKeyDeriverFactory: some VaultKeyDeriverFactory = VaultKeyDeriverFactoryImpl()

    @MainActor
    static let backupEventLogger: some BackupEventLogger = BackupEventLoggerImpl(defaults: defaults, clock: clock)

    static let encryptedVaultDecoder: some EncryptedVaultDecoder = EncryptedVaultDecoderImpl()

    @MainActor
    static let deviceAuthenticationService: DeviceAuthenticationService = .init(policy: .default)

    @MainActor
    static let vaultInjector: VaultInjector = .init(
        clock: clock,
        intervalTimer: timer,
        backupEventLogger: backupEventLogger,
        vaultKeyDeriverFactory: vaultKeyDeriverFactory,
        encryptedVaultDecoder: encryptedVaultDecoder,
        defaults: defaults,
        fileManager: fileManager
    )
}
