import Foundation

public enum UpdateContext: Equatable, Sendable {
    case updateUpdatedDate
    case retainUpdatedDate(Date)
}
