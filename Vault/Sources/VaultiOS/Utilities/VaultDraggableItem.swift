import CoreTransferable
import Foundation
import UniformTypeIdentifiers
import VaultFeed

private enum VaultItemTransferError: Error {
    case unableToCreateString
}

extension VaultItem: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        VaultSharingContentTransferRepresentation(clock: EpochClockImpl())
    }

    public struct VaultSharingContentTransferRepresentation: TransferRepresentation {
        public typealias Item = VaultItem
        private let clock: any EpochClock

        init(clock: any EpochClock) {
            self.clock = clock
        }

        public var body: some TransferRepresentation {
            DataRepresentation(exportedContentType: .plainText) { item in
                if let string = item.sharingContent(clock: clock).data(using: .utf8) {
                    return string
                } else {
                    throw VaultItemTransferError.unableToCreateString
                }
            }
            ProxyRepresentation(exporting: \.id)
        }
    }

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
                case .hotp:
                    return "" // TODO: support this, need latest counter value
                }
            } catch {
                return "ERROR"
            }
        }
    }
}

private enum VaultIDTransferError: Error {
    case idDecodingError
}

struct VaultIDTransferRepresentation: TransferRepresentation {
    typealias Item = Identifier<VaultItem>

    var body: some TransferRepresentation {
        DataRepresentation(contentType: .vaultIdentifierItemType) { id in
            Data(id.id.uuidString.bytes)
        } importing: { data in
            let string = String(decoding: data, as: Unicode.UTF8.self)
            guard let uuid = UUID(uuidString: string) else { throw VaultIDTransferError.idDecodingError }
            return Identifier(id: uuid)
        }
    }
}

extension Identifier: Transferable where T == VaultItem {
    public static var transferRepresentation: some TransferRepresentation {
        VaultIDTransferRepresentation()
    }
}

extension UTType {
    static let vaultIdentifierItemType = UTType(exportedAs: "vault.identifier.drop.id")
}
