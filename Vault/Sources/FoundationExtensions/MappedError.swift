import Foundation

@inlinable
public func withMappedError<T, E: Error>(body: () throws -> T, error: (any Error) -> E) throws -> T {
    try Result {
        try body()
    }.mapError {
        error($0)
    }.get()
}

/// Catches an error and returns the error type.
@inlinable
public func withCatchingError<T>(body: () throws -> T) -> (any Error)? {
    do {
        _ = try body()
        return nil
    } catch {
        return error
    }
}
