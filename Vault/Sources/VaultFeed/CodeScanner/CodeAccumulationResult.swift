import Foundation

/// Represents the state of an accumulation when scanning codes.
public enum CodeAccumulationResult<Partial, Full> {
    case accumulate(Partial)
    case complete(Full)
}
