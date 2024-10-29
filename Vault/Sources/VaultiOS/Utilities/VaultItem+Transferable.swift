import CoreTransferable
import Foundation
import UniformTypeIdentifiers
import VaultFeed

private enum VaultItemTransferError: Error {
    case unableToCreateString
}

extension VaultItem: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        MainActor.assumeIsolated {
            VaultSharingContentTransferRepresentation(copyActionHandler: VaultRoot.vaultItemCopyHandler)
        }
    }

    public struct VaultSharingContentTransferRepresentation<C: VaultItemCopyActionHandler>: TransferRepresentation {
        public typealias Item = VaultItem
        private let copyActionHandler: C

        init(copyActionHandler: C) {
            self.copyActionHandler = copyActionHandler
        }

        public var body: some TransferRepresentation {
            DataRepresentation(exportedContentType: .plainText) { item in
                guard
                    let data = await copyActionHandler.textToCopyForVaultItem(id: item.id),
                    !data.requiresAuthenticationToCopy
                else {
                    return Data()
                }
                if let string = data.text.data(using: .utf8) {
                    return string
                } else {
                    throw VaultItemTransferError.unableToCreateString
                }
            }
            ProxyRepresentation(exporting: \.id)
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
