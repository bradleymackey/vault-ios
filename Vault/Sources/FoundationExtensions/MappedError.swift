import Foundation

@inlinable
public func withMappedError<T>(body: () throws -> T, error: (any Error) -> some Error) throws -> T {
    try Result {
        try body()
    }.mapError {
        error($0)
    }.get()
}

/// Catches an error and returns the error type.
@inlinable
public func withCatchingError(body: () throws -> some Any) -> (any Error)? {
    do {
        _ = try body()
        return nil
    } catch {
        return error
    }
}

/// Catches an error and returns the error type.
///
/// Throws if there was another error that we can't catch.
@inlinable
public func withCatchingSomeError<T, E>(body: () throws -> T) throws -> (E)? {
    do {
        _ = try body()
        return nil
    } catch let error as E {
        return error
    } catch {
        throw error
    }
}

/// Catches an error and returns the error type.
@inlinable
public func withCatchingAsyncError(body: () async throws -> some Any) async -> (any Error)? {
    do {
        _ = try await body()
        return nil
    } catch {
        return error
    }
}
