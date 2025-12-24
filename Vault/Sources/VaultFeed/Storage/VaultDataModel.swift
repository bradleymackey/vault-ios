// swiftlint:disable:next no_preconcurrency
@preconcurrency import AuthenticationServices
import Combine
import Foundation
import FoundationExtensions
import VaultKeygen

/// Provides access to the vault data layer for the UI layer.
///
/// Uses the underlying data stores and provides observations to the underlying data when it changes.
/// This should be the primary way to interact with the vault data layer (and its underlying stores),
/// to ensure that we have a consistent view of the available data at all times, regardless of the view.
///
/// This is isolated to the main actor for the purposes of UI interop.
@MainActor
@Observable
public final class VaultDataModel {
    public enum State {
        case base, loaded, loading
    }

    // MARK: Searching Items

    public var itemsSearchQuery: String = ""
    public var itemsFilteringByTags: Set<Identifier<VaultItemTag>> = []
    public var itemSearchHash: Int {
        var hasher = Hasher()
        hasher.combine(itemsSearchQuery)
        hasher.combine(itemsFilteringByTags)
        return hasher.finalize()
    }

    public var isSearching: Bool {
        itemsSanitizedQuery != nil
    }

    public var feedTitle: String {
        if isSearching {
            localized(key: "feedViewModel.searching.title.\(items.count)")
        } else {
            localized(key: "feedViewModel.list.title")
        }
    }

    public var filteringByTagsDescription: String {
        localized(key: "feed.searching.filteringByTags.\(itemsFilteringByTags.count)")
    }

    private var itemsSanitizedQuery: String? {
        let trimmed = itemsSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isNotEmpty else { return nil }
        return trimmed
    }

    // MARK: Items

    public var items = [VaultItem]()
    public private(set) var hasAnyItems = false
    public private(set) var itemErrors = [VaultRetrievalResult<VaultItem>.Error]()
    public private(set) var itemsState: State = .base
    public private(set) var itemsRetrievalError: PresentationError?
    public var itemCaches: [any VaultItemCache]

    // MARK: Tags

    public var allTags = [VaultItemTag]()
    public private(set) var allTagsState: State = .base
    public private(set) var allTagsRetrievalError: PresentationError?

    // MARK: - Backup Password

    public enum BackupPasswordState: Sendable, Equatable {
        case notFetched
        case notCreated
        case fetched(DerivedEncryptionKey)
        case error(PresentationError)

        public var fetchedPassword: DerivedEncryptionKey? {
            switch self {
            case let .fetched(password): password
            default: nil
            }
        }

        public var isRetryable: Bool {
            switch self {
            case .error, .notFetched: true
            case .notCreated, .fetched: false
            }
        }

        public var isError: Bool {
            switch self {
            case .error: true
            default: false
            }
        }
    }

    public private(set) var backupPassword: BackupPasswordState = .notFetched
    public private(set) var backupPasswordLoadingState: LoadingState = .notLoading

    // MARK: - Backup Events

    /// The last time the user's vault was backed up.
    /// This will always be kept up-to-date.
    public private(set) var lastBackupEvent: VaultBackupEvent?

    /// An up-to-date hash of the current user data payload.
    /// This is so it can be compared to the last backup event to see if we have any changes.
    public private(set) var currentPayloadHash: Digest<VaultApplicationPayload>.SHA256?

    // MARK: - Init

    private let vaultStore: any VaultStore
    private let vaultTagStore: any VaultTagStore
    private let vaultImporter: any VaultStoreImporter
    private let vaultDeleter: any VaultStoreDeleter
    private let vaultKillphraseDeleter: any VaultStoreKillphraseDeleter
    private let vaultOtpAutofillStore: any VaultOTPAutofillStore
    private let backupPasswordStore: any BackupPasswordStore
    private let backupEventLogger: any BackupEventLogger
    private var observationBag = Set<AnyCancellable>()

    public init(
        vaultStore: any VaultStore,
        vaultTagStore: any VaultTagStore,
        vaultImporter: any VaultStoreImporter,
        vaultDeleter: any VaultStoreDeleter,
        vaultKillphraseDeleter: any VaultStoreKillphraseDeleter,
        vaultOtpAutofillStore: any VaultOTPAutofillStore,
        backupPasswordStore: any BackupPasswordStore,
        backupEventLogger: any BackupEventLogger,
        itemCaches: [any VaultItemCache] = [],
    ) {
        self.vaultStore = vaultStore
        self.vaultTagStore = vaultTagStore
        self.vaultImporter = vaultImporter
        self.vaultDeleter = vaultDeleter
        self.vaultKillphraseDeleter = vaultKillphraseDeleter
        self.vaultOtpAutofillStore = vaultOtpAutofillStore
        self.backupPasswordStore = backupPasswordStore
        self.backupEventLogger = backupEventLogger
        self.itemCaches = itemCaches

        monitorBackupEvents()
    }

    /// Initial setup to ensure the model is in a good state.
    public func setup() async {
        await updateCurrentPayloadHash()
    }

    private func monitorBackupEvents() {
        lastBackupEvent = backupEventLogger.lastBackupEvent()
        backupEventLogger.loggedEventPublisher.sink { [weak self] newEvent in
            self?.lastBackupEvent = newEvent
        }.store(in: &observationBag)
    }

    /// Updates the current payload hash in the background.
    private func updateCurrentPayloadHash() async {
        currentPayloadHash = try? await computeVaultHash()
    }

    private nonisolated func computeVaultHash() async throws -> Digest<VaultApplicationPayload>.SHA256 {
        let exported = try await vaultStore.exportVault(userDescription: "")
        return try Digest<VaultApplicationPayload>.SHA256.makeHash(exported)
    }
}

// MARK: - Helpers

extension VaultDataModel {
    private func invalidateCaches(itemID: Identifier<VaultItem>) async {
        for itemCache in itemCaches {
            await itemCache.vaultItemCacheClear(forVaultItemWithID: itemID)
        }
    }

    public func code(id: Identifier<VaultItem>) -> VaultItem? {
        items.first(where: { $0.id == id })
    }

    public func toggleFiltering(tag: Identifier<VaultItemTag>) {
        if itemsFilteringByTags.contains(tag) {
            itemsFilteringByTags.remove(tag)
        } else {
            itemsFilteringByTags.insert(tag)
        }
    }

    /// Ensures that any sensitive data is removed from memory.
    public func purgeSensitiveData() {
        backupPassword = .notFetched
        backupPasswordLoadingState = .notLoading
    }
}

// MARK: - Backup Password

extension VaultDataModel {
    public func loadBackupPassword() async {
        do {
            if case .fetched = backupPassword { return }
            backupPasswordLoadingState = .loading
            defer { backupPasswordLoadingState = .notLoading }
            let password = try await backupPasswordStore.fetchPassword()
            if let password {
                backupPassword = .fetched(password)
            } else {
                backupPassword = .notCreated
            }
        } catch {
            backupPassword = .error(PresentationError(
                userTitle: "Encryption Key Error",
                userDescription: "Unable to load encryption key from storage",
                debugDescription: error.localizedDescription,
            ))
        }
    }

    public func store(backupPassword: DerivedEncryptionKey) async throws {
        try await backupPasswordStore.set(password: backupPassword)
        self.backupPassword = .fetched(backupPassword)
    }
}

// MARK: - Fetching

extension VaultDataModel {
    /// Reloads all data in the model.
    public func reloadData() async {
        await reloadTags()
        await reloadItems()
    }

    /// Reloads only the items of the model, based on the current query.
    public func reloadItems() async {
        do {
            let query = VaultStoreQuery(
                filterText: itemsSanitizedQuery,
                filterTags: itemsFilteringByTags,
            )
            await vaultKillphraseDeleter.deleteItems(matchingKillphrase: itemsSearchQuery)
            let result = try await vaultStore.retrieve(query: query)
            items = result.items
            itemErrors = result.errors
            itemsRetrievalError = nil
            hasAnyItems = try await vaultStore.hasAnyItems
        } catch {
            itemsRetrievalError = PresentationError(
                userTitle: "Error Loading",
                userDescription: "Unable to load items",
                debugDescription: error.localizedDescription,
            )
        }
    }

    /// Reloads only the tags of the model.
    public func reloadTags() async {
        do {
            allTags = try await vaultTagStore.retrieveTags()
            allTagsState = .loaded
        } catch {
            allTagsRetrievalError = PresentationError(
                userTitle: "Error Loading",
                userDescription: "Unable to load tags",
                debugDescription: error.localizedDescription,
            )
        }
    }
}

// MARK: - Writing

extension VaultDataModel {
    public func insert(item: VaultItem.Write) async throws {
        try await vaultStore.insert(item: item)
        await reloadItems()
    }

    public func update(itemID id: Identifier<VaultItem>, data: VaultItem.Write) async throws {
        try await vaultStore.update(id: id, item: data)
        await invalidateCaches(itemID: id)
        await reloadItems()
        await updateCurrentPayloadHash()
    }

    public func delete(itemID: Identifier<VaultItem>) async throws {
        try await vaultStore.delete(id: itemID)
        await invalidateCaches(itemID: itemID)
        await reloadItems()
        await updateCurrentPayloadHash()
    }

    public func reorder(items: Set<Identifier<VaultItem>>, to position: VaultReorderingPosition) async throws {
        try await vaultStore.reorder(items: items, to: position)
        // don't reload, assume UI state has reordered items directly
        await updateCurrentPayloadHash()
    }

    public func insert(tag: VaultItemTag.Write) async throws {
        try await vaultTagStore.insertTag(item: tag)
        await reloadTags()
        await updateCurrentPayloadHash()
    }

    public func update(tagID id: Identifier<VaultItemTag>, data: VaultItemTag.Write) async throws {
        try await vaultTagStore.updateTag(id: id, item: data)
        await reloadTags()
        await updateCurrentPayloadHash()
    }

    public func delete(tagID: Identifier<VaultItemTag>) async throws {
        try await vaultTagStore.deleteTag(id: tagID)
        await reloadTags()
        itemsFilteringByTags.remove(tagID)
        await reloadItems()
        await updateCurrentPayloadHash()
    }
}

extension VaultDataModel: VaultStoreHOTPIncrementer {
    public func incrementCounter(id: Identifier<VaultItem>) async throws {
        try await vaultStore.incrementCounter(id: id)
        await reloadItems()
    }
}

// MARK: - Import

extension VaultDataModel {
    public func importMerge(payload: VaultApplicationPayload) async throws {
        try await vaultImporter.importAndMergeVault(payload: payload)
        await reloadItems()
        await reloadTags()
        await updateCurrentPayloadHash()
    }

    public func importOverride(payload: VaultApplicationPayload) async throws {
        try await vaultImporter.importAndOverrideVault(payload: payload)
        await reloadItems()
        await reloadTags()
        await updateCurrentPayloadHash()
    }
}

// MARK: - Export

extension VaultDataModel {
    public func makeExport(userDescription: String) async throws -> VaultApplicationPayload {
        // No need to refetch items, this export is pulled directly from the store.
        try await vaultStore.exportVault(userDescription: userDescription)
    }
}

// MARK: - Delete

extension VaultDataModel {
    public func deleteVault() async throws {
        try await vaultDeleter.deleteVault()
        try await vaultOtpAutofillStore.removeAll()
        await reloadItems()
        await reloadTags()
    }
}

// MARK: - OTP Autofill Store

extension VaultDataModel {
    public func addDemoOTPItemToAutofillStore(
        issuer: String,
        accountName: String,
    ) async throws {
        let secret = try OTPAuthSecret.base32EncodedString("JBSWY3DPEHPK3PXP")
        let codeData = OTPAuthCodeData(
            secret: secret,
            algorithm: .sha1,
            digits: .default,
            accountName: accountName,
            issuer: issuer,
        )
        let code = OTPAuthCode(
            type: .totp(period: 30),
            data: codeData,
        )
        try await vaultOtpAutofillStore.update(
            id: UUID(),
            code: code,
        )
    }

    public func clearOTPAutofillStore() async throws {
        try await vaultOtpAutofillStore.removeAll()
    }

    public func getOTPAutofillStoreIdentities() async throws -> [ASOneTimeCodeCredentialIdentity] {
        try await vaultOtpAutofillStore.getAllIdentities()
    }

    public func removeOTPItemFromAutofillStore(id: UUID) async throws {
        try await vaultOtpAutofillStore.remove(id: id)
    }

    public func getOTPAutofillStoreState() async -> ASCredentialIdentityStoreState {
        await vaultOtpAutofillStore.getState()
    }
}
