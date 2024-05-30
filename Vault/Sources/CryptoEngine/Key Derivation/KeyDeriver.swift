import Foundation

/// Can derive a key, for example a KDF such as *scrypt*.
///
/// https://en.wikipedia.org/wiki/Key_derivation_function
public protocol KeyDeriver {
    func key() async throws -> Data
}

extension KeyDeriver {
    /// Asychronously perform some computation on a background thread.
    func computeOnBackgroundThread<T>(closure: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result {
                    try closure()
                })
            }
        }
    }
}
