import Combine
import CryptoEngine
import Foundation
import OTPCore

/// Renders the code to a visible state for the given `code`.
public protocol OTPCodeRenderer {
    func renderedCodePublisher() -> AnyPublisher<String, Error>
}

extension Publisher where Output == UInt32 {
    func digitsRenderer(digits: Int) -> AnyPublisher<String, Failure> {
        map { codeNumber in
            String(codeNumber).leftPadding(toLength: digits, withPad: "0")
        }
        .eraseToAnyPublisher()
    }
}

public final class TOTPCodeRenderer<Timer: CodeTimerUpdater>: OTPCodeRenderer {
    private let timer: Timer
    private let totpGenerator: TOTPGenerator

    public init(timer: Timer, totpGenerator: TOTPGenerator) {
        self.timer = timer
        self.totpGenerator = totpGenerator
    }

    public func renderedCodePublisher() -> AnyPublisher<String, Error> {
        codeValuePublisher()
            .digitsRenderer(digits: totpGenerator.digits)
    }

    private func codeValuePublisher() -> AnyPublisher<UInt32, Error> {
        let generator = totpGenerator
        return timer.timerUpdatedPublisher()
            .setFailureType(to: Error.self)
            .tryMap { state in
                try generator.code(epochSeconds: UInt64(state.startTime))
            }
            .eraseToAnyPublisher()
    }
}

public final class HOTPCodeRenderer: OTPCodeRenderer {
    private let hotpGenerator: HOTPGenerator
    private let counterSubject: CurrentValueSubject<UInt64, Never>

    public init(hotpGenerator: HOTPGenerator, initialCounter: UInt64) {
        self.hotpGenerator = hotpGenerator
        counterSubject = CurrentValueSubject(initialCounter)
    }

    /// Update the current value of the counter.
    public func set(counter: UInt64) {
        counterSubject.send(counter)
    }

    public func renderedCodePublisher() -> AnyPublisher<String, Error> {
        codeValuePublisher()
            .digitsRenderer(digits: hotpGenerator.digits.rawValue)
    }

    private func codeValuePublisher() -> AnyPublisher<UInt32, Error> {
        let generator = hotpGenerator
        return counterSubject
            .setFailureType(to: Error.self)
            .tryMap { counterValue in
                try generator.code(counter: counterValue)
            }
            .eraseToAnyPublisher()
    }
}

private extension String {
    func leftPadding(toLength newLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < newLength {
            return String(repeatElement(character, count: newLength - stringLength)) + self
        } else {
            return String(suffix(newLength))
        }
    }
}
