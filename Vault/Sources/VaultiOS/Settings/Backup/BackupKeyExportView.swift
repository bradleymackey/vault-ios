import Foundation
import SwiftUI

struct BackupKeyExportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Text("Export")
        }
        .navigationTitle(Text("Export Password"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
    }
}
