import SwiftUI

struct AddRepoSection: View {
    let onAdd: (String) -> Void
    @State private var input = ""
    @State private var isInvalid = false

    var body: some View {
        Section {
            HStack(spacing: 12) {
                TextField("owner/repo or GitHub link", text: $input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .onSubmit(add)
                    .onChange(of: input) { isInvalid = false }

                Button("Add Repo", systemImage: "plus.circle.fill", action: add)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } footer: {
            if isInvalid {
                Label("Use owner/repo, for example apple/swift", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.red)
            }
        }
    }

    private func add() {
        guard let name = GitHub.normalize(input) else {
            isInvalid = true
            return
        }
        onAdd(name)
        input = ""
    }
}
