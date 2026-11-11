import SwiftUI

/// Text-pill menu for the kind of issues For You recommends.
struct SuggestionFilterMenu: View {
    @Binding var filter: SuggestionFilter

    var body: some View {
        Menu {
            Picker("Label", systemImage: "tag", selection: $filter.label) {
                ForEach(SuggestionFilter.IssueLabel.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.menu)

            Picker("Opened", systemImage: "calendar", selection: $filter.days) {
                ForEach(SuggestionFilter.dayChoices, id: \.self) { Text(SuggestionFilter.dayName($0)).tag($0) }
            }
            .pickerStyle(.menu)

            Picker("Comments", systemImage: "bubble.left.and.bubble.right", selection: $filter.maxComments) {
                ForEach(SuggestionFilter.commentChoices, id: \.self) { Text("Fewer than \($0)").tag(Optional($0)) }
                Text("Any number").tag(Int?.none)
            }
            .pickerStyle(.menu)

            Toggle("Unassigned Only", systemImage: "person.crop.circle.badge.questionmark", isOn: $filter.unassignedOnly)

            if !filter.isDefault {
                Divider()
                Button("Reset Filters", systemImage: "arrow.counterclockwise", action: reset)
            }
        } label: {
            Text(filter.summary)
                .lineLimit(1)
        }
        .accessibilityLabel("Recommendation filters")
        .accessibilityValue(filter.isDefault ? "Defaults" : filter.summary)
    }

    private func reset() {
        filter = SuggestionFilter()
    }
}
