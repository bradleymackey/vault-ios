import Foundation
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("Merge with existing codes")
                    Text("Recommended")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                print("override")
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Override existing codes")
                    Text("Danger")
                        .font(.footnote.bold())
                        .foregroundStyle(.red)
                }
            }
        } footer: {
            Text("You have some existing codes. What would you like to do?")
        }
    }
}
