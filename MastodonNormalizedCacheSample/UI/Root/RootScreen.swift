import SwiftUI

struct RootScreen: View {
    @StateObject private var viewModel: RootViewModel

    init() {
        _viewModel = StateObject(wrappedValue: RootViewModel())
    }

    var body: some View {
        if viewModel.isLoggedIn {
            MainScreen()
        } else {
            OnboardingScreen()
        }
    }
}
