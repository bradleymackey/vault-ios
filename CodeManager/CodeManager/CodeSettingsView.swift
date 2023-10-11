//
//  CodeSettingsView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 10/08/2023.
//

import OTPFeediOS
import VaultSettings
import SwiftUI

struct CodeSettingsView: View {
    var viewModel: SettingsViewModel
    var localSettings: LocalSettings

    var body: some View {
        SettingsHomeView(viewModel: viewModel, localSettings: localSettings)
    }
}
