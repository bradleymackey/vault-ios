import CryptoEngine
import Foundation
import SwiftUI
import VaultFeed

struct LastBackupSummaryView: View {
    var lastBackup: VaultBackupEvent?
    var currentHash: Digest<VaultApplicationPayload>.SHA256?

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

                if let currentHash {
                    if lastBackup.payloadHash == currentHash {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Latest changes backed up")
                        }
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .textCase(.uppercase)
                        .padding(.top, 8)
                    } else {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Recent changes have not been backed up")
                        }
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                        .textCase(.uppercase)
                        .padding(.top, 8)
                    }
                }
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
        LastBackupSummaryView(lastBackup: VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data(hex: "ababa"))
        ), currentHash: .init(value: Data()))
        LastBackupSummaryView(lastBackup: VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data(hex: "ababa"))
        ), currentHash: .init(value: Data(hex: "ababa")))
    }
}
