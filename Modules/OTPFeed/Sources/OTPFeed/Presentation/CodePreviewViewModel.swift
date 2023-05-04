import Combine
import Foundation
import OTPCore

/// A preview of an OTP code.
public final class CodePreviewViewModel: ObservableObject {
    @Published public private(set) var code: VisibleCode = .notReady

    public enum VisibleCode: Equatable {
        case notReady
        case noMoreCodes
        case visible(String)
        case error(PresentationError)
    }

    private var cancellables = Set<AnyCancellable>()

    public init(renderer: some OTPCodeRenderer) {
        renderer.renderedCodePublisher()
            .sink { completion in
                switch completion {
                case .finished:
                    self.code = .noMoreCodes
                case let .failure(error):
                    self.code = .error(
                        PresentationError(
                            userTitle: "Error",
                            debugDescription: error.localizedDescription
                        )
                    )
                }
            } receiveValue: { code in
                self.code = .visible(code)
            }
            .store(in: &cancellables)
    }
}
