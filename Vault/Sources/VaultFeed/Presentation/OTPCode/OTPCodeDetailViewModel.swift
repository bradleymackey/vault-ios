import Combine
import Foundation
import FoundationExtensions
import VaultCore

@MainActor
@Observable
public final class OTPCodeDetailViewModel: DetailViewModel {
    public var editingModel: DetailEditingModel<OTPCodeDetailEdits>

    public enum Mode {
        case creating(initialCode: OTPAuthCode? = nil)
        case editing(code: OTPAuthCode, metadata: StoredVaultItem.Metadata)
    }

    public let mode: Mode
    private let editor: any OTPCodeDetailEditor
    private let detailEditState = DetailEditState<OTPCodeDetailEdits>()
    private let didEncounterErrorSubject = PassthroughSubject<any Error, Never>()
    private let isFinishedSubject = PassthroughSubject<Void, Never>()

    public init(
        mode: Mode,
        editor: any OTPCodeDetailEditor
    ) {
        self.mode = mode
        self.editor = editor

        editingModel = switch mode {
        case .creating(.none):
            .init(detail: .new())
        case let .creating(.some(initialCode)):
            .init(
                detail: OTPCodeDetailEdits(
                    hydratedFromCode: initialCode,
                    userDescription: "",
                    color: nil,
                    visibility: .always,
                    searchableLevel: .full,
                    searchPassphrase: ""
                ),
                isInitiallyDirty: true
            )
        case let .editing(code, metadata):
            .init(detail: OTPCodeDetailEdits(
                hydratedFromCode: code,
                userDescription: metadata.userDescription,
                color: metadata.color,
                visibility: metadata.visibility,
                searchableLevel: metadata.searchableLevel,
                searchPassphrase: metadata.searchPassphrase ?? ""
            ))
        }
    }

    public var isInitialCreation: Bool {
        switch mode {
        case .creating: true
        case .editing: false
        }
    }

    public var showsKeyEditingFields: Bool {
        switch mode {
        case .creating(.none): true
        case .creating(.some(_)): false
        case .editing: false
        }
    }

    public var isSaving: Bool {
        detailEditState.isSaving
    }

    public var isInEditMode: Bool {
        detailEditState.isInEditMode
    }

    public var visibleIssuerTitle: String {
        if editingModel.detail.issuerTitle.isNotEmpty {
            editingModel.detail.issuerTitle
        } else {
            strings.siteNameEmptyTitle
        }
    }

    public var detailMenuItems: [DetailEntry] {
        var entries = [DetailEntry]()
        if let createdDate = createdDateValue {
            entries.append(DetailEntry(title: strings.createdDateTitle, detail: createdDate, systemIconName: "clock"))
        }

        if let updateDate = updatedDateValue {
            entries.append(DetailEntry(
                title: strings.updatedDateTitle,
                detail: updateDate,
                systemIconName: "clock.arrow.2.circlepath"
            ))
        }

        entries.append(DetailEntry(
            title: strings.searchableLevelTitle,
            detail: editingModel.detail.searchableLevel.localizedTitle,
            systemIconName: editingModel.detail.searchableLevel.systemIconName
        ))

        entries.append(DetailEntry(
            title: strings.visibilityTitle,
            detail: editingModel.detail.visibility.localizedTitle,
            systemIconName: editingModel.detail.visibility.systemIconName
        ))

        switch mode {
        case .creating:
            break
        case let .editing(code, _):
            let formatter = OTPCodeDetailFormatter(code: code)
            entries.append(
                DetailEntry(
                    title: localized(key: "codeDetail.listSection.type.title"),
                    detail: formatter.typeName,
                    systemIconName: "tag.fill"
                )
            )
            if let period = formatter.period {
                entries.append(
                    DetailEntry(
                        title: localized(key: "codeDetail.listSection.period.title"),
                        detail: period,
                        systemIconName: "clock.fill"
                    )
                )
            }
            entries.append(
                DetailEntry(
                    title: localized(key: "codeDetail.listSection.digits.title"),
                    detail: formatter.digits,
                    systemIconName: "number"
                )
            )
            entries.append(
                DetailEntry(
                    title: localized(key: "codeDetail.listSection.algorithm.title"),
                    detail: formatter.algorithm,
                    systemIconName: "lock.laptopcomputer"
                )
            )
            entries.append(
                DetailEntry(
                    title: localized(key: "codeDetail.listSection.secretFormat.title"),
                    detail: formatter.secretType,
                    systemIconName: "lock.fill"
                )
            )
        }

        return entries
    }

    public func didEncounterErrorPublisher() -> AnyPublisher<any Error, Never> {
        didEncounterErrorSubject.eraseToAnyPublisher()
    }

    /// Publishes when we are done looking at a given code, and should dismiss.
    public func isFinishedPublisher() -> AnyPublisher<Void, Never> {
        isFinishedSubject.eraseToAnyPublisher()
    }

    public func startEditing() {
        detailEditState.startEditing()
    }

    public func saveChanges() async {
        do {
            try await detailEditState.saveChanges {
                switch mode {
                case .creating:
                    try await editor.createCode(initialEdits: editingModel.detail)
                    isFinishedSubject.send()
                case let .editing(code, metadata):
                    try await editor.updateCode(id: metadata.id, item: code, edits: editingModel.detail)
                    editingModel.didPersist()
                }
            }
        } catch {
            didEncounterErrorSubject.send(error)
        }
    }

    public func delete() async {
        await deleteCode()
    }

    public func deleteCode() async {
        switch mode {
        case .creating:
            break // noop
        case let .editing(_, metadata):
            do {
                try await detailEditState.deleteItem {
                    try await editor.deleteCode(id: metadata.id)
                } finished: {
                    isFinishedSubject.send()
                }
            } catch {
                didEncounterErrorSubject.send(error)
            }
        }
    }

    public func done() {
        detailEditState.exitCurrentModeClearingDirtyState {
            editingModel.restoreInitialState()
        } finished: {
            isFinishedSubject.send()
        }
    }
}

// MARK: - Titles

extension OTPCodeDetailViewModel {
    @MainActor
    public struct Strings: DetailViewModelStrings {
        static let shared = Strings()
        private init() {}

        public let title = localized(key: "codeDetail.title")
        public let deleteConfirmTitle = localized(key: "codeDetail.action.delete.confirm.title")
        public let deleteItemTitle = localized(key: "codeDetail.action.delete.entity.title")
        public let deleteConfirmSubtitle = localized(key: "codeDetail.action.delete.confirm.subtitle")
        public let createdDateTitle = localized(key: "codeDetail.listSection.created.title")
        public let updatedDateTitle = localized(key: "codeDetail.listSection.updated.title")
        public let doneEditingTitle = localized(key: "feedViewModel.doneEditing.title")
        public let saveEditsTitle = localized(key: "feedViewModel.saveEdits.title")
        public let cancelEditsTitle = localized(key: "feedViewModel.cancelEdits.title")
        public let startEditingTitle = localized(key: "feedViewModel.edit.title")
        public let siteNameTitle = localized(key: "codeDetail.field.siteName.title")
        public let siteNameEmptyTitle = localized(key: "codeDetail.field.siteName.empty.title")
        public let accountNameTitle = localized(key: "codeDetail.field.accountName.title")
        public let accountNameExample = localized(key: "codeDetail.field.accountName.example")
        public let descriptionTitle = localized(key: "codeDetail.description.title")
        public let descriptionSubtitle = localized(key: "codeDetail.description.subtitle")
        public let codeDetailsSectionTitle = localized(key: "codeDetail.section.codeDetails")
        public let inputTotpPeriodTitle = localized(key: "codeDetail.field.totpPeriod.title")
        public let inputHotpCounterTitle = localized(key: "codeDetail.field.hotpCounter.title")
        public let inputCodeTypeTitle = localized(key: "codeDetail.input.codeType.title")
        public let inputAlgorithmTitle = localized(key: "codeDetail.input.algorithm.title")
        public let inputNumberOfDigitsTitle = localized(key: "codeDetail.input.numberOfDigits.title")
        public let advancedSectionTitle = localized(key: "codeDetail.section.advanced.title")
        public let inputSecretTitle = localized(key: "codeDetail.field.secret.title")
        public let inputEnterCodeManually = localized(key: "codeDetail.input.enterCodeManually.title")
        public let inputPickScannerImage = localized(key: "codeDetail.input.pickScannerImage.title")
        public let inputKeyValidTitle = localized(key: "codeDetail.input.key.valid.title")
        public let inputKeyErrorTitle = localized(key: "codeDetail.input.key.error.title")
        public let inputKeyEmptyTitle = localized(key: "codeDetail.input.key.enterText.title")
        public let visibilityTitle = localized(key: "itemDetail.visibilitySection.title")
        public let shownInTitle = localized(key: "itemDetail.visibility.title")
        public let shownInSubtitle = localized(key: "itemDetail.visibility.subtitle")
        public let searchableLevelTitle = localized(key: "itemDetail.searchableLevel.title")
        public let searchableLevelSubtitle = localized(key: "noteDetail.searchableLevel.subtitle")
        public let passphraseTitle = localized(key: "itemDetail.passphrase.title")
        public let passphrasePrompt = localized(key: "itemDetail.passphrase.prompt")
        public let passphraseSubtitle = localized(key: "itemDetail.passphrase.subtitle")

        public func codeKindTitle(kind: OTPAuthType.Kind) -> String {
            switch kind {
            case .totp: localized(key: "codeDetail.typeName.totp")
            case .hotp: localized(key: "codeDetail.typeName.hotp")
            }
        }
    }

    public var strings: Strings {
        Strings.shared
    }

    public var createdDateValue: String? {
        switch mode {
        case let .editing(_, metadata):
            metadata.created.formatted(date: .abbreviated, time: .shortened)
        default:
            nil
        }
    }

    public var updatedDateValue: String? {
        switch mode {
        case let .editing(_, metadata) where metadata.created != metadata.updated:
            metadata.updated.formatted(date: .abbreviated, time: .shortened)
        default:
            nil
        }
    }
}
