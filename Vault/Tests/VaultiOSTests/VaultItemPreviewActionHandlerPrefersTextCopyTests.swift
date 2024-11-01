import Foundation
import TestHelpers
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
struct VaultItemPreviewActionHandlerPrefersTextCopyTests {
    @Test
    func copyHandlersNil_opensItemDetail() {
        let handler = VaultItemCopyActionHandlerMock()
        handler.textToCopyForVaultItemHandler = { _ in nil }
        let sut = VaultItemPreviewActionHandlerPrefersTextCopy(copyHandlers: handler, handler)

        let id = Identifier<VaultItem>.new()
        #expect(sut.previewActionForVaultItem(id: id) == .openItemDetail(id))
    }

    @Test
    func copyHandlers_copiesFirstText() {
        let handler1 = VaultItemCopyActionHandlerMock()
        handler1.textToCopyForVaultItemHandler = { _ in .init(text: "hi", requiresAuthenticationToCopy: false) }
        let sut = VaultItemPreviewActionHandlerPrefersTextCopy(copyHandlers: handler1)

        let id = Identifier<VaultItem>.new()
        #expect(sut.previewActionForVaultItem(id: id) == .copyText(.init(
            text: "hi",
            requiresAuthenticationToCopy: false
        )))
    }

    @Test
    func copyHandlers_copiesFirstText_skipsNil() {
        let handler1 = VaultItemCopyActionHandlerMock()
        handler1.textToCopyForVaultItemHandler = { _ in nil }
        let handler2 = VaultItemCopyActionHandlerMock()
        handler2.textToCopyForVaultItemHandler = { _ in .init(text: "hi", requiresAuthenticationToCopy: false) }
        let sut = VaultItemPreviewActionHandlerPrefersTextCopy(copyHandlers: handler1, handler2)

        let id = Identifier<VaultItem>.new()
        #expect(sut.previewActionForVaultItem(id: id) == .copyText(.init(
            text: "hi",
            requiresAuthenticationToCopy: false
        )))
    }

    @Test
    func copyHandlers_copiesFirstText_noNls() {
        let handler1 = VaultItemCopyActionHandlerMock()
        handler1.textToCopyForVaultItemHandler = { _ in .init(text: "first", requiresAuthenticationToCopy: false) }
        let handler2 = VaultItemCopyActionHandlerMock()
        handler2.textToCopyForVaultItemHandler = { _ in .init(text: "hi", requiresAuthenticationToCopy: false) }
        let sut = VaultItemPreviewActionHandlerPrefersTextCopy(copyHandlers: handler1, handler2)

        let id = Identifier<VaultItem>.new()
        #expect(sut.previewActionForVaultItem(id: id) == .copyText(.init(
            text: "first",
            requiresAuthenticationToCopy: false
        )))
    }
}
