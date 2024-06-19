import Combine
import Foundation
import VaultCore

/// A preview of an OTP code.
@MainActor
@Observable
public final class OTPCodePreviewViewModel {
    public let accountName: String
    public let issuer: String
    public let color: VaultItemColor
    public private(set) var code: OTPCodeState = .notReady

    public var visibleIssuer: String {
        if issuer.isNotEmpty {
            issuer
        } else {
            localized(key: "codeDetail.field.siteName.empty.title")
        }
    }

    private var cancellables = Set<AnyCancellable>()

    public init(
        accountName: String,
        issuer: String,
        color: VaultItemColor,
        fixedCodeState: OTPCodeState
    ) {
        self.accountName = accountName
        self.issuer = issuer
        self.color = color
        code = fixedCodeState
    }

    public init(
        accountName: String,
        issuer: String,
        color: VaultItemColor,
        renderer: some OTPCodeRenderer
    ) {
        self.accountName = accountName
        self.color = color
        self.issuer = issuer
        renderer.renderedCodePublisher()
            .sink { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    code = .finished
                case let .failure(error):
                    code = .error(
                        PresentationError(
                            userTitle: localized(key: "codePreview.codeGenerationError.title"),
                            userDescription: localized(key: "codePreview.codeGenerationError.description"),
                            debugDescription: error.localizedDescription
                        ),
                        digits: 6
                    )
                }
            } receiveValue: { [weak self] code in
                guard let self else { return }
                self.code = .visible(code)
            }
            .store(in: &cancellables)
    }

    public func update(code: OTPCodeState) {
        self.code = code
    }

    public func hideCodeUntilNextUpdate() {
        code = .obfuscated
    }
}
