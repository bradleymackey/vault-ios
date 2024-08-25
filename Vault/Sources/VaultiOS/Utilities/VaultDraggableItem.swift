import Foundation
import VaultFeed

protocol VaultDraggableItem: Identifiable {
    func sharingContent(clock: any EpochClock) -> String
}

extension VaultItem: VaultDraggableItem {
    func sharingContent(clock: any EpochClock) -> String {
        switch item {
        case let .secureNote(note):
            return note.title
        case let .otpCode(code):
            do {
                switch code.type {
                case let .totp(period):
                    let totp = TOTPAuthCode(period: period, data: code.data)
                    return try totp.renderCode(epochSeconds: UInt64(clock.currentTime))
                case let .hotp(counter):
                    let hotp = HOTPAuthCode(counter: counter, data: code.data)
                    return try hotp.renderCode()
                }
            } catch {
                return "ERROR"
            }
        }
    }
}
