import SwiftUI

struct TimelineContent: View {
    let statuses: [Status]
    let onStatusAppear: (Status.ID) async -> Void
    let onFavoriteTapped: (Status.ID) -> Void
    let onUnfavoriteTapped: (Status.ID) -> Void
    let onStatusTapped: (Status.ID) -> Void

    var body: some View {
        List {
            ForEach(statuses) { status in
                StatusRow(
                    status: status,
                    onFavoriteTapped: {
                        onFavoriteTapped(status.id)
                    },
                    onUnfavoriteTapped: {
                        onUnfavoriteTapped(status.id)
                    },
                    onRowTapped: {
                        onStatusTapped(status.id)
                    }
                )
                .listRowInsets(EdgeInsets())
                .frame(maxWidth: .infinity)
                .padding(16)
                .task {
                    await onStatusAppear(status.id)
                }
            }
        }
        .listStyle(.plain)
    }
}
