import Foundation
import SwiftUI
import VaultFeed

struct BackupImportView: View {
    @Environment(VaultDataModel.self) private var dataModel

    var body: some View {
        Form {
            if dataModel.hasAnyItems {
                hasExistingCodesSection
            } else {
                noExistingCodesSection
            }
        }
        .navigationTitle(Text("Restore Backup"))
        .task {
            await dataModel.reloadItems()
        }
    }

    private var noExistingCodesSection: some View {
        Section {
            Button {
//                print("restore existing")
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .accentColor,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Import Backup",
                        subtitle: "Use a backup file to populate your Vault"
                    )
                }
            }
        }
    }

    private var hasExistingCodesSection: some View {
        Section {
            Button {
//                print("merge")
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.on.square.fill"),
                    color: .accentColor,
                    style: .standard,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Merge Backup",
                        subtitle: "Import a backup file and merge with your existing data. If any items conflict, the most recent version will be used."
                    )
                }
            }

            Button {
//                print("override")
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .red,
                    style: .standard,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Override Backup",
                        subtitle: "Import a backup file and override any existing data. Any existing data in your vault will be deleted. Warning!"
                    )
                }
                .foregroundStyle(.red)
            }
        }
    }
}
