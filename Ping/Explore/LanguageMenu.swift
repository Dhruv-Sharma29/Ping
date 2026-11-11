import SwiftUI

/// Toolbar picker for the language Explore searches in; the user's own languages come first.
struct LanguageMenu: View {
    @Binding var selection: String?
    let yours: [String]

    static let popular = [
        "Swift", "Python", "JavaScript", "TypeScript", "Java", "Kotlin", "Go", "Rust",
        "C++", "C#", "C", "Ruby", "PHP", "Dart", "Jupyter Notebook",
    ]

    var body: some View {
        Menu {
            Picker("Language", selection: $selection) {
                Text("All Languages").tag(String?.none)
                if !yours.isEmpty {
                    Section("Your Languages") {
                        ForEach(yours, id: \.self) { Text($0).tag(Optional($0)) }
                    }
                }
                Section("Popular") {
                    ForEach(Self.popular.filter { !yours.contains($0) }, id: \.self) { Text($0).tag(Optional($0)) }
                }
            }
        } label: {
            // The chosen language's name is the clearest sign a filter is on.
            if let selection {
                Text(selection)
            } else {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
            }
        }
        .accessibilityLabel("Language")
        .accessibilityValue(selection ?? "All languages")
    }
}
