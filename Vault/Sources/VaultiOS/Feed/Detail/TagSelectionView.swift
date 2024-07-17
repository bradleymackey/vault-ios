import Foundation
import SwiftUI
import VaultFeed

struct TagSelectionView: View {
    @Binding var selectedTags: Set<VaultItemTag.Identifier>
    var allTags: [VaultItemTag]

    @Namespace private var animation

    private var tagsThatAreSelected: [VaultItemTag] {
        allTags.filter { selectedTags.contains($0.id) }
    }

    private var unselectedTags: [VaultItemTag] {
        allTags.filter { !selectedTags.contains($0.id) }
    }

    var body: some View {
        // A view that is presented within a cell that allows users to pick VaultItemTags, using TagPillView
        VStack {
            if tagsThatAreSelected.isNotEmpty {
                // Selected tags
                LazyVGrid(columns: [.init(.adaptive(minimum: 100))]) {
                    ForEach(tagsThatAreSelected, id: \.self) { tag in
                        Button {
                            withAnimation {
                                _ = selectedTags.remove(tag.id)
                            }
                        } label: {
                            TagPillView(tag: tag, isSelected: true)
                        }
                        .buttonStyle(.plain)
                        .matchedGeometryEffect(id: tag.id, in: animation)
                    }
                }
                .animation(.easeInOut, value: selectedTags)

                Divider()
                    .animation(.easeInOut, value: selectedTags)
            }

            // Unselected tags
            LazyVGrid(columns: [.init(.adaptive(minimum: 100))]) {
                ForEach(unselectedTags, id: \.self) { tag in
                    Button {
                        withAnimation {
                            _ = selectedTags.insert(tag.id)
                        }
                    } label: {
                        TagPillView(tag: tag, isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: tag.id, in: animation)
                }
            }
        }
    }
}
