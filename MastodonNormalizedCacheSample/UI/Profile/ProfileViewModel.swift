import Foundation
import Combine

enum ProfileUIState {
    case initial
    case loading
    case success(account: Account)
    case failed
}

enum UserTimelineUIState {
    case initial
    case loading
    case noStatuses
    case hasStatuses(statuses: [Status])
    case failed

    var statuses: [Status]? {
        switch self {
        case .initial, .loading, .noStatuses, .failed: return nil
        case .hasStatuses(let statuses): return statuses
        }
    }
}

@MainActor class ProfileViewModel: ObservableObject {
    @Published private(set) var profileUIState = ProfileUIState.initial
    @Published private(set) var userTimelineUIState = UserTimelineUIState.initial

    private let userTimelineRepository: UserTimelineRepository
    private let accountRepository: AccountRepository

    private var cancellables = Set<AnyCancellable>()

    init(
        userTimelineRepository: UserTimelineRepository = .init(
            accountID: CurrentAccountIDStore().load()!
        ),
        accountRepository: AccountRepository = .init()
    ) {
        self.userTimelineRepository = userTimelineRepository
        self.accountRepository = accountRepository
        watchProfile()
        watchUserTimeline()
    }

    func onProfileAppear() async {
        guard case .initial = profileUIState else { return }

        await loadProfile()
    }

    func onUserTimelineAppear() async {
        guard case .initial = userTimelineUIState else { return }

        await loadUserTimeline()
    }

    func onStatusAppear(statusID: Status.ID) async {
        guard
            let statuses = userTimelineUIState.statuses,
            statuses.firstIndex(where: { $0.id == statusID }) == statuses.endIndex - 1
        else { return }

        do {
            try await userTimelineRepository.fetchNextTimeline()
        } catch {
            print(error)
        }
    }

    func onFavoriteTapped(statusID: Status.ID) async {
        do {
            try await userTimelineRepository.favoriteStatus(by: statusID)
        } catch {
            print(error)
        }
    }

    func onUnfavoriteTapped(statusID: Status.ID) async {
        do {
            try await userTimelineRepository.unfavoriteStatus(by: statusID)
        } catch {
            print(error)
        }
    }

    private func loadProfile() async {
        do {
            profileUIState = .loading
            try await accountRepository.fetchMyAccount()
        } catch {
            print(error)
            profileUIState = .failed
        }
    }

    private func loadUserTimeline() async {
        do {
            userTimelineUIState = .loading
            try await userTimelineRepository.fetchInitialTimeline()
        } catch {
            print(error)
            userTimelineUIState = .failed
        }
    }

    private func watchProfile() {
        accountRepository.watch()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                self?.profileUIState = .success(account: account)
            }
            .store(in: &cancellables)
    }

    private func watchUserTimeline() {
        userTimelineRepository.watch()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statuses in
                if statuses.isEmpty {
                    self?.userTimelineUIState = .noStatuses
                } else {
                    self?.userTimelineUIState = .hasStatuses(statuses: statuses)
                }
            }
            .store(in: &cancellables)
    }
}
