import SwiftUI
import Combine

enum HomeTimelineUIState {
    case initial
    case loading
    case noStatuses
    case hasStatuses(statuses: [Status])

    var statuses: [Status]? {
        switch self {
        case .initial, .loading, .noStatuses: return nil
        case .hasStatuses(let statuses): return statuses
        }
    }
}

@MainActor
class HomeTimelineViewModel: ObservableObject {
    @Published private(set) var uiState: HomeTimelineUIState = .initial

    private let homeTimelineRepository: HomeTimelineRepository
    private var cancellables = Set<AnyCancellable>()

    init(homeTimelineRepository: HomeTimelineRepository = .init()) {
        self.homeTimelineRepository = homeTimelineRepository
        homeTimelineRepository.watch()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statuses in
                if statuses.isEmpty {
                    self?.uiState = .noStatuses
                } else {
                    self?.uiState = .hasStatuses(statuses: statuses)
                }
            }
            .store(in: &cancellables)
    }

    func onAppear() async {
        guard case .initial = uiState else { return }

        do {
            uiState = .loading
            try await homeTimelineRepository.fetchInitialTimeline()
        } catch {
            print(error)
        }
    }

    func onStatusAppear(statusID: Status.ID) async {
        guard
            let statuses = uiState.statuses,
            statuses.firstIndex(where: { $0.id == statusID }) == statuses.endIndex - 1
        else { return }

        do {
            try await homeTimelineRepository.fetchNextTimeline()
        } catch {
            print(error)
        }
    }

    func onFavoriteTapped(statusID: Status.ID) async {
        do {
            try await homeTimelineRepository.favoriteStatus(by: statusID)
        } catch {
            print(error)
        }
    }

    func onUnfavoriteTapped(statusID: Status.ID) async {
        do {
            try await homeTimelineRepository.unfavoriteStatus(by: statusID)
        } catch {
            print(error)
        }
    }
}
