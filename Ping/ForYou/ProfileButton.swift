import SwiftUI

/// The avatar in the top-right of every tab; opens Account.
struct ProfileButton: View {
    @AppStorage(StorageKey.handle) private var handle = ""
    @State private var isShowingAccount = false

    var body: some View {
        Button(action: showAccount) {
            AvatarImage(handle: handle, size: 28)
        }
        .accessibilityLabel("Account")
        .accessibilityValue(handle.isEmpty ? "Not set up" : handle)
        .sheet(isPresented: $isShowingAccount) {
            AccountView()
        }
    }

    private func showAccount() {
        isShowingAccount = true
    }
}
