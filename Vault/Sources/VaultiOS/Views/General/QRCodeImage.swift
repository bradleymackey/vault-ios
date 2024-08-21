import Foundation
import ImageTools
import SwiftUI
import UIKit

struct QRCodeImage: View {
    @State private var viewModel = ViewModel()
    @State private var data: Data

    init(data: Data) {
        self.data = data
    }

    var body: some View {
        ZStack(alignment: .center) {
            qrImage
        }
        .onAppear {
            viewModel.render(data: data)
        }
    }

    @ViewBuilder
    private var qrImage: some View {
        switch viewModel.state {
        case let .showing(uIImage):
            Image(uiImage: uIImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
        case .renderingError:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)
        case nil:
            EmptyView()
        }
    }
}

extension QRCodeImage {
    @Observable
    final class ViewModel {
        enum ImageState {
            case showing(UIImage)
            case renderingError
        }

        var state: ImageState?
        private let renderer = QRCodeImageRenderer()

        func render(data: Data) {
            if let image = renderer.makeImage(fromData: data) {
                state = .showing(image)
            } else {
                state = .renderingError
            }
        }
    }
}
