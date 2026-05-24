import SwiftUI
import VaultFeed

struct VaultDetailNotePreviewEditView: View {
    var title: String
    var description: String
    @Binding var previewMode: NotePreviewMode

    var body: some View {
        Form {
            titleSection
            optionSection
        }
        .animation(.easeOut, value: previewMode)
        .transition(.move(edge: .top))
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(
                systemIcon: previewMode.systemIconName,
                title: title,
                subtitle: description,
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .contentTransition(.symbolEffect(.replace))
        }
    }

    private var optionSection: some View {
        Section {
            Picker(selection: $previewMode) {
                ForEach(NotePreviewMode.allCases, id: \.self) { mode in
                    Text(mode.localizedTitle).tag(mode)
                }
            } label: {
                Text("Preview style")
                    .font(.body)
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }
}

extension NotePreviewMode {
    fileprivate var systemIconName: String {
        switch self {
        case .titleAndFirstLine: "text.alignleft"
        case .titleOnly: "text.line.first.and.arrowtriangle.forward"
        case .hidden: "eye.slash.fill"
        }
    }
}

#Preview {
    VaultDetailNotePreviewEditView(
        title: "Preview",
        description: "Choose what shows in the preview tile.",
        previewMode: .constant(.titleAndFirstLine),
    )
}
