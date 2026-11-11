import SwiftUI

struct RepoRow: View {
    let repo: Repo
    @ScaledMetric private var avatarSize = 40.0

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: repo.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(.quaternary)
            }
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(.circle)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(repo.shortName)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(repo.owner)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    StarCount(repo: repo.name)
                }

                if let error = repo.error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                } else if let checked = repo.lastChecked {
                    Text("Checked \(checked, format: .relative(presentation: .named))")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
