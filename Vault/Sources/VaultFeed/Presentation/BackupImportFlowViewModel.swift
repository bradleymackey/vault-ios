import Foundation

@MainActor
@Observable
public final class BackupImportFlowViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case error(PresentationError)
        case success
    }

    public enum ImportContext: Equatable {
        case toEmptyVault
        case merge
        case override
    }

    public private(set) var state: State = .idle
    public let importContext: ImportContext

    public init(importContext: ImportContext) {
        self.importContext = importContext
    }
}
