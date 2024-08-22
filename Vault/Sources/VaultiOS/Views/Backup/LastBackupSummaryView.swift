import Foundation
import SwiftUI
import VaultFeed

struct LastBackupSummaryView: View {
    var lastBackup: VaultBackupEvent?

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            if let lastBackup {
                Text(lastBackup.backupDate.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.primary)
                Text(lastBackup.kind.localizedTitle)
                    .foregroundStyle(.secondary)
            } else {
                Text("You have never created a backup and are at risk of data loss.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .padding()
        .containerRelativeFrame(.horizontal)
        .alignmentGuide(.listRowSeparatorLeading, computeValue: { _ in
            0
        })
    }

    private var title: String {
        lastBackup == nil ? "No Backups" : "Last Backup"
    }

    private var systemImage: String {
        lastBackup == nil ? "exclamationmark.arrow.triangle.2.circlepath" : "clock.arrow.2.circlepath"
    }
}

#Preview {
    List {
        LastBackupSummaryView(lastBackup: nil)
        LastBackupSummaryView(lastBackup: VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data(hex: "ababa"))
        ))
    }
}
