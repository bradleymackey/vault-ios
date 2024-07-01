import Combine
import CryptoEngine
import Foundation
import VaultCore

/// Renders the code to a visible state for the given `code`.
public protocol OTPCodeRenderer {
    func renderedCodePublisher() -> AnyPublisher<String, any Error>
}

// MARK: - Mock

public final class OTPCodeRendererMock: OTPCodeRenderer {
    public init() {}
    public let subject = PassthroughSubject<String, any Error>()
    public func renderedCodePublisher() -> AnyPublisher<String, any Error> {
        subject.eraseToAnyPublisher()
    }
}

// MARK: - Impl

public final class TOTPCodeRenderer: OTPCodeRenderer {
    private let timer: any OTPCodeTimerUpdater
    private let totpGenerator: TOTPGenerator

    public init(timer: any OTPCodeTimerUpdater, totpGenerator: TOTPGenerator) {
        self.timer = timer
        self.totpGenerator = totpGenerator
    }

    public func renderedCodePublisher() -> AnyPublisher<String, any Error> {
        codeValuePublisher()
            .digitsRenderer(digits: Int(totpGenerator.digits))
    }

    private func codeValuePublisher() -> AnyPublisher<BigUInt, any Error> {
        let generator = totpGenerator
        return timer.timerUpdatedPublisher()
            .setFailureType(to: (any Error).self)
            .tryMap { state in
                try generator.code(epochSeconds: UInt64(state.startTime))
            }
            .eraseToAnyPublisher()
    }
}

public final class HOTPCodeRenderer: OTPCodeRenderer {
    private let hotpGenerator: HOTPGenerator
    private let counterSubject: PassthroughSubject<UInt64, Never>

    public init(hotpGenerator: HOTPGenerator) {
        self.hotpGenerator = hotpGenerator
        counterSubject = PassthroughSubject()
    }

    /// Update the current value of the counter.
    public func set(counter: UInt64) {
        counterSubject.send(counter)
    }

    public func renderedCodePublisher() -> AnyPublisher<String, any Error> {
        codeValuePublisher()
            .digitsRenderer(digits: Int(hotpGenerator.digits))
    }

    private func codeValuePublisher() -> AnyPublisher<BigUInt, any Error> {
        let generator = hotpGenerator
        return counterSubject
            .setFailureType(to: (any Error).self)
            .tryMap { counterValue in
                try generator.code(counter: counterValue)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension Publisher where Output == BigUInt {
    func digitsRenderer(digits: Int) -> AnyPublisher<String, Failure> {
        map { codeNumber in
            String(codeNumber).leftPadding(toLength: digits, withPad: "0")
        }
        .eraseToAnyPublisher()
    }
}

extension String {
    fileprivate func leftPadding(toLength newLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < newLength {
            return String(repeatElement(character, count: newLength - stringLength)) + self
        } else {
            return String(suffix(newLength))
        }
    }
}
