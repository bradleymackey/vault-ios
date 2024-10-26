import Foundation
import SwiftUI

struct BackupImportCodeStateVisualizerView: View {
    var totalCount: Int
    var selectedIndexes: Set<Int>

    var body: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 30, maximum: 40))], spacing: 8) {
            ForEach(0 ..< totalCount, id: \.self) { index in
                Image(systemName: "qrcode")
                    .font(.system(size: 28))
                    .foregroundStyle(.primary.opacity(selectedIndexes.contains(index) ? 0.05 : 1))
                    .overlay(content: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24).bold())
                            .foregroundStyle(.green)
                            .opacity(selectedIndexes.contains(index) ? 1 : 0)
                    })
            }
        }
    }
}

#Preview {
    BackupImportCodeStateVisualizerView(totalCount: 20, selectedIndexes: [0, 5, 19])
}
