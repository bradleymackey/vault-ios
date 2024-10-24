import Foundation
import SwiftUI
import VaultFeed

struct VaultTagSelectorView: View {
    var currentTags: [VaultItemTag]
    var didSelect: (VaultItemTag) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(currentTags) { tag in
                Button {
                    didSelect(tag)
                    dismiss()
                } label: {
                    FormRow(
                        image: Image(systemName: tag.iconName),
                        color: tag.color.color,
                        style: .standard
                    ) {
                        Text(tag.name)
                    }
                }
                .tint(.primary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .tint(.red)
            }
        }
    }
}
