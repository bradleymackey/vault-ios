import Foundation

public struct BackupPassword: Equatable, Hashable {
    public var key: Data

    public init(key: Data) {
        self.key = key
    }
}
