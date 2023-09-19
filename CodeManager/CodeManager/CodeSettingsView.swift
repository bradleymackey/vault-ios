//
//  CodeSettingsView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 10/08/2023.
//

import OTPFeediOS
import OTPSettings
import SwiftUI

struct CodeSettingsView: View {
    @ObservedObject var localSettings: LocalSettings

    var body: some View {
        SettingsHomeView(localSettings: localSettings)
    }
}
