import SwiftUI
import VaultiOSWidgets
import WidgetKit

@main
struct VaultWidgetsBundle: WidgetBundle {
    var body: some Widget { OTPWidget() }
    
    init() {
        _ = OTPWidgetIntent.self
        _ = OTPWidgetItemEntity.self
    }
}
