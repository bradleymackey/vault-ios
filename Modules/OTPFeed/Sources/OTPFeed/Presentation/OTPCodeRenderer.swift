import Combine
import CryptoEngine
import Foundation
import OTPCore

/// Renders the code to a visible state for the given `code`.
protocol OTPCodeRenderer {
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

final class TOTPCodeRenderer<Clock: EpochClock>: OTPCodeRenderer {
    private let clock: Clock
    private let totpGenerator: TOTPGenerator

    init(clock: Clock, totpGenerator: TOTPGenerator) {
        self.clock = clock
        self.totpGenerator = totpGenerator
    }

    func renderedCodePublisher() -> AnyPublisher<String, Error> {
        codeValuePublisher()
            .digitsRenderer(digits: totpGenerator.digits)
    }

    private func codeValuePublisher() -> AnyPublisher<UInt32, Error> {
        let generator = totpGenerator
        return clock.secondsPublisher()
            .setFailureType(to: Error.self)
            .tryMap { epochSeconds in
                try generator.code(epochSeconds: epochSeconds)
            }
            .eraseToAnyPublisher()
    }
}

final class HOTPCodeRenderer: OTPCodeRenderer {
    private let hotpGenerator: HOTPGenerator
    private let counterSubject: CurrentValueSubject<UInt64, Never>

    init(hotpGenerator: HOTPGenerator, initialCounter: UInt64) {
        self.hotpGenerator = hotpGenerator
        counterSubject = CurrentValueSubject(initialCounter)
    }

    /// Update the current value of the counter.
    func set(counter: UInt64) {
        counterSubject.send(counter)
    }

    func renderedCodePublisher() -> AnyPublisher<String, Error> {
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
