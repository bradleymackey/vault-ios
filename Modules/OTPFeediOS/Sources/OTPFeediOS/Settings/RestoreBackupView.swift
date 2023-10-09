import Foundation
import OTPUI
import SwiftUI

struct RestoreBackupView: View {
    @State private var hasAnyExistingCodes = true

    var body: some View {
        Form {
            if hasAnyExistingCodes {
                hasExistingCodesSection
            } else {
                noExistingCodesSection
            }
        }
    }

    private var noExistingCodesSection: some View {
        Section {
            Button {
                print("restore existing")
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore Existing Codes")
                }
            }
        }
    }

    private var hasExistingCodesSection: some View {
        Section {
            Button {
                print("merge")
            } label: {
                FormRow(image: Image(systemName: "doc.on.doc.fill"), color: .green) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Merge with existing codes")
                        Text("Recommended")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }

            Button {
                print("override")
            } label: {
                FormRow(image: Image(systemName: "doc.fill"), color: .red) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Override existing codes")
                        Text("Danger")
                            .font(.footnote.bold())
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 2)
            }
        } footer: {
            Text("You have some existing codes. What would you like to do?")
        }
    }
}
