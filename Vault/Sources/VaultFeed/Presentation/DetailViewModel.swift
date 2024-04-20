import Combine
import Foundation

/// Common behaviours for the view model of an item's detail.
@MainActor
public protocol DetailViewModel: AnyObject, Observable {
    associatedtype Edits: Equatable
    associatedtype Strings: DetailViewModelStrings

    var editingModel: DetailEditingModel<Edits> { get set }
    var strings: Strings { get }
    var isInEditMode: Bool { get }
    var isSaving: Bool { get }

    func startEditing()
    func saveChanges() async
    func delete() async
    func done()
    func didEncounterErrorPublisher() -> AnyPublisher<any Error, Never>
    func isFinishedPublisher() -> AnyPublisher<Void, Never>
}

public protocol DetailViewModelStrings {
    var title: String { get }
    var cancelEditsTitle: String { get }
    var startEditingTitle: String { get }
    var saveEditsTitle: String { get }
    var doneEditingTitle: String { get }
    var deleteConfirmTitle: String { get }
    var deleteConfirmSubtitle: String { get }
    var deleteItemTitle: String { get }
}
