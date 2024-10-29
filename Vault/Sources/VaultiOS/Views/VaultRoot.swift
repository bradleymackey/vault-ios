import Foundation
import FoundationExtensions
import SwiftSecurity
import VaultFeed
import VaultSettings

/// The root entrypoint for the vault application.
///
/// This is the composition root of the application.
@MainActor
enum VaultRoot {
    // MARK: - Primitives

    static let defaults: Defaults = .init(userDefaults: .standard)

    static let localSettings: LocalSettings = .init(defaults: defaults)

    static let timer: some IntervalTimer = IntervalTimerImpl()

    static let clock: some EpochClock = EpochClockImpl()

    static let fileManager: FileManager = .default

    static let pasteboard: Pasteboard = .init(SystemPasteboardImpl(clock: clock), localSettings: localSettings)

    // MARK: - Stores

    static let keychain: Keychain = .default

    static let secureStorage: some SecureStorage = SecureStorageImpl(keychain: keychain)

    static let vaultStore: PersistedLocalVaultStore = PersistedLocalVaultStoreFactory(fileManager: fileManager)
        .makeVaultStore()

    static let backupPasswordStore: some BackupPasswordStore = BackupPasswordStoreImpl(secureStorage: secureStorage)

    static let vaultDataModel: VaultDataModel = .init(
        vaultStore: vaultStore,
        vaultTagStore: vaultStore,
        vaultImporter: vaultStore,
        vaultDeleter: vaultStore,
        backupPasswordStore: backupPasswordStore,
        backupEventLogger: backupEventLogger
    )

    // MARK: - Previews

    static let secureNotePreviewViewGenerator: some ActionableVaultItemPreviewViewGenerator<SecureNote> =
        SecureNotePreviewViewGenerator(viewFactory: SecureNotePreviewViewFactoryImpl())

    static let otpCodeTimerUpdaterFactory: some OTPCodeTimerUpdaterFactory = OTPCodeTimerUpdaterFactoryImpl(
        timer: timer,
        clock: clock
    )

    static let totpPreviewRepository: some TOTPPreviewViewRepository = {
        let repo = TOTPPreviewViewRepositoryImpl(
            clock: clock,
            timer: timer,
            updaterFactory: otpCodeTimerUpdaterFactory
        )
        vaultDataModel.itemCaches.append(repo)
        return repo
    }()

    static let totpPreviewViewGenerator: some ActionableVaultItemPreviewViewGenerator<TOTPAuthCode> =
        TOTPPreviewViewGenerator(
            viewFactory: TOTPPreviewViewFactoryImpl(),
            repository: totpPreviewRepository
        )

    static let hotpPreviewRepository: some HOTPPreviewViewRepository = {
        let repo = HOTPPreviewViewRepositoryImpl(
            timer: timer,
            store: vaultDataModel
        )
        vaultDataModel.itemCaches.append(repo)
        return repo
    }()

    static let hotpPreviewViewGenerator: some ActionableVaultItemPreviewViewGenerator<HOTPAuthCode> =
        HOTPPreviewViewGenerator(
            viewFactory: HOTPPreviewViewFactoryImpl(),
            repository: hotpPreviewRepository
        )

    // MARK: - Misc

    static let vaultKeyDeriverFactory: some VaultKeyDeriverFactory = VaultKeyDeriverFactoryImpl()

    static let backupEventLogger: some BackupEventLogger = BackupEventLoggerImpl(defaults: defaults, clock: clock)

    static let encryptedVaultDecoder: some EncryptedVaultDecoder = EncryptedVaultDecoderImpl()

    static let deviceAuthenticationService: DeviceAuthenticationService = .init(policy: .default)

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
