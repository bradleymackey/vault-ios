import SwiftUI
import VaultFeed

@MainActor
struct HOTPCodePreviewView<ButtonView: View>: View {
    var buttonView: ButtonView
    var previewViewModel: OTPCodePreviewViewModel
    var behaviour: VaultItemViewBehaviour

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            labelsStack
            Spacer()
            codeText.layoutPriority(100)
            Spacer()
            timerSection
        }
        .animation(.easeOut, value: behaviour)
        .animation(.easeOut, value: canLoadNextCode)
        .aspectRatio(1, contentMode: .fill)
        .shimmering(active: isEditing)
        .modifier(
            VaultCardModifier(
                configuration: .init(style: isEditing ? .prominent : .secondary, border: previewViewModel.color.color)
            )
        )
    }

    @ViewBuilder
    private var activeTimerView: some View {
        switch behaviour {
        case .normal:
            switch previewViewModel.code {
            case .visible, .locked:
                Color.blue
            case .notReady, .obfuscated:
                Color.gray
            case .error, .finished:
                Color.red
            }
        case .editingState:
            Color.blue
        }
    }

    private var labelsStack: some View {
        HStack(alignment: .top, spacing: 6) {
            icon
                .padding(.top, 2)
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.visibleIssuer)
                .foregroundStyle(isEditing ? .white : .primary)
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var icon: some View {
        if case .error = previewViewModel.code {
            PreviewErrorIcon()
                .font(.callout)
        } else {
            OTPCodeIconPlaceholderView(iconFontSize: 8, backgroundColor: previewViewModel.color.color)
                .clipShape(Circle())
        }
    }

    private var codeText: some View {
        VStack(alignment: .leading, spacing: 4) {
            OTPCodeTextView(codeState: behaviour != .normal ? .notReady : previewViewModel.code)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .padding(.horizontal, 2)
                .foregroundColor(isEditing ? .white : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var timerSection: some View {
        HStack(alignment: .bottom, spacing: 4) {
            CodeStateTimerBarView(
                timerView: activeTimerView,
                codeState: previewViewModel.code,
                behaviour: behaviour
            )
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            buttonView
                .disabled(!canLoadNextCode)
        }
        .animation(.easeOut, value: canLoadNextCode)
    }

    private var canLoadNextCode: Bool {
        previewViewModel.code.allowsNextCodeToBeGenerated && behaviour == .normal
    }

    private var isEditing: Bool {
        switch behaviour {
        case .normal: false
        case .editingState: true
        }
    }
}

#Preview {
    let codePublisher = OTPCodePublisherMock()
    let finishedPublisher = OTPCodePublisherMock()
    let errorPublisher = OTPCodePublisherMock()

    @MainActor
    func makePreviewView(
        accountName: String,
        codePublisher: OTPCodePublisherMock,
        behaviour: VaultItemViewBehaviour = .normal
    ) -> some View {
        let previewViewModel = OTPCodePreviewViewModel(
            accountName: accountName,
            issuer: "Authority",
            color: .default,
            isLocked: false,
            codePublisher: codePublisher
        )
        return HOTPCodePreviewView(
            buttonView: OTPCodeButtonView(
                viewModel: .init(
                    id: .new(),
                    codePublisher: .init(
                        hotpGenerator: .init(secret: Data())
                    ),
                    timer: IntervalTimerImpl(),
                    initialCounter: 0,
                    incrementerStore: VaultStoreHOTPIncrementerMock()
                )
            ),
            previewViewModel: previewViewModel,
            behaviour: behaviour
        )
    }

    return ScrollView(.vertical) {
        makePreviewView(accountName: "Normal", codePublisher: codePublisher)
            .onAppear {
                codePublisher.subject.send("123456")
            }

        makePreviewView(accountName: "Finished", codePublisher: finishedPublisher)
            .onAppear {
                finishedPublisher.subject.send(completion: .finished)
            }

        makePreviewView(accountName: "Error", codePublisher: errorPublisher)
            .onAppear {
                errorPublisher.subject.send(completion: .failure(NSError(domain: "any", code: 100)))
            }

        makePreviewView(
            accountName: "Obfuscate",
            codePublisher: codePublisher,
            behaviour: .editingState(message: "editing")
        )

        makePreviewView(
            accountName: "Obfuscate (no msg)",
            codePublisher: codePublisher,
            behaviour: .editingState(message: nil)
        )
    }
    .padding(.horizontal, 32)
}
