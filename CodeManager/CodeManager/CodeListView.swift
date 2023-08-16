//
//  CodeListView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import OTPCore
import OTPFeed
import OTPFeediOS
import SwiftUI

@MainActor
struct CodeListView<Store: OTPCodeStoreReader>: View {
    @ObservedObject var feedViewModel: FeedViewModel<Store>
    @ObservedObject var totpPreviewGenerator: TOTPPreviewViewGenerator
    @ObservedObject var hotpPreviewGenerator: HOTPPreviewViewGenerator
    @Binding var isShowingCopyPaste: Bool

    @State private var isEditing = false
    @State private var modal: Modal?

    enum Modal: Identifiable {
        case detail(UUID, StoredOTPCode)

        var id: some Hashable {
            switch self {
            case let .detail(id, _):
                return id
            }
        }
    }

    var body: some View {
        OTPCodeFeedView(
            viewModel: feedViewModel,
            viewGenerator: GenericGenerator(
                totpGenerator: totpEditingGenerator(),
                hotpGenerator: hotpEditingGenerator()
            ),
            isEditing: $isEditing,
            gridSpacing: 12
        )
        .navigationTitle(Text(feedViewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? feedViewModel.doneEditingTitle : feedViewModel.editTitle)
                        .fontWeight(isEditing ? .semibold : .regular)
                        .animation(.none)
                }
            }
        }
        .sheet(item: $modal) { visible in
            switch visible {
            case let .detail(_, storedCode):
                NavigationView {
                    detailView(storedCode: storedCode)
                }
            }
        }
    }

    @ViewBuilder
    private func detailView(storedCode: StoredOTPCode) -> some View {
        switch storedCode.code.type {
        case .totp:
            CodeDetailView(
                feedViewModel: feedViewModel,
                storedCode: storedCode,
                preview: Text("TOTP")
            )
        case .hotp:
            CodeDetailView(
                feedViewModel: feedViewModel,
                storedCode: storedCode,
                preview: Text("HOTP")
            )
        }
    }

    func totpEditingGenerator() -> OTPOnTapDecoratorViewGenerator<TOTPPreviewViewGenerator> {
        OTPOnTapDecoratorViewGenerator(
            generator: totpPreviewGenerator,
            onTap: { id in
                if isEditing {
                    guard let code = feedViewModel.code(id: id) else { return }
                    modal = .detail(id, code)
                } else {
                    isShowingCopyPaste = true
                }
            }
        )
    }

    func hotpEditingGenerator() -> OTPOnTapDecoratorViewGenerator<HOTPPreviewViewGenerator> {
        OTPOnTapDecoratorViewGenerator(
            generator: hotpPreviewGenerator,
            onTap: { id in
                if isEditing {
                    guard let code = feedViewModel.code(id: id) else { return }
                    modal = .detail(id, code)
                } else {
                    isShowingCopyPaste = true
                }
            }
        )
    }
}

struct GenericGenerator<TOTP, HOTP>: OTPViewGenerator where
    TOTP: OTPViewGenerator,
    TOTP.Code == TOTPAuthCode,
    HOTP: OTPViewGenerator,
    HOTP.Code == HOTPAuthCode
{
    typealias Code = GenericOTPAuthCode

    let totpGenerator: TOTP
    let hotpGenerator: HOTP

    @ViewBuilder
    func makeOTPView(id: UUID, code: Code, isEditing: Bool) -> some View {
        if let totp = TOTPAuthCode(generic: code) {
            totpGenerator.makeOTPView(id: id, code: totp, isEditing: isEditing)
        } else if let hotp = HOTPAuthCode(generic: code) {
            hotpGenerator.makeOTPView(id: id, code: hotp, isEditing: isEditing)
        } else {
            Text("Unsupported code")
        }
    }
}

struct OTPOnTapDecoratorViewGenerator<Generator: OTPViewGenerator>: OTPViewGenerator {
    typealias Code = Generator.Code
    let generator: Generator
    let onTap: (UUID) -> Void

    func makeOTPView(id: UUID, code: Code, isEditing: Bool) -> some View {
        generator.makeOTPView(id: id, code: code, isEditing: isEditing)
            .modifier(OnTapOverrideButtonModifier(onTap: {
                onTap(id)
            }))
    }
}

struct OnTapOverrideButtonModifier: ViewModifier {
    let onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .modifier(OTPCardViewModifier())
            .onTapGesture {
                onTap()
            }
    }
}

struct OTPCardViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
