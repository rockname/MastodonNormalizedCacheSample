import SwiftUI

struct StatusRow: View {
    let status: Status
    let onFavoriteTapped: () -> Void
    let onUnfavoriteTapped: () -> Void
    let onRowTapped: () -> Void

    var body: some View {
        Button {
            onRowTapped()
        } label: {
            StatusContent(
                status: status,
                onFavoriteTapped: onFavoriteTapped,
                onUnfavoriteTapped: onUnfavoriteTapped
            )
        }
    }
}
