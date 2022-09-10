import SwiftUI
import AuthenticationServices

@MainActor
class OnboardingViewModel: ObservableObject {
    private let authenticationRepository: AuthenticationRepository

    private var session: ASWebAuthenticationSession?

    init(authenticationRepository: AuthenticationRepository = .init()) {
        self.authenticationRepository = authenticationRepository
    }

    func onLoginButtonClick(presentationContextProvider: AuthPresentationContextProver) async {
        do {
            let application = try await authenticationRepository.createApplication()
            guard let authorizeURL = authenticationRepository.constructAuthorizeURL(with: application) else {
                return
            }

            session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: "rockname-mastodon-sample"
            ) { [weak self] url, error in
                guard
                    let self = self,
                    let url = url,
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                    let codeQueryItem = components.queryItems?.first(where: { $0.name == "code" }),
                    let code = codeQueryItem.value
                else { return }

                Task {
                    do {
                        try await self.authenticationRepository.authenticate(application: application, code: code)
                    } catch {
                        print(error)
                    }
                }
            }
            session?.presentationContextProvider = presentationContextProvider
            session?.start()
        } catch {
            print(error)
        }
    }
}

class AuthPresentationContextProver: NSObject, ASWebAuthenticationPresentationContextProviding {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        viewController?.view.window ?? ASPresentationAnchor()
    }
}
