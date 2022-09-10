import SwiftUI

enum ProfileEditUIState {
    case editing(name: String, note: String)
    case saving(name: String, note: String)
    case saved(name: String, note: String)

    var name: String {
        switch self {
        case .editing(let name, _),
                .saving(let name, _),
                .saved(let name, _):
            return name
        }
    }
    var note: String {
        switch self {
        case .editing(_, let note),
                .saving(_, let note),
                .saved(_, let note):
            return note
        }
    }
    var isSaveButtonLoading: Bool {
        switch self {
        case .saving: return true
        case .editing, .saved: return false
        }
    }
    var hasSaved: Bool {
        switch self {
        case .saved: return true
        case .editing, .saving: return false
        }
    }
}

@MainActor class ProfileEditViewModel: ObservableObject {
    @Published private(set) var uiState: ProfileEditUIState
    @Published var isAlertPresented = false

    private let accountRepository: AccountRepository

    init(
        name: String,
        note: String,
        accountRepository: AccountRepository = .init()
    ) {
        uiState = .editing(name: name, note: note)
        self.accountRepository = accountRepository
    }

    func onNameTextChange(text: String) {
        guard case .editing(_, let note) = uiState else {
            return
        }

        uiState = .editing(name: text, note: note)
    }

    func onNoteTextChange(text: String) {
        guard case .editing(let name, _) = uiState else {
            return
        }

        uiState = .editing(name: name, note: text)
    }

    func onProfileEditSaveButtonTapped() {
        guard case .editing(let name, let note) = uiState else {
            return
        }

        Task {
            do {
                uiState = .saving(name: name, note: note)
                try await accountRepository.updateAccount(
                    displayName: name,
                    note: note
                )
                uiState = .saved(name: name, note: note)
            } catch {
                print(error)
                isAlertPresented = true
                uiState = .editing(name: name, note: note)
            }
        }
    }
}
