import SwiftUI

/// Editing the GitHub username: a field with Save, and Cancel when there's an account to go back to.
struct HandleSection: View {
    @Binding var handle: String
    let onCancel: () -> Void
    @State private var draft = ""
    @State private var isInvalid = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Section {
            TextField("GitHub username", text: $draft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit(save)
                .onChange(of: draft) { isInvalid = false }

            HStack(spacing: 12) {
                if !handle.isEmpty {
                    Button("Cancel", role: .cancel, action: onCancel)
                        .buttonStyle(.bordered)
                }
                Spacer()
                Button("Save", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || draft == handle)
            }
        } header: {
            Text(handle.isEmpty ? "Add GitHub Account" : "Change GitHub Account")
        } footer: {
            if isInvalid {
                Label("That isn't a GitHub username", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.red)
            } else {
                Text("Your public username, for example octocat. No password needed.")
            }
        }
        .onAppear {
            draft = handle
            isFocused = true
        }
    }

    private func save() {
        guard let name = GitHub.normalizeHandle(draft) else {
            isInvalid = true
            return
        }
        draft = name
        handle = name
    }
}
