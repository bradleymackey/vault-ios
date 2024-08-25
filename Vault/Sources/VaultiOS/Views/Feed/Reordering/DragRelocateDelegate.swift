import Foundation
import SwiftUI

/// Relocation delegate for `ReorderableForEach`
///
/// https://stackoverflow.com/a/68963988/3261161
///
/// To workaround the inability to detect when dragging has ended, we use `currentItemCache`,
/// which retains the last dragged item so we can restore it across `dropExited` and the other drop
/// events.
struct DragRelocateDelegate<Item: VaultDraggableItem>: DropDelegate {
    let item: Item
    var listData: [Item]
    @Binding var current: Item?
    @Binding var currentItemCache: Item?
    var moveAction: (IndexSet, Int) -> Void

    func dropEntered(info _: DropInfo) {
        if current?.id != currentItemCache?.id {
            current = currentItemCache
        }
        guard item.id != current?.id, let current else { return }
        guard let from = listData.firstIndex(where: { $0.id == current.id }),
              let to = listData.firstIndex(where: { $0.id == item.id }) else { return }

        if listData[to].id != current.id {
            moveAction(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }

    func dropExited(info _: DropInfo) {
        current = nil
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? {
        if current?.id != currentItemCache?.id {
            current = currentItemCache
        }
        return DropProposal(operation: .move)
    }

    func performDrop(info _: DropInfo) -> Bool {
        current = nil
        currentItemCache = nil
        return true
    }
}
