import Combine
import OTPFeed
import SwiftUI

public struct CodeTextView: View {
    @StateObject public var viewModel: CodePreviewViewModel
    var codeSpacing: Double

    /// The last number of digits sent by a code, so the placeholder can be accurate.
    @State private var lastCodeNumberOfDigits = 6

    public var body: some View {
        switch viewModel.code {
        case .notReady, .noMoreCodes:
            placeholderCode
        case .error:
            HStack(alignment: .center, spacing: codeSpacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                placeholderCode
            }
            .foregroundColor(.red)
        case let .visible(code):
            makeCodeView(text: code)
                .onReceive(viewModel.$code) { update in
                    if case let .visible(code) = update {
                        lastCodeNumberOfDigits = code.count
                    }
                }
        }
    }

    private var placeholderCode: some View {
        makeCodeView(text: String(repeating: "0", count: lastCodeNumberOfDigits))
            .redacted(reason: .placeholder)
    }

    private func makeCodeView(text: String) -> some View {
        OTPCodeText(text: text, spacing: codeSpacing)
    }
}

struct CodeTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CodeTextView(
                viewModel: .init(renderer: codeRenderer),
                codeSpacing: 10
            )
            .onAppear {
                codeRenderer.subject.send("123456")
            }

            CodeTextView(
                viewModel: .init(renderer: finishedRenderer),
                codeSpacing: 10
            )
            .onAppear {
                finishedRenderer.subject.send(completion: .finished)
            }

            CodeTextView(
                viewModel: .init(renderer: errorRenderer),
                codeSpacing: 10
            )
            .onAppear {
                errorRenderer.subject.send("1234567")
                forceRunLoopAdvance()
                errorRenderer.subject.send(completion: .failure(NSError(domain: "anu", code: 100)))
            }
        }
        .font(.system(.largeTitle, design: .monospaced))
    }

    private static let codeRenderer = OTPCodeRendererMock()
    private static let finishedRenderer = OTPCodeRendererMock()
    private static let errorRenderer = OTPCodeRendererMock()

    private struct OTPCodeRendererMock: OTPCodeRenderer {
        let subject = PassthroughSubject<String, Error>()
        func renderedCodePublisher() -> AnyPublisher<String, Error> {
            subject.eraseToAnyPublisher()
        }
    }

    static func forceRunLoopAdvance() {
        RunLoop.main.run(until: Date())
    }
}
