import Foundation
import Testing
import VaultFeed
@testable import VaultiOS

struct VaultItemFeedReordererTests {
    @Test
    func doesNotMoveItemIfEmptyState() {
        let sut = VaultItemFeedReorderer(state: [])
        let result = sut.reorder(item: .new(), to: .new())

        #expect(result == .noMove)
    }

    @Test
    func doesNotMoveItemIfSamePosition() {
        let id = Identifier<VaultItem>.new()
        let sut = VaultItemFeedReorderer(state: [id])
        let result = sut.reorder(item: id, to: id)

        #expect(result == .noMove)
    }

    @Test
    func doesNotMoveItemIfNotInList() {
        let sut = VaultItemFeedReorderer(state: [.new()])
        let result = sut.reorder(item: .new(), to: .new())

        #expect(result == .noMove)
    }

    @Test
    func movesToStart() throws {
        let id1 = Identifier<VaultItem>.new()
        let id2 = Identifier<VaultItem>.new()
        let id3 = Identifier<VaultItem>.new()
        let sut = VaultItemFeedReorderer(state: [id1, id2, id3])

        let result = sut.reorder(item: id3, to: id1)
        let move = try #require(result.move)

        #expect(move.fromIndex == 2)
        #expect(move.toIndex == 0)
        #expect(move.reorderingPosition == .start)
    }

    @Test
    func movesBeforeItem() throws {
        let id1 = Identifier<VaultItem>.new()
        let id2 = Identifier<VaultItem>.new()
        let id3 = Identifier<VaultItem>.new()
        let sut = VaultItemFeedReorderer(state: [id1, id2, id3])

        let result = sut.reorder(item: id3, to: id2)
        let move = try #require(result.move)

        #expect(move.fromIndex == 2)
        #expect(move.toIndex == 1)
        #expect(move.reorderingPosition == .after(id1))
    }

    @Test
    func movesAfterItem() throws {
        let id1 = Identifier<VaultItem>.new()
        let id2 = Identifier<VaultItem>.new()
        let id3 = Identifier<VaultItem>.new()
        let sut = VaultItemFeedReorderer(state: [id1, id2, id3])

        let result = sut.reorder(item: id1, to: id3)
        let move = try #require(result.move)

        #expect(move.fromIndex == 0)
        #expect(move.toIndex == 3)
        #expect(move.reorderingPosition == .after(id3))
    }
}

extension VaultItemFeedReorderer.ReorderResult {
    var move: Move? {
        switch self {
        case .noMove: nil
        case let .move(move): move
        }
    }
}
