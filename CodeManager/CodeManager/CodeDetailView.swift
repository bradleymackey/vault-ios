//
//  CodeDetailView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 07/05/2023.
//

import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultFeediOS

struct CodeDetailView<Store: VaultStore>: View {
    @Environment(\.dismiss) var dismiss

    var feedViewModel: FeedViewModel<Store>
    let storedCode: StoredVaultItem

    var body: some View {
        OTPCodeDetailView(
            viewModel: .init(storedCode: storedCode, editor: CodeFeedCodeDetailEditorAdapter(codeFeed: feedViewModel))
        )
    }
}
