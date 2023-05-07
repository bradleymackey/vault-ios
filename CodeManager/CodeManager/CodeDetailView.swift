//
//  CodeDetailView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 07/05/2023.
//

import Foundation
import OTPCore
import OTPFeediOS
import SwiftUI

struct CodeDetailView<Preview: View>: View {
    @Environment(\.dismiss) var dismiss

    let code: OTPAuthCode
    var preview: Preview

    var body: some View {
        OTPCodeDetailView(
            preview: preview,
            viewModel: .init(code: code)
        )
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
