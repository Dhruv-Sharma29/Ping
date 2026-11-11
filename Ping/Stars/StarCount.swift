import SwiftUI

/// "★ 70.5K" for a repo; blank until (or unless) the count loads.
struct StarCount: View {
    let repo: String
    private var count: Int? { StarStore.shared.stars(for: repo) }

    var body: some View {
        // HStack, not Label: inside a List row a Label reserves a wide icon column.
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(count ?? 0, format: .number.notation(.compactName))
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .opacity(count == nil ? 0 : 1)
        .accessibilityHidden(count == nil)
        .accessibilityLabel("\(count ?? 0) stars")
        .task(id: repo) { await StarStore.shared.load(repo) }
    }
}
