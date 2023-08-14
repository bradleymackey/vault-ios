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
            generator: TOTPPreviewViewGenerator(
                clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
                timer: LiveIntervalTimer(),
                isEditing: isEditing
            ),
            isTapEnabled: isEditing,
            onTap: { id in
                guard let code = feedViewModel.code(id: id) else { return }
                modal = .detail(id, code)
            }
        )
    }

    func hotpEditingGenerator() -> OTPOnTapDecoratorViewGenerator<HOTPPreviewViewGenerator> {
        OTPOnTapDecoratorViewGenerator(
            generator: HOTPPreviewViewGenerator(timer: LiveIntervalTimer(), isEditing: isEditing),
            isTapEnabled: isEditing,
            onTap: { id in
                guard let code = feedViewModel.code(id: id) else { return }
                modal = .detail(id, code)
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
    func makeOTPView(id: UUID, code: Code) -> some View {
        if let totp = TOTPAuthCode(generic: code) {
            totpGenerator.makeOTPView(id: id, code: totp)
        } else if let hotp = HOTPAuthCode(generic: code) {
            hotpGenerator.makeOTPView(id: id, code: hotp)
        } else {
            Text("Unsupported code")
        }
    }
}

struct OTPOnTapDecoratorViewGenerator<Generator: OTPViewGenerator>: OTPViewGenerator {
    typealias Code = Generator.Code
    let generator: Generator
    let isTapEnabled: Bool
    let onTap: (UUID) -> Void

    func makeOTPView(id: UUID, code: Code) -> some View {
        generator.makeOTPView(id: id, code: code)
            .modifier(OnTapOverrideButtonModifier(isTapEnabled: isTapEnabled, onTap: {
                onTap(id)
            }))
    }
}

struct OnTapOverrideButtonModifier: ViewModifier {
    let isTapEnabled: Bool
    let onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .modifier(OTPCardViewModifier(isSelectable: isTapEnabled))
            .disabled(isTapEnabled)
            .onTapGesture {
                guard isTapEnabled else { return }
                onTap()
            }
    }
}

struct OTPCardViewModifier: ViewModifier {
    var isSelectable: Bool

    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
