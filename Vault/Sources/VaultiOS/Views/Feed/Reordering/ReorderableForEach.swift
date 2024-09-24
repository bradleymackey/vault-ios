import Foundation
import SwiftUI
import UniformTypeIdentifiers
import VaultCore

/// `ForEach` that supports reordering from a given source.
///
/// This is a bit of a hack, because SwiftUI doesn't currently natively support reordering in Lazy{V,H}Grid.
/// This should be removed in favor of a native solution when possible.
///
/// https://stackoverflow.com/a/68963988/3261161
@MainActor
struct ReorderableForEach<Content: View, PreviewContent: View, Item: VaultDraggableItem>: View {
    let items: [Item]
    @Binding var isDragging: Bool
    var isEnabled: Bool
    var clock: any EpochClock
    let content: (Item) -> Content
    let previewContent: (Item) -> PreviewContent
    let moveAction: (IndexSet, Int) -> Void

    init(
        items: [Item],
        isDragging: Binding<Bool>,
        isEnabled: Bool,
        clock: any EpochClock,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder previewContent: @escaping (Item) -> PreviewContent,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) {
        self.items = items
        _isDragging = isDragging
        self.isEnabled = isEnabled
        self.clock = clock
        self.content = content
        self.previewContent = previewContent
        self.moveAction = moveAction
    }

    @State private var draggingItem: Item?
    @State private var draggingItemCache: Item?
    @State private var canStartDrag = true

    var body: some View {
        ForEach(items) { item in
            content(item)
                .overlay(
                    Color.white
                        .opacity(draggingItem?.id == item.id ? 0.8 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .animation(.easeOut, value: draggingItem?.id)
                )
                .onDrag {
                    // Check this flag, because this closure may be triggered falsely after completing a drop in iOS 18
                    if canStartDrag {
                        draggingItem = isEnabled ? item : nil
                        draggingItemCache = isEnabled ? item : nil
                    } else {
                        // We may get one false event, after that we can drag again.
                        // (Due to that same iOS 18 bug)
                        canStartDrag = true
                    }
                    let string = item.sharingContent(clock: clock)
                    return NSItemProvider(object: string as NSString)
                } preview: {
                    previewContent(item)
                }
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
                .onChange(of: draggingItem?.id) { _, newValue in
                    isDragging = newValue != nil
                    if isDragging {
                        canStartDrag = false
                    }
                }
        }
    }
}
