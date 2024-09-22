import Foundation

/// An intermediate (encoded & compressed, but unencrypted) representation of a vault.
///
/// In this form, the vault is ready for either:
///  - encryption (for backup)
///  - converting to a vault payload (for the application)
///
/// The compression algorithm is lzma, which has a very high compression ratio.
/// The encoding format for LZMA should be `FORMAT_XZ`, which is generally recommended anyway.
struct IntermediateEncodedVault: Equatable {
    /// The raw encoded vault data.
    var data: Data
}
