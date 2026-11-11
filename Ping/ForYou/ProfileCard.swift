import SwiftUI

/// The saved GitHub account with an Edit button, or an Add button when there's none.
struct ProfileCard: View {
    let handle: String
    let onEdit: () -> Void

    var body: some View {
        Section {
            if handle.isEmpty {
                Button("Add GitHub Account", systemImage: "person.crop.circle.badge.plus", action: onEdit)
            } else {
                HStack(spacing: 16) {
                    AvatarImage(handle: handle, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(handle).font(.headline)
                        Text("Saved on this iPhone").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Edit", action: onEdit)
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Change GitHub account")
                }
                .padding(.vertical, 4)
            }
        }
    }
}
