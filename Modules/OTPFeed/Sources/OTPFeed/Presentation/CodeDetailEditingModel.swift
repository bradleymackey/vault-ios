import Combine
import Foundation

@MainActor
public final class CodeDetailEditingModel: ObservableObject {
    public struct Detail: Equatable {
        public var issuerTitle: String = ""
        public var accountNameTitle: String = ""
        public var description: String = ""
    }

    @Published public var detail = Detail()
    public let initialDetail = Detail()

    public init() {}

    public var isDirty: Bool {
        detail != initialDetail
    }
}
