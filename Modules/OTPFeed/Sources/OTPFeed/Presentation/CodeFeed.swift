import Foundation

/// A feed of codes.
public protocol CodeFeed {
    /// The feed should load all initial data.
    func reloadData() async

    /// An update was made to the given code.
    ///
    /// The feed should update this data and show the changes.
    func update(id: UUID, code: StoredOTPCode.Write) async throws
}
