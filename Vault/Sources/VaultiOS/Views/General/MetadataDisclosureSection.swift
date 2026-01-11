import SwiftUI
import VaultFeed

struct MetadataDisclosureSection: View {
    var tags: [VaultItemTag]
    var entries: [DetailEntry]
    @State private var isExpanded: Bool = false

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                if tags.isNotEmpty {
                    tagsRow
                }

                ForEach(entries) { entry in
                    LabeledContent {
                        Text(entry.detail)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label(entry.title, systemImage: entry.systemIconName)
                    }
                }
            } label: {
                Label("Metadata", systemImage: "info.circle")
            }
        }
    }

    private var tagsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(tags) { tag in
                        TagPillView(tag: tag, isSelected: true)
                            .id(tag)
                    }
                }
                .font(.callout)
            }
            .scrollClipDisabled()
        }
        .padding(.vertical, 4)
    }
}
