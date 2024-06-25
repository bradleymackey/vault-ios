import Combine
import Foundation
import VaultCore

@MainActor
@Observable
public final class SecureNoteDetailViewModel: DetailViewModel {
    public var editingModel: DetailEditingModel<SecureNoteDetailEdits>

    public enum Mode {
        case creating
        case editing(note: SecureNote, metadata: VaultItem.Metadata)
    }

    private let mode: Mode
    private let detailEditState = DetailEditState<SecureNoteDetailEdits>()
    private let didEncounterErrorSubject = PassthroughSubject<any Error, Never>()
    private let isFinishedSubject = PassthroughSubject<Void, Never>()
    private let editor: any SecureNoteDetailEditor

    /// Create a view model for an existing note.
    public init(mode: Mode, editor: any SecureNoteDetailEditor) {
        self.mode = mode
        self.editor = editor
        editingModel = switch mode {
        case .creating:
            .init(detail: .new())
        case let .editing(note, metadata):
            .init(detail: .init(
                title: note.title,
                description: metadata.userDescription,
                contents: note.contents,
                color: metadata.color,
                visibility: metadata.visibility,
                searchableLevel: metadata.searchableLevel,
                searchPassphrase: metadata.searchPassphrase ?? "",
                tags: metadata.tags
            ))
        }
    }

    public var isInEditMode: Bool {
        detailEditState.isInEditMode
    }

    public var isSaving: Bool {
        detailEditState.isSaving
    }

    /// The configured title of the note, as viewed by the user.
    public var visibleTitle: String {
        if editingModel.detail.title.isNotEmpty {
            editingModel.detail.title
        } else {
            strings.noteEmptyTitleTitle
        }
    }

    public var isInitialCreation: Bool {
        switch mode {
        case .creating: true
        case .editing: false
        }
    }

    public func startEditing() {
        detailEditState.startEditing()
    }

    public func didEncounterErrorPublisher() -> AnyPublisher<any Error, Never> {
        didEncounterErrorSubject.eraseToAnyPublisher()
    }

    /// When we are done looking at the detail page and should submit.
    public func isFinishedPublisher() -> AnyPublisher<Void, Never> {
        isFinishedSubject.eraseToAnyPublisher()
    }

    public func saveChanges() async {
        do {
            try await detailEditState.saveChanges {
                switch mode {
                case .creating:
                    try await editor.createNote(initialEdits: editingModel.detail)
                    isFinishedSubject.send()
                case let .editing(note, metadata):
                    try await editor.updateNote(id: metadata.id, item: note, edits: editingModel.detail)
                    editingModel.didPersist()
                }
            }
        } catch {
            didEncounterErrorSubject.send(error)
        }
    }

    public func delete() async {
        await deleteNote()
    }

    public func deleteNote() async {
        switch mode {
        case .creating:
            break // noop
        case let .editing(_, metadata):
            do {
                try await detailEditState.deleteItem {
                    try await editor.deleteNote(id: metadata.id)
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

extension SecureNoteDetailViewModel {
    @MainActor
    public struct Strings: DetailViewModelStrings {
        static let shared = Strings()
        private init() {}

        public let title = localized(key: "noteDetail.title")
        public let deleteItemTitle = localized(key: "noteDetail.action.delete.entity.title")
        public let deleteConfirmTitle = localized(key: "noteDetail.action.delete.confirm.title")
        public let deleteConfirmSubtitle = localized(key: "noteDetail.action.delete.confirm.subtitle")
        public let descriptionTitle = localized(key: "noteDetail.description.title")
        public let descriptionSubtitle = localized(key: "noteDetail.description.subtitle")
        public let createdDateTitle = localized(key: "noteDetail.listSection.created.title")
        public let updatedDateTitle = localized(key: "noteDetail.listSection.updated.title")
        public let doneEditingTitle = localized(key: "feedViewModel.doneEditing.title")
        public let saveEditsTitle = localized(key: "feedViewModel.saveEdits.title")
        public let cancelEditsTitle = localized(key: "feedViewModel.cancelEdits.title")
        public let startEditingTitle = localized(key: "feedViewModel.edit.title")
        public let noteTitle = localized(key: "noteDetail.field.noteTitle.title")
        public let noteTitleExample = localized(key: "noteDetail.field.noteTitle.example")
        public let noteDescription = localized(key: "noteDetail.field.noteDescription.title")
        public let noteContentsTitle = localized(key: "noteDetail.field.noteContents.title")
        public let noteEmptyTitleTitle = localized(key: "noteDetail.field.noteTitleEmpty.title")
        public let noteVisibilityTitle = localized(key: "itemDetail.visibilitySection.title")
        public let noteShownInTitle = localized(key: "itemDetail.visibility.title")
        public let noteShownInSubtitle = localized(key: "itemDetail.visibility.subtitle")
        public let searchableLevelTitle = localized(key: "itemDetail.searchableLevel.title")
        public let searchableLevelSubtitle = localized(key: "noteDetail.searchableLevel.subtitle")
        public let passphraseTitle = localized(key: "itemDetail.passphrase.title")
        public let passphrasePrompt = localized(key: "itemDetail.passphrase.prompt")
        public let passphraseSubtitle = localized(key: "itemDetail.passphrase.subtitle")
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
        case let .editing(_, metadata) where metadata.updated > metadata.created.addingTimeInterval(5):
            metadata.updated.formatted(date: .abbreviated, time: .shortened)
        default:
            nil
        }
    }

    public var detailEntries: [DetailEntry] {
        var items = [DetailEntry]()
        if let createdDateValue {
            items.append(.init(title: strings.createdDateTitle, detail: createdDateValue, systemIconName: "clock"))
        }

        if let updatedDateValue {
            items.append(.init(
                title: strings.updatedDateTitle,
                detail: updatedDateValue,
                systemIconName: "clock.arrow.2.circlepath"
            ))
        }

        items.append(.init(
            title: strings.searchableLevelTitle,
            detail: editingModel.detail.searchableLevel.localizedTitle,
            systemIconName: editingModel.detail.searchableLevel.systemIconName
        ))

        items.append(.init(
            title: strings.noteVisibilityTitle,
            detail: editingModel.detail.visibility.localizedTitle,
            systemIconName: editingModel.detail.visibility.systemIconName
        ))
        return items
    }
}
