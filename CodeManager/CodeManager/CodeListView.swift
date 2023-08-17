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
struct CodeListView<Store: OTPCodeStore>: View {
    @ObservedObject var feedViewModel: FeedViewModel<Store>
    @ObservedObject var totpPreviewGenerator: TOTPPreviewViewGenerator
    @ObservedObject var hotpPreviewGenerator: HOTPPreviewViewGenerator

    @EnvironmentObject var pasteboard: Pasteboard
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
            viewGenerator: GenericOTPViewGenerator { id, code, isEditing in
                switch code.type {
                case let .totp(period):
                    totpEditingGenerator().makeOTPView(
                        id: id,
                        code: .init(period: period, data: code.data),
                        isEditing: isEditing
                    )
                case let .hotp(counter):
                    hotpEditingGenerator().makeOTPView(
                        id: id,
                        code: .init(counter: counter, data: code.data),
                        isEditing: isEditing
                    )
                }
            },
            isEditing: $isEditing,
            gridSpacing: 12
        )
        .navigationTitle(Text(feedViewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !feedViewModel.codes.isEmpty {
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
                storedCode: storedCode
            )
        case .hotp:
            CodeDetailView(
                feedViewModel: feedViewModel,
                storedCode: storedCode
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
                } else if let code = totpPreviewGenerator.currentCode(id: id) {
                    pasteboard.copy(code)
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
                } else if let code = hotpPreviewGenerator.currentCode(id: id) {
                    pasteboard.copy(code)
                }
            }
        )
    }
}

struct OTPOnTapDecoratorViewGenerator<Generator: OTPViewGenerator>: OTPViewGenerator {
    typealias Code = Generator.Code
    let generator: Generator
    let onTap: (UUID) -> Void

    func makeOTPView(id: UUID, code: Code, isEditing: Bool) -> some View {
        Button {
            onTap(id)
        } label: {
            generator.makeOTPView(id: id, code: code, isEditing: isEditing)
                .modifier(OTPCardViewModifier())
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
