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
struct CodeListView<Store: OTPCodeStoreReader, TOTPGenerator: TOTPViewGenerator>: View {
    @ObservedObject var feedViewModel: FeedViewModel<Store>
    var generator: TOTPGenerator

    @State private var isEditing = false
    @State private var modal: Modal?

    enum Modal: Identifiable {
        case detail(UUID, OTPAuthCode)

        var id: some Hashable {
            switch self {
            case let .detail(id, _):
                return id
            }
        }
    }

    var body: some View {
        NavigationView {
            OTPCodeFeedView(
                viewModel: feedViewModel,
                totpGenerator: totpEditingGenerator(hideCodes: isEditing),
                hotpGenerator: hotpEditingGenerator(hideCodes: isEditing),
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
                case let .detail(_, code):
                    NavigationView {
                        detailView(code: code)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func detailView(code: OTPAuthCode) -> some View {
        switch code.type {
        case let .totp(period):
            CodeDetailView(
                feedViewModel: feedViewModel,
                code: code,
                preview: generator.makeTOTPView(period: period, code: code)
            )
        case let .hotp(counter):
            CodeDetailView(
                feedViewModel: feedViewModel,
                code: code,
                preview: hotpGenerator().makeHOTPView(counter: counter, code: code)
            )
        }
    }

    func totpEditingGenerator(hideCodes _: Bool) -> some TOTPViewGenerator {
        TOTPOnTapDecoratorViewGenerator(
            generator: generator,
            isTapEnabled: isEditing,
            onTap: { code in
                modal = .detail(UUID(), code)
            }
        )
    }

    func hotpGenerator(hideCodes: Bool = false) -> some HOTPViewGenerator {
        HOTPPreviewViewGenerator(timer: LiveIntervalTimer(), hideCodes: hideCodes)
    }

    func hotpEditingGenerator(hideCodes: Bool) -> some HOTPViewGenerator {
        HOTPOnTapDecoratorViewGenerator(
            generator: hotpGenerator(hideCodes: hideCodes),
            isTapEnabled: isEditing,
            onTap: { code in
                modal = .detail(UUID(), code)
            }
        )
    }
}

struct TOTPOnTapDecoratorViewGenerator<Generator: TOTPViewGenerator>: TOTPViewGenerator {
    let generator: Generator
    let isTapEnabled: Bool
    let onTap: (OTPAuthCode) -> Void

    func makeTOTPView(period: UInt64, code: OTPAuthCode) -> some View {
        generator.makeTOTPView(period: period, code: code)
            .modifier(OnTapOverrideButtonModifier(isTapEnabled: isTapEnabled, onTap: {
                onTap(code)
            }))
    }
}

struct HOTPOnTapDecoratorViewGenerator<Generator: HOTPViewGenerator>: HOTPViewGenerator {
    let generator: Generator
    let isTapEnabled: Bool
    let onTap: (OTPAuthCode) -> Void

    func makeHOTPView(counter: UInt64, code: OTPAuthCode) -> some View {
        generator.makeHOTPView(counter: counter, code: code)
            .modifier(OnTapOverrideButtonModifier(isTapEnabled: isTapEnabled, onTap: {
                onTap(code)
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
            .background(isSelectable ? .blue.opacity(0.2) : Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
