import SwiftUI

struct OnboardingScreen: View {
    @StateObject private var viewModel: OnboardingViewModel

    init() {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel())
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("🦣")
                        .font(.system(size: 80))
                    Text("mstdn.jp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                Text("mstdn.jp is the largest mastodon server in Japan.\nYou need an account to login.")
                    .font(.body)
            }
            Spacer()
            Button {
                let viewController = UIHostingController(rootView: self)
                let presentationContextProvider = AuthPresentationContextProver(viewController: viewController)
                Task {
                    await viewModel.onLoginButtonClick(presentationContextProvider: presentationContextProvider)
                }
            } label: {
                Text("Login")
                    .font(.headline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
    }
}
