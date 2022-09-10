import SwiftUI
import Combine

enum TimelineDetailUIState {
    case initial
    case loading
    case success(status: Status)
    case failed
}

@MainActor
class TimelineDetailViewModel: ObservableObject {
    @Published private(set) var uiState: TimelineDetailUIState = .initial

    private let statusID: Status.ID
    private let statusRepository: StatusRepository
    private var cancellables = Set<AnyCancellable>()

    init(statusID: Status.ID, statusRepository: StatusRepository = .init()) {
        self.statusID = statusID
        self.statusRepository = statusRepository
        statusRepository.watch()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.uiState = .success(status: status)
            }
            .store(in: &cancellables)
    }

    func onAppear() async {
        guard case .initial = uiState else {
            return
        }

        do {
            uiState = .loading
            try await statusRepository.fetchStatus(by: statusID)
        } catch {
            print(error)
            uiState = .failed
        }
    }

    func onFavoriteTapped() async {
        guard case .success(let status) = uiState else {
            return
        }

        Task {
            do {
                try await statusRepository.favoriteStatus(by: status.id)
            } catch {
                print(error)
            }
        }
    }

    func onUnfavoriteTapped() async {
        guard case .success(let status) = uiState else {
            return
        }

        Task {
            do {
                try await statusRepository.unfavoriteStatus(by: status.id)
            } catch {
                print(error)
            }
        }
    }
}
