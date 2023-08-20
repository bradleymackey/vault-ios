import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeFeedView<
    Store: OTPCodeStore,
    ViewGenerator: OTPViewGenerator
>: View where
    ViewGenerator.Code == GenericOTPAuthCode
{
    @ObservedObject public var viewModel: FeedViewModel<Store>
    public var viewGenerator: ViewGenerator
    @Binding public var isEditing: Bool
    public var gridSpacing: Double

    @State private var isReordering = false

    public init(
        viewModel: FeedViewModel<Store>,
        viewGenerator: ViewGenerator,
        isEditing: Binding<Bool>,
        gridSpacing: Double = 8
    ) {
        self.viewModel = viewModel
        self.viewGenerator = viewGenerator
        _isEditing = Binding(projectedValue: isEditing)
        self.gridSpacing = gridSpacing
    }

    public var body: some View {
        VStack {
            if viewModel.codes.isEmpty {
                noCodesView
            } else {
                listOfCodesView
            }
        }
        .task {
            await viewModel.reloadData()
        }
    }

    private var noCodesView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "key.viewfinder")
                .font(.largeTitle)
            Text(localized(key: "codeFeed.noCodes.title"))
                .font(.headline.bold())
        }
        .foregroundColor(.secondary)
        .padding()
    }

    private var reorderingBehaviour: OTPViewBehaviour {
        .obfuscate(message: nil)
    }

    private var currentBehaviour: OTPViewBehaviour? {
        if isEditing {
            return .obfuscate(message: localized(key: "action.tapToEdit"))
        } else if isReordering {
            return reorderingBehaviour
        } else {
            return nil
        }
    }

    private var listOfCodesView: some View {
        ScrollView {
            LazyVGrid(columns: columns, content: {
                ReorderableForEach(items: viewModel.codes, isDragging: $isReordering, isEnabled: isEditing) { code in
                    viewGenerator.makeOTPView(id: code.id, code: code.code, behaviour: currentBehaviour)
                } previewContent: { code in
                    viewGenerator.makeOTPView(id: code.id, code: code.code, behaviour: reorderingBehaviour)
                } moveAction: { from, to in
                    viewModel.codes.move(fromOffsets: from, toOffset: to)
                }
            })
            .padding()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: gridSpacing, alignment: .top)]
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: InMemoryCodeStore(codes: [
                .init(
                    id: UUID(),
                    created: Date(),
                    updated: Date(),
                    userDescription: "My Cool Code",
                    code: .init(
                        type: .totp(),
                        data: .init(
                            secret: .empty(),
                            accountName: "example@example.com",
                            issuer: "i"
                        )
                    )
                ),
            ])),
            viewGenerator: GenericGenerator(),
            isEditing: .constant(false)
        )
    }

    struct GenericGenerator: OTPViewGenerator {
        func makeOTPView(id _: UUID, code _: GenericOTPAuthCode, behaviour _: OTPViewBehaviour?) -> some View {
            Text("Code")
        }
    }
}
