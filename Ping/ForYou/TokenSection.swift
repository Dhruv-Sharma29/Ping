import SwiftUI

/// Optional GitHub token in Account: paste, check with GitHub, save to the Keychain, or remove.
struct TokenSection: View {
    @AppStorage(StorageKey.hasToken) private var hasToken = false
    @Environment(\.openURL) private var openURL
    @State private var draft = ""
    @State private var isChecking = false
    @State private var message: String?
    @State private var isError = false

    var body: some View {
        Section {
            if hasToken {
                Label("Token saved in Keychain", systemImage: "key.fill")
                Button("Remove Token", role: .destructive, action: remove)
            } else {
                SecureField("Paste token", text: $draft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: draft) { message = nil }
                HStack(spacing: 12) {
                    Button("Create One", systemImage: "arrow.up.right.square", action: openGuide)
                        .buttonStyle(.bordered)
                    Spacer()
                    if isChecking {
                        ProgressView()
                    } else {
                        Button("Save", action: save)
                            .buttonStyle(.borderedProminent)
                            .disabled(draft.isEmpty)
                    }
                }
            }
        } header: {
            Text("GitHub Token (Optional)")
        } footer: {
            if let message {
                Text(message).foregroundStyle(isError ? .red : .secondary)
            } else if hasToken {
                Text("Ping can make up to 5,000 GitHub requests an hour.")
            } else {
                Text("Without a token GitHub allows 60 requests an hour, shared with everyone on your network. A token raises that to 5,000 for you alone. Create a fine-grained token and give it no permissions: it can then only read public data. It's stored in this iPhone's Keychain.")
            }
        }
    }

    private func openGuide() {
        openURL(GitHub.newTokenURL)
    }

    private func save() {
        guard let token = GitHub.cleanToken(draft) else {
            show("That doesn't look like a GitHub token.", error: true)
            return
        }
        isChecking = true
        Task {
            defer { isChecking = false }
            do {
                let limit = try await GitHub.checkToken(token)
                guard TokenStore.save(token) else {
                    show("Couldn't save the token to the Keychain.", error: true)
                    return
                }
                RateLimit.clear()
                draft = ""
                show("Saved. GitHub now allows \(limit.formatted()) requests an hour.", error: false)
            } catch {
                show(error.localizedDescription, error: true)
            }
        }
    }

    private func remove() {
        TokenStore.delete()
        RateLimit.clear()
        message = nil
    }

    private func show(_ text: String, error: Bool) {
        message = text
        isError = error
    }
}
