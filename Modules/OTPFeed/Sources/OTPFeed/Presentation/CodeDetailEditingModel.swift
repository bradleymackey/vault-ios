import Combine
import Foundation

@MainActor
public final class CodeDetailEditingModel: ObservableObject {
    @Published public var detail: CodeDetailEdits
    public private(set) var initialDetail: CodeDetailEdits

    public init(detail: CodeDetailEdits) {
        initialDetail = detail
        self.detail = detail
    }

    public var isDirty: Bool {
        detail != initialDetail
    }

    public func restoreInitialState() {
        detail = initialDetail
    }

    public func didPersist() {
        initialDetail = detail
    }
}
