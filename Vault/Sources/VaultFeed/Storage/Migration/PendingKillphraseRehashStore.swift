import Foundation

/// Persisted as a sibling of the SwiftData store during the V1 → V2 schema
/// migration. Records the plaintext killphrases that were dropped from the
/// schema in Phase A so they can be hashed and written back in Phase B
/// (after the vault key becomes available on first post-update unlock).
///
/// On disk this is a JSON file written with file protection
/// `.completeFileProtectionUntilFirstUserAuthentication`. The window of
/// exposure is the narrow gap between a successful schema migration and
/// the user's first unlock that triggers `KillphraseRehashService.run`.
///
/// The file is cleared (and securely overwritten before deletion) once
/// all entries have been re-hashed.
struct PendingKillphraseRehashStore: Sendable {
    struct Entry: Codable, Equatable, Sendable {
        let itemID: UUID
        let phrase: String
    }

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Default location alongside the SwiftData store.
    static func defaultURL(storeDirectory: URL) -> URL {
        storeDirectory.appending(path: "vault-primary.pending-killphrase-rehash.json")
    }

    /// Read all pending entries. Returns an empty array if no file exists.
    func read() throws -> [Entry] {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        guard data.isEmpty == false else { return [] }
        return try JSONDecoder().decode([Entry].self, from: data)
    }

    /// Write a snapshot. Overwrites any existing file. File protection is
    /// applied so the data is unreadable until the user has authenticated
    /// the device at least once after boot.
    func write(_ entries: [Entry]) throws {
        let data = try JSONEncoder().encode(entries)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    /// Overwrite the file with zeros, then delete. Best-effort residue
    /// minimisation; the file system may still retain copies depending on
    /// underlying storage.
    func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return
        }
        if let size = try? FileManager.default.attributesOfItem(
            atPath: fileURL.path(percentEncoded: false),
        )[.size] as? Int, size > 0 {
            let zeros = Data(count: size)
            try? zeros.write(to: fileURL, options: [.atomic])
        }
        try FileManager.default.removeItem(at: fileURL)
    }
}
