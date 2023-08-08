//
//  CodeDetailView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 07/05/2023.
//

import Foundation
import OTPCore
import OTPFeed
import OTPFeediOS
import SwiftUI

struct CodeDetailView<Store: OTPCodeStoreReader, Preview: View>: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var feedViewModel: FeedViewModel<Store>
    let storedCode: StoredOTPCode
    var preview: Preview

    var body: some View {
        OTPCodeDetailView(
            preview: preview,
            viewModel: .init(storedCode: storedCode)
        )
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text(feedViewModel.doneEditingTitle)
                }
            }
        }
    }
}
