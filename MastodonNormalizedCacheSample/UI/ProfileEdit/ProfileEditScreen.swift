import SwiftUI

struct ProfileEditScreen: View {
    fileprivate enum Field: Hashable {
        case name
        case note
    }

    @StateObject private var viewModel: ProfileEditViewModel
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss

    init(name: String, note: String) {
        _viewModel = StateObject(wrappedValue: ProfileEditViewModel(name: name, note: note))
    }

    var body: some View {
        VStack(spacing: 16) {
            ProfileEditTextField(
                focusedField: $focusedField,
                field: .name,
                title: "name",
                placeholder: "name",
                text: viewModel.uiState.name,
                onTextChange: { text in
                    viewModel.onNameTextChange(text: text)
                }
            )
            ProfileEditTextField(
                focusedField: $focusedField,
                field: .note,
                title: "note",
                placeholder: "note",
                text: viewModel.uiState.note,
                onTextChange: { text in
                    viewModel.onNoteTextChange(text: text)
                }
            )
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.uiState.hasSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .task {
                            try? await Task.sleep(nanoseconds: 300_000_000)

                            dismiss()
                        }
                } else {
                    Button {
                        viewModel.onProfileEditSaveButtonTapped()
                    } label: {
                        if viewModel.uiState.isSaveButtonLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(viewModel.uiState.isSaveButtonLoading)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
        .alert("Failed to save your profile", isPresented: $viewModel.isAlertPresented) {
            Text("OK")
        }
    }
}


private struct ProfileEditTextField: View {
    var focusedField: FocusState<ProfileEditScreen.Field?>.Binding
    let field: ProfileEditScreen.Field
    let title: String
    let placeholder: String
    let text: String
    let onTextChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout)
                .foregroundColor(.secondary)
            TextField(placeholder, text: .init(get: {
                text
            }, set: { text in
                onTextChange(text)
            }))
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8.0)
                    .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 1.0))
            )
            .disableAutocorrection(true)
            .focused(focusedField, equals: field)
        }
    }
}
