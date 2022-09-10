import SwiftUI

struct TimelineDetailScreen: View {
    @StateObject private var viewModel: TimelineDetailViewModel

    init(statusID: Status.ID) {
        _viewModel = StateObject(wrappedValue: TimelineDetailViewModel(statusID: statusID))
    }

    var body: some View {
        ZStack {
            switch viewModel.uiState {
            case .initial: ZStack {}
            case .loading: ProgressView()
            case .failed: Text("Failed to load status")
            case let .success(status):
                StatusContent(
                    status: status,
                    onFavoriteTapped: {
                        Task {
                            await viewModel.onFavoriteTapped()
                        }
                    },
                    onUnfavoriteTapped: {
                        Task {
                            await viewModel.onUnfavoriteTapped()
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .padding(16)
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }
}
