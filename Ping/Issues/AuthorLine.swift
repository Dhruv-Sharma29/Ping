import SwiftUI

/// "avatar · login · [Role]" under an issue title.
struct AuthorLine: View {
    let author: IssueAuthor?
    let role: AuthorRole
    @ScaledMetric private var avatarSize = 20.0

    var body: some View {
        HStack(spacing: 8) {
            AsyncImage(url: author?.smallAvatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(.quaternary)
            }
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(.circle)
            .accessibilityHidden(true)

            Text(author?.login ?? "unknown")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(role.label)
                .font(.caption)
                .bold()
                .foregroundStyle(role.isMaintainer ? Color.accentColor : Color.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: .capsule)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Opened by \(author?.login ?? "unknown"), \(role.label)")
    }
}
