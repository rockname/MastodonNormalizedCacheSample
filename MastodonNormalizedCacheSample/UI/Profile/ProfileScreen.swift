import SwiftUI

struct ProfileScreen: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var isProfileEditPresented = false
    @EnvironmentObject private var profileRouter: ProfileRouter

    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    switch viewModel.profileUIState {
                    case .initial: ZStack {}
                    case .loading: ProgressView()
                    case let .success(account):
                        ProfileHeaderContent(
                            account: account,
                            onEditInfoTapped: {
                                isProfileEditPresented = true
                            }
                        )
                        .sheet(isPresented: $isProfileEditPresented) {
                            NavigationStack {
                                ProfileEditScreen(
                                    name: account.displayName,
                                    note: account.normalizedNote
                                )
                            }
                        }
                    case .failed:
                        Text("Failed to load account information")
                    }
                }
                .task {
                    await viewModel.onProfileAppear()
                }
                .frame(minHeight: 160, alignment: .top)

                ZStack {
                    switch viewModel.userTimelineUIState {
                    case .initial: ZStack {}
                    case .loading: ProgressView()
                    case .noStatuses:
                        Text("No statuses")
                    case let .hasStatuses(statuses):
                        TimelineContent(
                            statuses: statuses,
                            onStatusAppear: { statusID in
                                await viewModel.onStatusAppear(statusID: statusID)
                            },
                            onFavoriteTapped: { statusID in
                                Task {
                                    await viewModel.onFavoriteTapped(statusID: statusID)
                                }
                            },
                            onUnfavoriteTapped: { statusID in
                                Task {
                                    await viewModel.onUnfavoriteTapped(statusID: statusID)
                                }
                            },
                            onStatusTapped: { statusID in
                                profileRouter.navigateToTimelineDetail(statusID: statusID)
                            }
                        )
                    case .failed:
                        Text("Failed to load user timeline")
                    }
                }.task {
                    await viewModel.onUserTimelineAppear()
                }
            }
        }
    }
}

private struct ProfileHeaderContent: View {
    let account: Account
    let onEditInfoTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    AsyncImage(url: URL(string: account.avatar)) { image in
                        image
                            .resizable()
                            .clipShape(Circle())
                    } placeholder: {
                        Color.gray
                            .clipShape(Circle())
                            .redacted(reason: .placeholder)
                    }
                    .frame(width: 40, height: 40)
                    Text(account.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                Button {
                    onEditInfoTapped()
                } label: {
                    Text("Edit Info")
                }
            }
            Text(account.normalizedNote)
                .font(.body)
                .lineSpacing(1.0)
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(account.statusesCount)")
                        .font(.footnote)
                        .fontWeight(.medium)
                    Text("posts")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Text("\(account.followingCount)")
                        .font(.footnote)
                        .fontWeight(.medium)
                    Text("following")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Text("\(account.followersCount)")
                        .font(.footnote)
                        .fontWeight(.medium)
                    Text("followers")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
    }
}
