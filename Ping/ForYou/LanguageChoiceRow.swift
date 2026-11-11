import SwiftUI

/// A tappable language in Account; chosen ones show their order (1, 2, 3).
struct LanguageChoiceRow: View {
    let language: String
    let rank: Int?
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(language)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                Spacer()
                if let rank {
                    Image(systemName: "\(rank).circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                }
            }
        }
        .disabled(isDisabled)
        .accessibilityValue(rank.map { "Chosen, number \($0)" } ?? "Not chosen")
    }
}
