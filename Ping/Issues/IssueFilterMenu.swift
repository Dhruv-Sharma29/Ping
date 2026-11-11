import SwiftUI

/// Toolbar menu for state, repo and who-opened-it filters.
struct IssueFilterMenu: View {
    @Binding var filter: IssueFilter
    let repoNames: [String]

    var body: some View {
        Menu {
            Picker("State", systemImage: "circle.circle", selection: $filter.state) {
                ForEach(IssueFilter.State.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.menu)

            Picker("Repository", systemImage: "folder", selection: $filter.repo) {
                Text("All Repos").tag(String?.none)
                ForEach(repoNames, id: \.self) { Text($0).tag(Optional($0)) }
            }
            .pickerStyle(.menu)

            Picker("Opened By", systemImage: "person", selection: $filter.opener) {
                ForEach(IssueFilter.Opener.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.menu)

            if filter.isActive {
                Divider()
                Button("Clear Filters", systemImage: "xmark.circle", action: clear)
            }
        } label: {
            Text(filter.summary) // a text pill, like Explore's language button
                .lineLimit(1)
        }
        .accessibilityLabel("Filter")
        .accessibilityValue(filter.isActive ? filter.summary : "No filters")
    }

    private func clear() {
        filter = IssueFilter()
    }
}
