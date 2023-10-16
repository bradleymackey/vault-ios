import Combine
import Foundation

@MainActor
@Observable
public final class CodeDetailEditingModel {
    public var detail: OTPCodeDetailEdits
    public private(set) var initialDetail: OTPCodeDetailEdits

    public init(detail: OTPCodeDetailEdits) {
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
