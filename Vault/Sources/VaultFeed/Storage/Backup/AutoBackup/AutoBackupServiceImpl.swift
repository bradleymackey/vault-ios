import Combine
import CryptoEngine
import Foundation
import FoundationExtensions
import PDFKit
import VaultBackup
import VaultCore
import VaultExport
import VaultKeygen

/// Default implementation of AutoBackupService.
@MainActor
public final class AutoBackupServiceImpl: AutoBackupService {
    // MARK: - Public Properties

    public private(set) var status: AutoBackupStatus = .disabled
    public private(set) var configuration: AutoBackupConfiguration

    public var availableProviders: [any BackupStorageProvider] {
        providers
    }

    public var selectedProvider: (any BackupStorageProvider)? {
        guard let providerID = configuration.providerID else { return nil }
        return providers.first { $0.id == providerID }
    }

    // MARK: - Publishers

    private let statusSubject = PassthroughSubject<AutoBackupStatus, Never>()
    private let configurationSubject = PassthroughSubject<AutoBackupConfiguration, Never>()

    public var statusPublisher: AnyPublisher<AutoBackupStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    public var configurationPublisher: AnyPublisher<AutoBackupConfiguration, Never> {
        configurationSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let dataModel: VaultDataModel
    private let backupEventLogger: any BackupEventLogger
    private let clock: any EpochClock
    private let defaults: Defaults
    private let providers: [any BackupStorageProvider]

    private var observationBag = Set<AnyCancellable>()
    private var debounceTask: Task<Void, Never>?

    private static let configKey = Key<AutoBackupConfiguration>(VaultIdentifiers.AutoBackup.configuration)
    private static let debounceSeconds: UInt64 = 5

    // MARK: - Init

    public init(
        dataModel: VaultDataModel,
        backupEventLogger: any BackupEventLogger,
        clock: any EpochClock,
        defaults: Defaults,
        providers: [any BackupStorageProvider],
    ) {
        self.dataModel = dataModel
        self.backupEventLogger = backupEventLogger
        self.clock = clock
        self.defaults = defaults
        self.providers = providers
        configuration = defaults.get(for: Self.configKey) ?? AutoBackupConfiguration()

        Task {
            await restoreProviderConfigurations()
            updateStatus()
        }
    }

    // MARK: - Configuration

    public func setEnabled(_ enabled: Bool) async {
        configuration.isEnabled = enabled
        await saveConfiguration()
        updateStatus()

        if enabled {
            await triggerBackupIfNeeded()
        }
    }

    public func selectProvider(id: String) async {
        configuration.providerID = id
        await saveConfiguration()
        // Don't call updateStatus() here - selecting a provider shouldn't reset error states
    }

    public func setRetention(_ retention: AutoBackupRetention) async {
        configuration.retentionDays = retention
        await saveConfiguration()

        // Run cleanup with new retention settings
        await cleanupOldBackups()
    }

    // MARK: - Backup Operations

    public func triggerBackupIfNeeded() async {
        guard configuration.isEnabled else { return }
        guard let provider = selectedProvider else { return }
        guard await provider.isConfigured else { return }

        // Check if hash has changed since last backup
        if let currentHash = dataModel.currentPayloadHash?.value.base64EncodedString(),
           let lastHash = configuration.lastBackupHash,
           currentHash == lastHash
        {
            // No changes since last backup
            return
        }

        await performBackup()
    }

    public func forceBackup() async {
        await performBackup()
    }

    public func saveProviderConfiguration() async {
        await saveConfiguration()
    }

    public func cleanupOldBackups() async {
        guard configuration.retentionDays.shouldCleanup else { return }
        guard let provider = selectedProvider else { return }
        guard await provider.isConfigured else { return }

        setStatus(.cleaningUp)

        do {
            let backups = try await provider.listBackups()
            let cutoffDate = Calendar.current.date(
                byAdding: .day,
                value: -configuration.retentionDays.rawValue,
                to: clock.currentDate,
            ) ?? clock.currentDate

            for backup in backups where backup.createdDate < cutoffDate {
                try await provider.delete(filename: backup.filename)
            }

            updateStatus()
        } catch {
            setStatus(.error(.cleanupFailed(reason: error.localizedDescription)))
        }
    }

    // MARK: - Monitoring

    public func startMonitoring() {
        // Observe payload hash changes from data model
        // Since VaultDataModel uses @Observable, we need to use a different approach
        // We'll check on each relevant operation instead
    }

    public func stopMonitoring() {
        debounceTask?.cancel()
        debounceTask = nil
        observationBag.removeAll()
    }

    /// Called by external code when data changes are detected.
    /// This should be called after any vault mutation.
    public func notifyDataChanged() {
        guard configuration.isEnabled else { return }

        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.debounceSeconds * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await triggerBackupIfNeeded()
        }
    }

    // MARK: - Private

    private func performBackup() async {
        guard let provider = selectedProvider else {
            setStatus(.error(.noProviderSelected))
            return
        }

        guard await provider.isConfigured else {
            setStatus(.error(.providerNotConfigured))
            return
        }

        guard await provider.isAvailable else {
            setStatus(.error(.providerUnavailable(reason: "Provider is not available")))
            return
        }

        guard case let .fetched(backupPassword) = dataModel.backupPassword else {
            setStatus(.error(.backupPasswordNotSet))
            return
        }

        setStatus(.backingUp)

        do {
            // Generate PDF
            let pdfData = try await generateBackupPDF(backupPassword: backupPassword)

            // Create filename with timestamp
            let timestamp = VaultDateFormatter(timezone: .current).formatForFileName(date: clock.currentDate)
            let filename = "vault-auto-backup-\(timestamp).pdf"

            // Write to provider
            try await provider.write(data: pdfData, filename: filename)

            // Update configuration with last backup info
            if let hash = dataModel.currentPayloadHash {
                configuration.lastBackupHash = hash.value.base64EncodedString()
            }
            configuration.lastBackupDate = clock.currentDate
            await saveConfiguration()

            // Log the event
            if let hash = dataModel.currentPayloadHash {
                backupEventLogger.exportedToAutoBackup(
                    date: clock.currentDate,
                    hash: hash,
                    providerID: provider.id,
                )
            }

            setStatus(.completed(clock.currentDate))

            // Clean up old backups
            await cleanupOldBackups()

        } catch let error as AutoBackupError {
            setStatus(.error(error))
        } catch {
            setStatus(.error(.unknown(reason: error.localizedDescription)))
        }
    }

    private func generateBackupPDF(backupPassword: DerivedEncryptionKey) async throws -> Data {
        // Get vault payload
        let payload = try await dataModel.makeExport(userDescription: "Auto-backup")

        // Encrypt the payload
        let encoder = EncryptedVaultEncoder(clock: clock, backupPassword: backupPassword)
        let encryptedVault = try encoder.encryptAndEncode(payload: payload)

        // Create export payload
        let exportPayload = VaultExportPayload(
            encryptedVault: encryptedVault,
            userDescription: "Automatic backup created by Vault",
            created: clock.currentDate,
        )

        // Generate PDF
        let pdfGenerator = VaultBackupPDFGenerator(
            size: A4DocumentSize(),
            documentTitle: "Auto-Backup",
            applicationName: "Vault",
            authorName: "Vault",
        )

        let pdfDocument = try pdfGenerator.makePDF(payload: exportPayload)

        guard let pdfData = pdfDocument.dataRepresentation() else {
            throw AutoBackupError.pdfGenerationFailed(reason: "Failed to get PDF data")
        }

        return pdfData
    }

    private func setStatus(_ newStatus: AutoBackupStatus) {
        status = newStatus
        statusSubject.send(newStatus)
    }

    private func updateStatus() {
        if !configuration.isEnabled {
            setStatus(.disabled)
        } else if let lastBackupDate = configuration.lastBackupDate {
            setStatus(.completed(lastBackupDate))
        } else {
            setStatus(.idle)
        }
    }

    private func saveConfiguration() async {
        // Save provider-specific configs
        for provider in providers {
            if let configData = await provider.configurationData {
                configuration.providerConfigs[provider.id] = configData
            }
        }

        try? defaults.set(configuration, for: Self.configKey)
        configurationSubject.send(configuration)
    }

    private func restoreProviderConfigurations() async {
        for provider in providers {
            if let configData = configuration.providerConfigs[provider.id] {
                try? await provider.restoreConfiguration(from: configData)
            }
        }
    }
}
