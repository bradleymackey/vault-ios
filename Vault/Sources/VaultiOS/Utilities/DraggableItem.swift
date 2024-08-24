import Foundation
import VaultFeed

protocol DraggableItem: Identifiable {
    var sharingContent: String { get }
}

extension VaultItem: DraggableItem {
    var sharingContent: String {
        "Hello, world!"
    }
}
