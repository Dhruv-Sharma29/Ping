import SwiftUI

/// "1  Swift  ▬▬▬───  37.5%"
struct LanguageRow: View {
    let rank: Int
    let language: LanguageShare
    @ScaledMetric private var badgeSize = 28.0
    @ScaledMetric private var percentWidth = 56.0 // fixed so every bar lines up

    var body: some View {
        HStack(spacing: 12) {
            Text(String(rank))
                .font(.footnote)
                .bold()
                .foregroundStyle(.secondary)
                .frame(width: badgeSize, height: badgeSize)
                .background(.quaternary, in: .circle)

            Text(language.name)
                .lineLimit(1)

            Spacer(minLength: 8)

            ProgressView(value: language.share)
                .frame(maxWidth: 96)

            Text(language.share, format: .percent.precision(.fractionLength(1)))
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: percentWidth, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number \(rank), \(language.name), \(language.share.formatted(.percent.precision(.fractionLength(1)))) of your repos")
    }
}
