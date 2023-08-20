import Foundation
import SwiftUI

/// Relocation delegate for `ReorderableForEach`
///
/// https://stackoverflow.com/a/68963988/3261161
struct DragRelocateDelegate<Item: Equatable>: DropDelegate {
    let item: Item
    var listData: [Item]
    @Binding var current: Item?

    var moveAction: (IndexSet, Int) -> Void

    func dropEntered(info _: DropInfo) {
        guard item != current, let current else { return }
        guard let from = listData.firstIndex(of: current), let to = listData.firstIndex(of: item) else { return }

        if listData[to] != current {
            moveAction(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info _: DropInfo) -> Bool {
        current = nil
        return true
    }
}
