import Foundation
import SwiftUI
import VaultFeed

struct VaultDetailTagEditView: View {
    var tagsThatAreSelected: [VaultItemTag]
    var remainingTags: [VaultItemTag]
    var didAdd: (VaultItemTag) -> Void
    var didRemove: (VaultItemTag) -> Void

    var body: some View {
        Form {
            if hasAnyTags {
                currentTagsSection
            }
            remainingTagsSection
        }
        .navigationTitle(Text("Tags"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hasAnyTags: Bool {
        !(tagsThatAreSelected.isEmpty && remainingTags.isEmpty)
    }

    private var currentTagsSection: some View {
        Section {
            ForEach(tagsThatAreSelected) { tag in
                Button {
                    withAnimation {
                        didRemove(tag)
                    }
                } label: {
                    FormRow(
                        image: Image(systemName: "minus.circle.fill"),
                        color: .red,
                        style: .standard,
                    ) {
                        TagPillView(tag: tag, isSelected: true)
                    }
                }
                .id(tag.id)
            }

            if tagsThatAreSelected.isEmpty {
                PlaceholderView(
                    systemIcon: "tag.fill",
                    title: "No Tags Selected",
                    subtitle: "Add a tag from the available tags",
                )
                .containerRelativeFrame(.horizontal)
                .padding()
            }
        } header: {
            Text("Selected Tags")
        }
    }

    private var remainingTagsSection: some View {
        Section {
            ForEach(remainingTags) { tag in
                Button {
                    withAnimation {
                        didAdd(tag)
                    }
                } label: {
                    FormRow(
                        image: Image(systemName: "plus.circle.fill"),
                        color: .green,
                        style: .standard,
                    ) {
                        TagPillView(tag: tag, isSelected: false)
                    }
                }
                .id(tag.id)
            }

            if remainingTags.isEmpty {
                PlaceholderView(
                    systemIcon: "checkmark.circle.fill",
                    title: "No Other Tags",
                    subtitle: "Create new tags in the tag manager",
                )
                .containerRelativeFrame(.horizontal)
                .padding()
            }
        } header: {
            Text("Available Tags")
        }
    }
}
