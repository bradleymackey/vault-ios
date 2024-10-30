import Foundation
import SwiftUI

public struct VaultAutofillView: View {
    public init() {}
    public var body: some View {
        NavigationStack {
            Form {
                Text("Vault can Autofill!")
            }
            .navigationTitle(Text("Vault Autofill"))
        }
    }
}
