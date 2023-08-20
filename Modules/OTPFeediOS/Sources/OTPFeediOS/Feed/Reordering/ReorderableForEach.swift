import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// `ForEach` that supports reordering from a given source.
///
/// https://stackoverflow.com/a/68963988/3261161
struct ReorderableForEach<Content: View, PreviewContent: View, Item: Identifiable & Equatable>: View {
    let items: [Item]
    @Binding var isDragging: Bool
    let content: (Item) -> Content
    let previewContent: (Item) -> PreviewContent
    let moveAction: (IndexSet, Int) -> Void

    init(
        items: [Item],
        isDragging: Binding<Bool>,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder previewContent: @escaping (Item) -> PreviewContent,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) {
        self.items = items
        _isDragging = isDragging
        self.content = content
        self.previewContent = previewContent
        self.moveAction = moveAction
    }

    @State private var draggingItem: Item?
    @State private var draggingItemCache: Item?

    var body: some View {
        ForEach(items) { item in
            content(item)
                .overlay(draggingItem == item ? Color.white.opacity(0.8) : Color.clear)
                .onDrag({
                    draggingItem = item
                    draggingItemCache = item
                    return NSItemProvider(object: "\(item.id)" as NSString)
                }, preview: {
                    previewContent(item)
                })
                .onDrop(
                    of: [UTType.text],
                    delegate: DragRelocateDelegate(
                        item: item,
                        listData: items,
                        current: $draggingItem,
                        currentItemCache: $draggingItemCache
                    ) { from, to in
                        withAnimation {
                            moveAction(from, to)
                        }
                    }
                )
                .onChange(of: draggingItem) { currentlyDragging in
                    isDragging = currentlyDragging != nil
                }
        }
    }
}
