import CryptoEngine
import Foundation
import SwiftUI
import VaultFeed

struct LastBackupSummaryView: View {
    var lastBackup: VaultBackupEvent?

    var body: some View {
        HStack(spacing: 0) {
            // Colored accent bar
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(accentColor)

                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                }

                if let lastBackup {
                    Text(lastBackup.backupDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.title3)
                        .foregroundStyle(.primary)

                    Text(lastBackup.kind.localizedTitle)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("You haven't created a backup from this device and could be at risk of data loss.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var title: String {
        lastBackup == nil ? "No Backups" : "Last Backup"
    }

    private var systemImage: String {
        lastBackup == nil ? "exclamationmark.arrow.triangle.2.circlepath" : "clock.arrow.2.circlepath"
    }

    private var accentColor: Color {
        guard let lastBackup else { return Color.red }

        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackup.backupDate, to: Date())
            .day ?? Int.max

        if daysSinceBackup < 7 {
            return Color.green
        } else if daysSinceBackup < 30 {
            return Color.orange
        } else {
            return Color.red
        }
    }
}

#Preview {
    List {
        LastBackupSummaryView(lastBackup: nil)
        LastBackupSummaryView(lastBackup: VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data(hex: "ababa")),
        ))
        LastBackupSummaryView(lastBackup: VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data(hex: "ababa")),
        ))
        LastBackupSummaryView(lastBackup: VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data(hex: "ababa")),
        ))
    }
}
