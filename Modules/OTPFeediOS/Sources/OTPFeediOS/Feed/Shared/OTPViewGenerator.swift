import Foundation
import OTPCore
import SwiftUI

@MainActor
public protocol OTPViewGenerator {
    associatedtype Code: OTPAuthCode
    associatedtype CodeView: View
    func makeOTPView(id: UUID, code: Code, isEditing: Bool) -> CodeView
}
