import Foundation

@MainActor
@Observable
public final class BackupImportViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case error(PresentationError)
        case success
    }

    public private(set) var state: State = .idle

    public init() {}
}
