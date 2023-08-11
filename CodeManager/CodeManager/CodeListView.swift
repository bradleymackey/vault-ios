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
            totpGenerator: totpEditingGenerator(),
            hotpGenerator: hotpEditingGenerator(),
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
        case let .totp(period):
            CodeDetailView(
                feedViewModel: feedViewModel,
                storedCode: storedCode,
                preview: totpGenerator().makeTOTPView(period: period, code: storedCode)
            )
        case let .hotp(counter):
            CodeDetailView(
                feedViewModel: feedViewModel,
                storedCode: storedCode,
                preview: hotpGenerator().makeHOTPView(counter: counter, code: storedCode)
            )
        }
    }

    func totpGenerator() -> some TOTPViewGenerator {
        TOTPPreviewViewGenerator(
            clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
            timer: LiveIntervalTimer(),
            isEditing: isEditing
        )
    }

    func totpEditingGenerator() -> some TOTPViewGenerator {
        TOTPOnTapDecoratorViewGenerator(
            generator: totpGenerator(),
            isTapEnabled: isEditing,
            onTap: { code in
                modal = .detail(UUID(), code)
            }
        )
    }

    func hotpGenerator() -> some HOTPViewGenerator {
        HOTPPreviewViewGenerator(timer: LiveIntervalTimer(), isEditing: isEditing)
    }

    func hotpEditingGenerator() -> some HOTPViewGenerator {
        HOTPOnTapDecoratorViewGenerator(
            generator: hotpGenerator(),
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
    let onTap: (StoredOTPCode) -> Void

    func makeTOTPView(period: UInt64, code: StoredOTPCode) -> some View {
        generator.makeTOTPView(period: period, code: code)
            .modifier(OnTapOverrideButtonModifier(isTapEnabled: isTapEnabled, onTap: {
                onTap(code)
            }))
    }
}

struct HOTPOnTapDecoratorViewGenerator<Generator: HOTPViewGenerator>: HOTPViewGenerator {
    let generator: Generator
    let isTapEnabled: Bool
    let onTap: (StoredOTPCode) -> Void

    func makeHOTPView(counter: UInt64, code: StoredOTPCode) -> some View {
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
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
