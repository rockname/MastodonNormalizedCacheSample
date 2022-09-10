import SwiftUI

struct StatusContent: View {
    let status: Status
    let onFavoriteTapped: () -> Void
    let onUnfavoriteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: status.account.avatar)) { image in
                    image
                        .resizable()
                        .clipShape(Circle())
                } placeholder: {
                    Color.gray
                        .clipShape(Circle())
                        .redacted(reason: .placeholder)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(status.account.displayName)
                            .font(.headline)
                        Spacer()
                        Button {
                            if status.favourited == true {
                                onUnfavoriteTapped()
                            } else {
                                onFavoriteTapped()
                            }
                        } label: {
                            Image(systemName: status.favourited == true ? "star.fill" : "star")
                        }
                    }
                    Text(status.formattedCreatedAt)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Text(status.normalizedContent ?? "")
                .font(.body)
                .lineSpacing(1.0)
        }
    }
}
