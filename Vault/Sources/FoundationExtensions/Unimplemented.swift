import Foundation

public struct UnimplementedError: Error, LocalizedError {
    private let file: StaticString
    private let line: UInt

    public init(file: StaticString = #fileID, line: UInt = #line) {
        self.file = file
        self.line = line
    }

    public var errorDescription: String? {
        "This feature has not been implemented: (\(file):L\(line))"
    }
}
