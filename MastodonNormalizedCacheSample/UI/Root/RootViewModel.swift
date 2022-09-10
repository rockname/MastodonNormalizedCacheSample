import SwiftUI
import Combine

@MainActor
class RootViewModel: ObservableObject {
    @Published private(set) var isLoggedIn: Bool

    private let authenticationRepository: AuthenticationRepository
    private var cancellables = Set<AnyCancellable>()

    init(authenticationRepository: AuthenticationRepository = .init()) {
        self.authenticationRepository = authenticationRepository
        isLoggedIn = authenticationRepository.isLoggedIn
        authenticationRepository.watchAuthentication()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authentication in
                self?.isLoggedIn = authentication != nil
            }
            .store(in: &cancellables)
    }
}
