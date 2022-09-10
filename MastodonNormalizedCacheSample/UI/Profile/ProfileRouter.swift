import SwiftUI

enum ProfileRoute: Hashable {
    case timelineDetail(id: Status.ID)
}

class ProfileRouter: ObservableObject {
    @Published var path = NavigationPath()

    func navigateToTimelineDetail(statusID: Status.ID) {
        path.append(ProfileRoute.timelineDetail(id: statusID))
    }
}
