import SwiftUI

struct HomeTimelineScreen: View {
    @StateObject private var viewModel: HomeTimelineViewModel
    @EnvironmentObject private var homeTimelineRouter: HomeTimelineRouter

    init(homeTimelineRepository: HomeTimelineRepository = .init()) {
        _viewModel = StateObject(wrappedValue: HomeTimelineViewModel())
    }

    var body: some View {
        ZStack {
            switch viewModel.uiState {
            case .initial:
                ZStack {}
            case .loading:
                ProgressView()
            case .noStatuses:
                Text("No statuses")
            case let .hasStatuses(statuses):
                TimelineContent(
                    statuses: statuses,
                    onStatusAppear: { statusID in
                        await viewModel.onStatusAppear(statusID: statusID)
                    },
                    onFavoriteTapped: { statusID in
                        Task {
                            await viewModel.onFavoriteTapped(statusID: statusID)
                        }
                    },
                    onUnfavoriteTapped: { statusID in
                        Task {
                            await viewModel.onUnfavoriteTapped(statusID: statusID)
                        }
                    },
                    onStatusTapped: { statusID in
                        homeTimelineRouter.navigateToTimelineDetail(statusID: statusID)
                    }
                )
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }
}
