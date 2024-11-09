import Foundation
import SwiftUI
import VaultFeed

struct DeveloperCreateItemsView: View {
    @Environment(VaultDataModel.self) var dataModel

    var body: some View {
        Form {
            AsyncButton {
                let factory = VaultItemDemoFactory()
                let hotpItem = factory.makeHOTPCode()
                try await dataModel.insert(item: hotpItem)
            } label: {
                Text("Create HOTP")
            }

            AsyncButton {
                let factory = VaultItemDemoFactory()
                let item = factory.makeTOTPCode()
                try await dataModel.insert(item: item)
            } label: {
                Text("Create TOTP")
            }

            AsyncButton {
                let factory = VaultItemDemoFactory()
                let item = factory.makeSecureNote()
                try await dataModel.insert(item: item)
            } label: {
                Text("Create note")
            }

            Button {
                print("TODO: create encrypted note in DB")
            } label: {
                Text("Create encrypted note")
            }
        }
    }
}
