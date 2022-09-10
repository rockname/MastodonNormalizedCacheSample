import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    private let authenticationRepository: AuthenticationRepository

    init(authenticationRepository: AuthenticationRepository = .init()) {
        self.authenticationRepository = authenticationRepository
    }

    func onLogoutTapped() {
        do {
            try authenticationRepository.logout()
        } catch {
            print(error)
        }
    }
}
