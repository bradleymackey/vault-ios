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

struct CodeDetailView<Store: OTPCodeStoreReader>: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var feedViewModel: FeedViewModel<Store>
    let storedCode: StoredOTPCode

    var body: some View {
        OTPCodeDetailView(
            viewModel: .init(storedCode: storedCode)
        )
    }
}
