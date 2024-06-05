import CryptoDocumentExporter
import Foundation

public final class BackupPasswordExporter {
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }
}
