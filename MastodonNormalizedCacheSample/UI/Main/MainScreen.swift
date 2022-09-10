import SwiftUI

enum MainTabItem: Hashable {
    case timeline
    case profile
}

struct MainScreen: View {
    @StateObject private var viewModel: MainViewModel
    @StateObject private var timelineRouter = HomeTimelineRouter()
    @StateObject private var profileRouter = ProfileRouter()
    @State private var selectedTabItem: MainTabItem = .timeline

    init() {
        _viewModel = StateObject(wrappedValue: MainViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTabItem) {
            NavigationStack(path: $timelineRouter.path) {
                HomeTimelineScreen()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                viewModel.onLogoutTapped()
                            } label: {
                                Text("Logout")
                            }
                        }
                    }
                    .navigationTitle("mstdn.jp")
                    .navigationDestination(for: HomeTimelineRoute.self) { route in
                        switch route {
                        case .timelineDetail(let id):
                            TimelineDetailScreen(statusID: id)
                        }
                    }
            }
            .environmentObject(timelineRouter)
            .tabItem {
                Image(systemName: "newspaper.fill")
            }
            .tag(MainTabItem.timeline)

            NavigationStack {
                ProfileScreen()
                    .navigationTitle("Profile")
                    .navigationDestination(for: ProfileRoute.self) { route in
                        switch route {
                        case .timelineDetail(let id):
                            TimelineDetailScreen(statusID: id)
                        }
                    }
            }
            .environmentObject(profileRouter)
            .tabItem {
                Image(systemName: "person.fill")
            }
            .tag(MainTabItem.profile)
        }
    }
}
