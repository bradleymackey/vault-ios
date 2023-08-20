import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// `ForEach` that supports reordering from a given source.
///
/// https://stackoverflow.com/a/68963988/3261161
struct ReorderableForEach<Content: View, Item: Identifiable & Equatable>: View {
    let items: [Item]
    let isEnabled: Bool
    let content: (Item) -> Content
    let moveAction: (IndexSet, Int) -> Void

    // A little hack that is needed in order to make view back opaque
    // if the drag and drop hasn't ever changed the position
    // Without this hack the item remains semi-transparent
    @State private var hasChangedLocation: Bool = false

    init(
        items: [Item],
        isEnabled: Bool,
        @ViewBuilder content: @escaping (Item) -> Content,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) {
        self.items = items
        self.isEnabled = isEnabled
        self.content = content
        self.moveAction = moveAction
    }

    @State private var draggingItem: Item?

    var body: some View {
        ForEach(items) { item in
            content(item)
                .overlay(draggingItem == item && hasChangedLocation ? Color.white.opacity(0.8) : Color.clear)
                .overlay(isEnabled ? draggableOverlay(item: item) : nil)
        }
    }

    /// Helper overlay for the dragging modifier.
    /// As `onDrag` cannot be conditionally disabled, we do a little hack to place a draggable view as an overlay.
    private func draggableOverlay(item: Item) -> some View {
        Rectangle()
            .opacity(0.01) // Make it invisible, but still active
            .onDrag({
                draggingItem = item
                return NSItemProvider(object: "\(item.id)" as NSString)
            }, preview: {
                content(item)
            })
            .onDrop(
                of: [UTType.text],
                delegate: DragRelocateDelegate(
                    item: item,
                    listData: items,
                    current: $draggingItem,
                    hasChangedLocation: $hasChangedLocation
                ) { from, to in
                    withAnimation {
                        moveAction(from, to)
                    }
                }
            )
    }
}
