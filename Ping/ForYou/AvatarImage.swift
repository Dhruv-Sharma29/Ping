import SwiftUI

/// A GitHub user's avatar, or a person symbol when there's no username.
struct AvatarImage: View {
    let handle: String
    let size: Double

    var body: some View {
        Group {
            if handle.isEmpty {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .foregroundStyle(.secondary)
            } else {
                AsyncImage(url: URL(string: "https://github.com/\(handle).png?size=\(Int(size * 3))")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(.quaternary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}
