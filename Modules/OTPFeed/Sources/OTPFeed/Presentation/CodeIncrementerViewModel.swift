import Combine
import Foundation
import OTPCore

@MainActor
public final class CodeIncrementerViewModel: ObservableObject {
    private let hotpRenderer: HOTPCodeRenderer
    private var counter: UInt64

    public init(hotpRenderer: HOTPCodeRenderer, counter: UInt64) {
        self.hotpRenderer = hotpRenderer
        self.counter = counter
        hotpRenderer.set(counter: counter)
    }

    public func incrementCounter() {
        counter += 1
        hotpRenderer.set(counter: counter)
    }
}
