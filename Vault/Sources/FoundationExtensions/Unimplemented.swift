import Foundation

public func unimplemented<T>(_ message: String? = nil, file: StaticString = #file, line: UInt = #line) -> T {
    let finalMessage = "UNIMPLEMENTED: \(message ?? "This has not been implemented")"
    fatalError(finalMessage, file: file, line: line)
}

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
