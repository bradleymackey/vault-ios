import Foundation
import VaultFeed

protocol DraggableItem: Identifiable {
    var sharingContent: String { get }
}

extension VaultItem: DraggableItem {
    var sharingContent: String {
        switch item {
        case let .secureNote(note):
            return note.title
        case .otpCode:
            return "OTP"
        }
    }
}
