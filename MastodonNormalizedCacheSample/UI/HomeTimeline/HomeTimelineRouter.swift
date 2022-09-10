import SwiftUI

enum HomeTimelineRoute: Hashable {
    case timelineDetail(id: Status.ID)
}

class HomeTimelineRouter: ObservableObject {
    @Published var path = NavigationPath()

    func navigateToTimelineDetail(statusID: Status.ID) {
        path.append(HomeTimelineRoute.timelineDetail(id: statusID))
    }
}
